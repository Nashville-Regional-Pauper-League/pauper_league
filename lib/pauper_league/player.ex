defmodule PauperLeague.Player do
  use Ecto.Schema

  import Ecto.Query
  alias PauperLeague.Repo

  schema "players" do
    field :persona_id, :string
    field :first_name, :string
    field :last_name, :string
    field :display_name, :string
    timestamps()
  end

  def search_players(""), do: []

  def search_players(search) do
    search = "%#{search}%"

    from(u in __MODULE__,
      where:
        ilike(u.first_name, ^search) or
          ilike(u.last_name, ^search),
      order_by: u.first_name,
      limit: 20
    )
    |> Repo.all()
  end

  def player_view(player_id) do
    player =
      from(p in __MODULE__,
        join: etp in PauperLeague.Seasons.Event.TeamPlayer,
        on: etp.player_id == p.id,
        join: mr in PauperLeague.Seasons.Event.MatchResult,
        on: etp.event_team_id == mr.event_team_id,
        group_by: [p.id, p.first_name, p.last_name],
        select: %{
          first_name: p.first_name,
          last_name: p.last_name,
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
      |> Repo.get(player_id)

    if not is_nil(player) do
      win_rate =
        Float.round(
          100 * player.match_wins / (player.match_wins + player.match_losses + player.match_draws),
          1
        )

      trophies =
        get_event_trophy_status(player_id)
        |> Enum.filter(fn event -> event.trophied end)
        |> Enum.count()

      events = get_events(player_id)

      decks = get_decks(player_id)

      player_details = %{
        record: "#{player.match_wins}-#{player.match_losses}-#{player.match_draws}",
        win_rate: "#{win_rate}%",
        trophies: trophies,
        events: events,
        decks: decks
      }

      {:ok, player |> Map.merge(player_details)}
    else
      {:error, "Player Not Found"}
    end
  end

  def get_events(player_id) do
    from(p in __MODULE__,
      join: etp in PauperLeague.Seasons.Event.TeamPlayer,
      on: etp.player_id == p.id,
      join: mr in PauperLeague.Seasons.Event.MatchResult,
      on: etp.event_team_id == mr.event_team_id,
      join: rm in PauperLeague.Seasons.Event.RoundMatch,
      on: mr.event_round_match_id == rm.id,
      join: mr_opp in PauperLeague.Seasons.Event.MatchResult,
      on: mr_opp.event_round_match_id == rm.id and mr.id != mr_opp.id,
      join: etp_opp in PauperLeague.Seasons.Event.TeamPlayer,
      on: etp_opp.event_team_id == mr_opp.event_team_id,
      join: opp in PauperLeague.Player,
      on: etp_opp.player_id == opp.id,
      join: r in PauperLeague.Seasons.Event.Round,
      on: rm.round_id == r.id,
      join: e in PauperLeague.Seasons.Event,
      on: r.event_id == e.id,
      join: s in PauperLeague.Seasons.Season,
      on: e.season_id == s.id,
      join: st in PauperLeague.Stores.Store,
      on: e.store_id == st.id,
      where: p.id == ^player_id,
      order_by: [desc: e.event_date, asc: r.round_number],
      select: %{
        event_id: e.id,
        event_date: e.event_date,
        store: st.name,
        season: s.name,
        round: r.round_number,
        match_wins: mr.wins,
        match_losses: mr.losses,
        match_draws: mr.draws,
        match_bye: mr.is_bye,
        opp_player_id: opp.id,
        opp_first_name: opp.first_name,
        opp_last_name: opp.last_name
      }
    )
    |> Repo.all()
    |> Enum.group_by(fn e -> {e.event_id, e.event_date, e.store, e.season} end)
    |> Enum.sort_by(fn {{_, event_date, _, _}, _} -> event_date end, {:desc, Date})
  end

  def get_event_trophy_status(player_id) do
    from(p in __MODULE__,
      join: etp in PauperLeague.Seasons.Event.TeamPlayer,
      on: etp.player_id == p.id,
      join: mr in PauperLeague.Seasons.Event.MatchResult,
      on: etp.event_team_id == mr.event_team_id,
      join: rm in PauperLeague.Seasons.Event.RoundMatch,
      on: mr.event_round_match_id == rm.id,
      join: r in PauperLeague.Seasons.Event.Round,
      on: rm.round_id == r.id,
      where: p.id == ^player_id,
      group_by: r.event_id,
      select: %{
        event_id: r.event_id,
        trophied:
          sum(
            fragment(
              "CASE WHEN ? = 2 THEN 1 WHEN ? = 1 and ? = 0 THEN 1 ELSE 0 END",
              mr.wins,
              mr.wins,
              mr.losses
            )
          ) == 3
      }
    )
    |> Repo.all()
  end

  def get_decks(player_id) do
    from(p in __MODULE__,
      join: etp in PauperLeague.Seasons.Event.TeamPlayer,
      on: etp.player_id == p.id,
      join: et in PauperLeague.Seasons.Event.EventTeam,
      on: etp.event_team_id == et.id,
      join: mr in PauperLeague.Seasons.Event.MatchResult,
      on: etp.event_team_id == mr.event_team_id,
      join: deck in PauperLeague.DeckArchetype,
      on: et.deck_archetype_id == deck.id,
      where: p.id == ^player_id,
      group_by: [deck.id, deck.name],
      select: %{
        deck_id: deck.id,
        deck: deck.name,
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
    |> Enum.sort_by(
      fn deck ->
        {deck.matches, deck.match_wins / deck.matches}
      end,
      :desc
    )
    |> Enum.map(fn deck ->
      deck
      |> Map.put(:win_rate, "#{Float.round(100 * deck.match_wins / deck.matches, 2)}%")
    end)
  end
end
