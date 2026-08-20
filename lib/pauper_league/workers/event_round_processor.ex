defmodule PauperLeague.Workers.EventRoundProcessor do
  use Oban.Worker, max_attempts: 1

  @impl true
  def perform(_job) do
    # get all rounds for the event in round order, timestamp order
    # filtered by if they were inserted before the last time the round was updated
    # Per round
    # - add teams
    # - add matches
    # - add standings
  end
end
