defmodule PauperLeague.Stage.Event.MatchResult do
  use Ecto.Schema

  @schema_prefix "stage"
  schema "match_results" do
    belongs_to :event_round_match, PauperLeague.Stage.Event.RoundMatch
    belongs_to :event_team, PauperLeague.Stage.Event.EventTeam
    field :wins, :integer
    field :draws, :integer
    field :is_bye, :boolean
    field :losses, :integer
  end
end
