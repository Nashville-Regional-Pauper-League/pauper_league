defmodule PauperLeague.Seasons.Event.EventTeam do
  use Ecto.Schema

  schema "event_teams" do
    field :team_id, :string
    belongs_to :event, PauperLeague.Seasons.Event
    has_many :team_players, PauperLeague.Seasons.Event.TeamPlayer
  end
end
