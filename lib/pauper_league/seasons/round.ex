defmodule PauperLeague.Seasons.Event.Round do
  use Ecto.Schema

  schema "event_rounds" do
    belongs_to :event, PauperLeague.Seasons.Event
    field :eventlink_id, :string
    field :round_number, :integer
    field :is_playoff, :boolean
    field :is_final_round, :boolean
  end
end
