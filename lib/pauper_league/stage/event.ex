defmodule PauperLeague.Stage.Event do
  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset
  alias PauperLeague.Repo

  @schema_prefix "stage"
  schema "events" do
    field :eventlink_id, :string
    field :format, :string
    field :event_date, :date
    field :playoff_rounds, :integer
    field :games_to_win, :integer
    belongs_to :store, PauperLeague.Stores.Store
    belongs_to :season, PauperLeague.Seasons.Season

    timestamps()
  end

  def clear_data do
    PauperLeague.Stage.Event.MatchResult |> Repo.delete_all()
    PauperLeague.Stage.Event.RoundMatch |> Repo.delete_all()
    PauperLeague.Stage.Event.TeamPlayer |> Repo.delete_all()
    PauperLeague.Stage.Event.Round |> Repo.delete_all()
    PauperLeague.Stage.Event.EventTeam |> Repo.delete_all()
    PauperLeague.Stage.Event |> Repo.delete_all()
  end

  def stage_event_from_raw(raw_event_id, season_id \\ 2) do
    raw_event = PauperLeague.Stores.RawEvent |> Repo.get(raw_event_id)

    params = %{
      store_id: raw_event.store_id,
      season_id: season_id,
      eventlink_id: raw_event.eventlink_id,
      format: raw_event.format,
      event_date: raw_event.event_date,
      playoff_rounds: 0,
      games_to_win: 0
    }

    %__MODULE__{}
    |> change(params)
    |> Repo.insert()
  end

  def event_view(event_id) do
    from(e in __MODULE__,
      join: st in PauperLeague.Stores.Store,
      on: e.store_id == st.id,
      join: s in PauperLeague.Seasons.Season,
      on: e.season_id == s.id,
      select: %{
        event_id: e.id,
        eventlink_id: e.eventlink_id,
        event_date: e.event_date,
        store_id: st.id,
        store_name: st.name,
        season_name: s.name
      }
    )
    |> Repo.get(event_id)
  end

  def standings(event_id) do
    from(e in __MODULE__,
      join: et in PauperLeague.Stage.Event.EventTeam,
      on: e.id == et.event_id,
      join: etp in PauperLeague.Stage.Event.TeamPlayer,
      on: et.id == etp.event_team_id,
      join: p in PauperLeague.Player,
      on: etp.player_id == p.id,
      left_join: d in PauperLeague.DeckArchetype,
      on: et.deck_archetype_id == d.id,
      join: mr in PauperLeague.Stage.Event.MatchResult,
      on: mr.event_team_id == et.id,
      where: e.id == ^event_id,
      group_by: [
        p.id,
        p.first_name,
        p.last_name,
        d.id,
        d.name,
        et.id
      ],
      select: %{
        player_id: p.id,
        player_first_name: p.first_name,
        player_last_name: p.last_name,
        event_team_id: et.id,
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
    |> Repo.all()
    |> Enum.sort_by(
      fn player -> {player.match_wins * 3 + player.match_draws * 1, player.player_last_name} end,
      :desc
    )
  end

  def publish_staged_event(staged_event_id) do
    PauperLeague.Seasons.Event.create_event_from_stage(staged_event_id)
    PauperLeague.Seasons.Event.Round.create_rounds_from_stage(staged_event_id)
    PauperLeague.Seasons.Event.EventTeam.create_teams_from_stage(staged_event_id)
    PauperLeague.Seasons.Event.RoundMatch.create_matches_from_stage(staged_event_id)
  end
end
