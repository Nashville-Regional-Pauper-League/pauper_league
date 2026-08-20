defmodule PauperLeague.Stores.RawEventData do
  use Ecto.Schema

  @schema_prefix "raw"
  schema "event_data" do
    field :data, :map
    belongs_to :event, PauperLeague.Stores.RawEvent

    timestamps()
  end
end
