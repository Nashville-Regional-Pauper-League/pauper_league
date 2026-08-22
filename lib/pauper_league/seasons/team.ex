defmodule PauperLeague.Seasons.Event.EventTeam do
  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset
  alias PauperLeague.Repo

  schema "event_teams" do
    field :team_id, :string
    belongs_to :event, PauperLeague.Seasons.Event
    belongs_to :deck_archetype, PauperLeague.DeckArchetype
    has_many :team_players, PauperLeague.Seasons.Event.TeamPlayer
  end

  def create_teams_from_raw(raw_event_id) do
    raw_event = PauperLeague.Stores.RawEvent |> Repo.get(raw_event_id)
    season_event = PauperLeague.Seasons.Event |> Repo.get_by(eventlink_id: raw_event.eventlink_id)

    event_round_data =
      PauperLeague.Stores.RawEventRound
      |> where([ed], ed.event_id == ^raw_event_id and ed.round_no in [1, 2, 3])
      |> order_by([ed], asc: ed.round_no, desc: ed.inserted_at)
      |> distinct([ed], [ed.round_no])
      |> Repo.all()

    event_round_data
    |> Enum.map(fn round ->
      round
      |> Map.get(:data)
      |> Map.get("teams")
    end)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(fn team ->
      params = %{
        team_id: team["teamId"],
        event_id: season_event.id
      }

      {:ok, inserted_event_team} =
        %__MODULE__{}
        |> change(params)
        |> Repo.insert()

      team["players"]
      |> Enum.map(fn player ->
        db_player = PauperLeague.Player |> Repo.get_by(persona_id: player["personaId"])

        player_params = %{
          event_team_id: inserted_event_team.id,
          player_id: db_player.id
        }

        %PauperLeague.Seasons.Event.TeamPlayer{}
        |> change(player_params)
        |> Repo.insert()
      end)
    end)
  end

  def create_teams_from_stage(staged_event_id) do
    staged_event = PauperLeague.Stage.Event |> Repo.get(staged_event_id)

    season_event =
      PauperLeague.Seasons.Event |> Repo.get_by(eventlink_id: staged_event.eventlink_id)

    from(et in PauperLeague.Stage.Event.EventTeam)
    |> where([et], et.event_id == ^staged_event_id)
    |> preload([:team_players])
    |> PauperLeague.Repo.all()
    |> Enum.map(fn event_team ->
      params =
        event_team
        |> Map.take([:team_id, :deck_archetype_id])
        |> Map.put(:event_id, season_event.id)

      {:ok, inserted_event_team} =
        %__MODULE__{}
        |> change(params)
        |> Repo.insert()

      event_team.team_players
      |> Enum.map(fn team_player ->
        player_params = %{
          event_team_id: inserted_event_team.id,
          player_id: team_player.player_id
        }

        %PauperLeague.Seasons.Event.TeamPlayer{}
        |> change(player_params)
        |> Repo.insert()
      end)
    end)
  end
end
