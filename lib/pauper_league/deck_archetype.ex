defmodule PauperLeague.DeckArchetype do
  use Ecto.Schema

  import Ecto.Query
  alias PauperLeague.Repo

  schema "deck_archetypes" do
    field :name, :string
  end

  def all do
    from(da in __MODULE__)
    |> select([da], %{label: da.name, value: da.id})
    |> order_by([da], da.name)
    |> Repo.all()
  end

  def deck_view(deck_id) do
    deck =
      from(d in __MODULE__,
        join: et in PauperLeague.Seasons.Event.EventTeam,
        on: et.deck_archetype_id == d.id,
        join: mr in PauperLeague.Seasons.Event.MatchResult,
        on: et.id == mr.event_team_id,
        where: d.id == ^deck_id,
        group_by: [d.id, d.name],
        select: %{
          deck_id: d.id,
          deck_name: d.name,
          matches: count(),
          match_wins:
            sum(
              fragment(
                "CASE WHEN ? = 2 THEN 1 WHEN ? = 1 and ? = 0 THEN 1 ELSE 0 END",
                mr.wins,
                mr.wins,
                mr.losses
              )
            ),
          match_losses:
            sum(
              fragment(
                "CASE WHEN ? = 2 THEN 1 WHEN ? = 1 and ? = 0 THEN 1 ELSE 0 END",
                mr.losses,
                mr.losses,
                mr.wins
              )
            ),
          match_draws:
            sum(
              fragment(
                "CASE WHEN ? = ? THEN 1 ELSE 0 END",
                mr.wins,
                mr.losses
              )
            )
        }
      )
      |> Repo.one()

    deck
    |> Map.put(:win_rate, "#{Float.round(100 * deck.match_wins / deck.matches, 2)}%")
  end

  def deck_specialists(deck_id) do
    from(d in __MODULE__,
      join: et in PauperLeague.Seasons.Event.EventTeam,
      on: et.deck_archetype_id == d.id,
      join: mr in PauperLeague.Seasons.Event.MatchResult,
      on: et.id == mr.event_team_id,
      join: etp in PauperLeague.Seasons.Event.TeamPlayer,
      on: etp.event_team_id == et.id,
      join: p in PauperLeague.Player,
      on: etp.player_id == p.id,
      where: d.id == ^deck_id,
      group_by: [p.id, p.first_name, p.last_name],
      select: %{
        player_id: p.id,
        player_first_name: p.first_name,
        player_last_name: p.last_name,
        matches: count(),
        match_wins:
          sum(
            fragment(
              "CASE WHEN ? = 2 THEN 1 WHEN ? = 1 and ? = 0 THEN 1 ELSE 0 END",
              mr.wins,
              mr.wins,
              mr.losses
            )
          ),
        match_losses:
          sum(
            fragment(
              "CASE WHEN ? = 2 THEN 1 WHEN ? = 1 and ? = 0 THEN 1 ELSE 0 END",
              mr.losses,
              mr.losses,
              mr.wins
            )
          ),
        match_draws:
          sum(
            fragment(
              "CASE WHEN ? = ? THEN 1 ELSE 0 END",
              mr.wins,
              mr.losses
            )
          )
      }
    )
    |> Repo.all()
    |> Enum.filter(fn sp -> sp.matches > 5 end)
    |> Enum.sort_by(fn sp -> sp.match_wins / sp.matches end, :desc)
    |> Enum.map(fn sp ->
      sp
      |> Map.put(
        :win_rate,
        "#{Float.round(100 * sp.match_wins / sp.matches, 2)}%"
      )
    end)
  end

  def matchups(deck_id) do
    from(d in __MODULE__,
      join: et in PauperLeague.Seasons.Event.EventTeam,
      on: et.deck_archetype_id == d.id,
      join: mr in PauperLeague.Seasons.Event.MatchResult,
      on: et.id == mr.event_team_id,
      join: rm in PauperLeague.Seasons.Event.RoundMatch,
      on: mr.event_round_match_id == rm.id,
      join: opp_mr in PauperLeague.Seasons.Event.MatchResult,
      on: opp_mr.event_round_match_id == rm.id and opp_mr.event_team_id != mr.event_team_id,
      join: opp_et in PauperLeague.Seasons.Event.EventTeam,
      on: opp_mr.event_team_id == opp_et.id,
      join: opp_deck in PauperLeague.DeckArchetype,
      on: opp_et.deck_archetype_id == opp_deck.id,
      where: d.id == ^deck_id,
      group_by: [opp_deck.id, opp_deck.name],
      select: %{
        opp_deck_id: opp_deck.id,
        opp_deck_name: opp_deck.name,
        matches: count(),
        match_wins:
          sum(
            fragment(
              "CASE WHEN ? = 2 THEN 1 WHEN ? = 1 and ? = 0 THEN 1 ELSE 0 END",
              mr.wins,
              mr.wins,
              mr.losses
            )
          ),
        match_losses:
          sum(
            fragment(
              "CASE WHEN ? = 2 THEN 1 WHEN ? = 1 and ? = 0 THEN 1 ELSE 0 END",
              mr.losses,
              mr.losses,
              mr.wins
            )
          ),
        match_draws:
          sum(
            fragment(
              "CASE WHEN ? = ? THEN 1 ELSE 0 END",
              mr.wins,
              mr.losses
            )
          )
      }
    )
    |> Repo.all()
    # |> Enum.filter(fn mu -> mu.matches > 5 end)
    |> Enum.sort_by(fn mu -> {mu.match_wins / mu.matches, mu.matches} end, :desc)
    |> Enum.map(fn mu ->
      mu
      |> Map.put(
        :win_rate,
        "#{Float.round(100 * mu.match_wins / mu.matches, 2)}%"
      )
    end)
  end

  def get_decks_by_season(season_id) do
    from(d in __MODULE__,
      join: et in PauperLeague.Seasons.Event.EventTeam,
      on: et.deck_archetype_id == d.id,
      join: e in PauperLeague.Seasons.Event,
      on: et.event_id == e.id,
      where: e.season_id == ^season_id,
      where: d.name != "Unknown",
      group_by: [d.id, d.name],
      select: %{
        deck_id: d.id,
        deck_name: d.name,
        count: count()
      }
    )
    |> Repo.all()
    |> Enum.sort_by(fn d -> d.count end, :desc)
  end

  def get_decks_last_event do
    event_id =
      PauperLeague.Seasons.Event
      |> select([e], e.id)
      |> order_by([e], desc: e.event_date)
      |> limit(1)
      |> Repo.one()

    if not is_nil(event_id), do: get_decks_by_event(event_id), else: []
  end

  def get_decks_by_event(event_id) do
    from(d in __MODULE__,
      join: et in PauperLeague.Seasons.Event.EventTeam,
      on: et.deck_archetype_id == d.id,
      where: et.event_id == ^event_id,
      group_by: [d.id, d.name],
      select: %{
        deck_id: d.id,
        deck_name: d.name,
        count: count()
      }
    )
    |> Repo.all()
    |> Enum.sort_by(fn d -> d.count end, :desc)
  end

  def get_by_id(deck_id) do
    from(d in __MODULE__)
    |> Repo.get(deck_id)
  end

  def get_by_name(deck_name) do
    from(d in __MODULE__)
    |> where([d], d.name == ^deck_name)
    |> Repo.one()
  end
end
