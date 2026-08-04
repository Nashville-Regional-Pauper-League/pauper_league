defmodule PauperLeague.Seasons.Event do
  use Ecto.Schema

  schema "events" do
    field :eventlink_id, :string
    field :format, :string
    field :event_date, :date
    field :playoff_rounds, :integer
    field :games_to_win, :integer
    belongs_to :store, PauperLeague.Stores.Store
    belongs_to :season, PauperLeague.Seasons.Season
  end
end
