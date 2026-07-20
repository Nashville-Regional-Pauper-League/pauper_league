defmodule PauperLeague.Stores.RawEvent do
  use Ecto.Schema

  @schema_prefix "raw"
  schema "events" do
    field :eventlink_id, :string
    field :format, :string
    field :event_date, :date
    field :internal_state, :string
    belongs_to :store, PauperLeague.Stores.Store

    timestamps()
  end
end
