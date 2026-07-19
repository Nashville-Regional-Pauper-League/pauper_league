defmodule PauperLeague.Seasons.Event do
  use Ecto.Schema

  schema "events" do
    field :eventlink_id, :string
    field :format, :string
    field :event_date, :date
    belongs_to :store, PauperLeague.Stores.Store
  end
end
