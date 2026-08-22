defmodule PauperLeague.Seasons.Event.MatchResult do
  use Ecto.Schema

  schema "match_results" do
    belongs_to :event_round_match, PauperLeague.Seasons.Event.RoundMatch
    belongs_to :event_team, PauperLeague.Seasons.Event.EventTeam
    field :wins, :integer
    field :draws, :integer
    field :is_bye, :boolean
    field :losses, :integer
  end
end
