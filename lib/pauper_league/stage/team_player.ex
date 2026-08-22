defmodule PauperLeague.Stage.Event.TeamPlayer do
  use Ecto.Schema

  @schema_prefix "stage"
  schema "event_team_players" do
    belongs_to :event_team, PauperLeague.Stage.Event.EventTeam
    belongs_to :player, PauperLeague.Player
  end
end
