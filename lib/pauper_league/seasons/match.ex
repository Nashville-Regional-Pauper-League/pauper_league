defmodule PauperLeague.Seasons.Event.RoundMatch do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias PauperLeague.Repo

  schema "event_round_matches" do
    belongs_to :round, PauperLeague.Seasons.Event.Round
    field :table_number, :integer
    field :is_bye, :boolean
    field :match_id, :string
  end

  def create_matches_from_raw(raw_event_id) do
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
      season_event_round =
        PauperLeague.Seasons.Event.Round
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
            PauperLeague.Seasons.Event.EventTeam
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

          %PauperLeague.Seasons.Event.MatchResult{}
          |> change(result_params)
          |> Repo.insert()
        end)
      end)
    end)
  end

  def create_matches_from_stage(staged_event_id) do
    staged_event = PauperLeague.Stage.Event |> Repo.get(staged_event_id)

    season_event =
      PauperLeague.Seasons.Event |> Repo.get_by(eventlink_id: staged_event.eventlink_id)

    from(er in PauperLeague.Stage.Event.Round,
      join: ser in PauperLeague.Seasons.Event.Round,
      on: er.round_number == ser.round_number and ser.event_id == ^season_event.id,
      where: er.event_id == ^staged_event_id,
      select: %{
        staged_round: er,
        season_round: ser
      }
    )
    |> Repo.all()
    |> Enum.map(fn %{staged_round: staged_round, season_round: season_round} ->
      from(rm in PauperLeague.Stage.Event.RoundMatch,
        where: rm.round_id == ^staged_round.id
      )
      |> Repo.all()
      |> Enum.map(fn staged_round_match ->
        round_match_params =
          staged_round_match
          |> Map.take([:table_number, :is_bye, :match_id])
          |> Map.put(:round_id, season_round.id)

        {:ok, inserted_event_round_match} =
          %__MODULE__{}
          |> change(round_match_params)
          |> Repo.insert()

        from(mr in PauperLeague.Stage.Event.MatchResult,
          where: mr.event_round_match_id == ^staged_round_match.id
        )
        |> preload([:event_team])
        |> Repo.all()
        |> Enum.map(fn staged_match_result ->
          season_event_team =
            from(et in PauperLeague.Seasons.Event.EventTeam,
              where:
                et.team_id == ^staged_match_result.event_team.team_id and
                  et.event_id == ^season_event.id
            )
            |> Repo.one()

          match_result_params = %{
            event_team_id: season_event_team.id,
            event_round_match_id: inserted_event_round_match.id,
            wins: staged_match_result.wins,
            losses: staged_match_result.losses,
            is_bye: staged_match_result.is_bye,
            draws: staged_match_result.draws
          }

          %PauperLeague.Seasons.Event.MatchResult{}
          |> change(match_result_params)
          |> Repo.insert()
          |> IO.inspect()
        end)
      end)
    end)
  end
end
