defmodule PauperLeague.Seasons.EventTeam do
  use Ecto.Schema

  schema "event_teams" do
    belongs_to :event, PauperLeague.Seasons.Event
    has_many :team_players, PauperLeague.Seasons.Event.TeamPlayer
  end
end
