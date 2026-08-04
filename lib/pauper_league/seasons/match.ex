defmodule PauperLeague.Seasons.Event.RoundMatch do
  use Ecto.Schema

  schema "event_round_matches" do
    belongs_to :round, PauperLeague.Seasons.Event.Round
    field :table_number, :integer
    field :is_bye, :boolean
    field :match_id, :string
  end
end
