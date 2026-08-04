defmodule PauperLeague.Stores.RawEventRound do
  use Ecto.Schema

  @schema_prefix "raw"
  schema "event_round" do
    field :data, :map
    field :round_no, :integer
    belongs_to :event, PauperLeague.Stores.RawEvent

    timestamps()
  end
end
