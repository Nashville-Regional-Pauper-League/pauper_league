defmodule PauperLeague.Seasons.Season do
  use Ecto.Schema

  schema "seasons" do
    field :name, :string
    field :season_number, :integer
    field :start_date, :date
    field :end_date, :date
    field :active, :boolean
  end
end
