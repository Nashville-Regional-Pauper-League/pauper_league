defmodule PauperLeague.Stage.Event.Round do
  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset
  alias PauperLeague.Repo

  @schema_prefix "stage"
  schema "event_rounds" do
    belongs_to :event, PauperLeague.Stage.Event
    field :eventlink_id, :string
    field :round_number, :integer
    field :is_playoff, :boolean
    # field :games_to_win, :integer
    field :is_final_round, :boolean

    has_many :event_round_matches, PauperLeague.Stage.Event.RoundMatch, foreign_key: :round_id
  end

  def stage_rounds_from_raw(raw_event_id) do
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
      params = %{
        event_id: season_event.id,
        round_number: round.round_no
        # games_to_win: round |> Map.get(:data) |> Map.get("gamesToWin")
      }

      %__MODULE__{}
      |> change(params)
      |> Repo.insert()
    end)
  end
end
