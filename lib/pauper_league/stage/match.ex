defmodule PauperLeague.Stage.Event.RoundMatch do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias PauperLeague.Repo

  @schema_prefix "stage"
  schema "event_round_matches" do
    belongs_to :round, PauperLeague.Stage.Event.Round
    field :table_number, :integer
    field :is_bye, :boolean
    field :match_id, :string
  end

  def stage_matches_from_raw(raw_event_id) do
    raw_event = PauperLeague.Stores.RawEvent |> Repo.get(raw_event_id)
    season_event = PauperLeague.Stage.Event |> Repo.get_by(eventlink_id: raw_event.eventlink_id)

    event_round_data =
      PauperLeague.Stores.RawEventRound
      |> where([ed], ed.event_id == ^raw_event_id and ed.round_no in [1, 2, 3])
      |> order_by([ed], asc: ed.round_no, desc: ed.inserted_at)
      |> distinct([ed], [ed.round_no])
      |> Repo.all()

    event_round_data
    |> Enum.map(fn round ->
      season_event_round =
        PauperLeague.Stage.Event.Round
        |> where([r], r.event_id == ^season_event.id and r.round_number == ^round.round_no)
        |> Repo.one()

      round
      |> Map.get(:data)
      |> Map.get("rounds")
      |> hd()
      |> Map.get("matches")
      |> Enum.map(fn match ->
        match_params = %{
          round_id: season_event_round.id,
          table_number: match["tableNumber"],
          is_bye: match["isBye"],
          match_id: match["matchId"]
        }

        {:ok, inserted_event_round_match} =
          %__MODULE__{}
          |> change(match_params)
          |> Repo.insert()

        match["results"]
        |> Enum.map(fn result ->
          event_team =
            PauperLeague.Stage.Event.EventTeam
            |> where([et], et.team_id == ^result["teamId"] and et.event_id == ^season_event.id)
            |> Repo.one()

          result_params = %{
            event_round_match_id: inserted_event_round_match.id,
            event_team_id: event_team.id,
            wins: result["wins"],
            losses: result["losses"],
            is_bye: result["isBye"],
            draws: result["draws"]
          }

          %PauperLeague.Stage.Event.MatchResult{}
          |> change(result_params)
          |> Repo.insert()
        end)
      end)
    end)
  end
end
