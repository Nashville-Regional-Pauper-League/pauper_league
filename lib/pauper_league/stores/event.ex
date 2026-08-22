defmodule PauperLeague.Stores.RawEvent do
  use Ecto.Schema

  import Ecto.Query

  alias PauperLeague.Repo

  @schema_prefix "raw"
  schema "events" do
    field :eventlink_id, :string
    field :format, :string
    field :event_date, :date
    field :description, :string
    field :title, :string
    field :eventlink_status, :string
    field :internal_state, :string
    field :season_event_id, :integer, virtual: true
    field :stage_event_id, :integer, virtual: true
    belongs_to :store, PauperLeague.Stores.Store
    has_many :event_rounds, PauperLeague.Stores.RawEventRound, foreign_key: :event_id

    timestamps()
  end

  def check_status(event_id) do
    event_rounds =
      PauperLeague.Stores.RawEventRound
      |> where([e], e.round_no in [1, 2, 3])
      |> Repo.all_by(event_id: event_id)

    # IO.inspect(length(event_rounds) == 3, label: "Has 3 rounds")

    rounds_with_results =
      event_rounds
      |> Enum.filter(fn %{data: round} ->
        matches = round |> Map.get("rounds") |> hd() |> Map.get("matches")
        # all matches have results
        matches_with_results =
          matches |> Enum.filter(fn match -> not is_nil(match["results"]) end)

        length(matches) == length(matches_with_results)
      end)

    length(rounds_with_results) == 3
    # IO.inspect(length(rounds_with_results) == 3, label: "Has 3 rounds with results")
  end

  def all_round_data do
    PauperLeague.Stores.RawEventRound
    |> where([ed], ed.round_no in [1, 2, 3])
    |> order_by([ed], asc: ed.event_id, asc: ed.round_no, desc: ed.inserted_at)
    |> distinct([ed], [ed.event_id, ed.round_no])
    |> Repo.all()
  end

  def create_event_data(event_id) do
    PauperLeague.Seasons.Event.create_event_from_raw(event_id)
    PauperLeague.Seasons.Event.Round.create_rounds_from_raw(event_id)
    PauperLeague.Seasons.Event.EventTeam.create_teams_from_raw(event_id)
    PauperLeague.Seasons.Event.RoundMatch.create_matches_from_raw(event_id)
  end

  def stage_event_data(event_id) do
    PauperLeague.Stage.Event.stage_event_from_raw(event_id)
    PauperLeague.Stage.Event.Round.stage_rounds_from_raw(event_id)
    PauperLeague.Stage.Event.EventTeam.stage_teams_from_raw(event_id)
    PauperLeague.Stage.Event.RoundMatch.stage_matches_from_raw(event_id)
  end
end
