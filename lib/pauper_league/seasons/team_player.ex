defmodule PauperLeague.Seasons.Event.TeamPlayer do
  use Ecto.Schema

  schema "event_team_players" do
    belongs_to :event_team, PauperLeague.Seasons.EventTeam
    belongs_to :player, PauperLeague.Player
  end
end
