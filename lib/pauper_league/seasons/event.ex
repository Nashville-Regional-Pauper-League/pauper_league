defmodule PauperLeague.Seasons.Event do
  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset
  alias PauperLeague.Repo

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
    PauperLeague.Seasons.Event.MatchResult |> Repo.delete_all()
    PauperLeague.Seasons.Event.RoundMatch |> Repo.delete_all()
    PauperLeague.Seasons.Event.TeamPlayer |> Repo.delete_all()
    PauperLeague.Seasons.Event.Round |> Repo.delete_all()
    PauperLeague.Seasons.Event.EventTeam |> Repo.delete_all()
    PauperLeague.Seasons.Event |> Repo.delete_all()
  end

  def create_event_from_stage(stage_event_id) do
    stage_event = PauperLeague.Stage.Event |> Repo.get(stage_event_id)

    params = %{
      store_id: stage_event.store_id,
      season_id: stage_event.season_id,
      eventlink_id: stage_event.eventlink_id,
      format: stage_event.format,
      event_date: stage_event.event_date,
      playoff_rounds: 0,
      games_to_win: 0
    }

    %__MODULE__{}
    |> change(params)
    |> Repo.insert()
  end

  def create_event_from_raw(raw_event_id, season_id \\ 1) do
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

  def get_events_by_season(season_id) do
    from(e in __MODULE__,
      join: st in PauperLeague.Stores.Store,
      on: e.store_id == st.id,
      where: e.season_id == ^season_id,
      order_by: [desc: e.event_date],
      select: %{
        event_id: e.id,
        event_date: e.event_date,
        store_id: st.id,
        store_name: st.name
      }
    )
    |> Repo.all()
  end

  def event_view(event_id) do
    from(e in __MODULE__,
      join: st in PauperLeague.Stores.Store,
      on: e.store_id == st.id,
      join: s in PauperLeague.Seasons.Season,
      on: e.season_id == s.id,
      select: %{
        id: e.id,
        event_id: e.id,
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
      join: et in PauperLeague.Seasons.Event.EventTeam,
      on: e.id == et.event_id,
      join: etp in PauperLeague.Seasons.Event.TeamPlayer,
      on: et.id == etp.event_team_id,
      join: p in PauperLeague.Player,
      on: etp.player_id == p.id,
      left_join: d in PauperLeague.DeckArchetype,
      on: et.deck_archetype_id == d.id,
      join: mr in PauperLeague.Seasons.Event.MatchResult,
      on: mr.event_team_id == et.id,
      where: e.id == ^event_id,
      group_by: [p.id, p.first_name, p.last_name, d.id, d.name],
      select: %{
        player_id: p.id,
        player_first_name: p.first_name,
        player_last_name: p.last_name,
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
    |> Enum.sort_by(fn player -> player.match_wins * 3 + player.match_draws * 1 end, :desc)
  end
end
