defmodule PauperLeague.Leaderboard do
  import Ecto.Query
  alias PauperLeague.Repo

  def get_leaderboard_by_season do
    # We want to have only 1 best event per player per week
    from(s in PauperLeague.Seasons.Season,
      join: e in PauperLeague.Seasons.Event,
      on: e.season_id == s.id,
      join: r in PauperLeague.Seasons.Event.Round,
      on: r.event_id == e.id,
      join: rm in PauperLeague.Seasons.Event.RoundMatch,
      on: rm.round_id == r.id,
      join: mr in PauperLeague.Seasons.Event.MatchResult,
      on: mr.event_round_match_id == rm.id,
      join: etp in PauperLeague.Seasons.Event.TeamPlayer,
      on: etp.event_team_id == mr.event_team_id,
      join: p in PauperLeague.Player,
      on: etp.player_id == p.id,
      where: s.active,
      group_by: [p.id, p.first_name, p.last_name],
      order_by: [desc: sum(fragment("CASE WHEN ? = 2 THEN 1 ELSE 0 END", mr.wins))],
      select: %{
        player_id: p.id,
        first_name: p.first_name,
        last_name: p.last_name,
        matches: count(mr.id),
        events: fragment("count(distinct ?)", e.id),
        match_wins:
          sum(
            fragment(
              "CASE WHEN ? = 2 THEN 1 WHEN ? = 1 and ? = 0 THEN 1 ELSE 0 END",
              mr.wins,
              mr.wins,
              mr.losses
            )
          ),
        match_losses:
          sum(
            fragment(
              "CASE WHEN ? = 2 THEN 1 WHEN ? = 1 and ? = 0 THEN 1 ELSE 0 END",
              mr.losses,
              mr.losses,
              mr.wins
            )
          ),
        match_draws:
          sum(
            fragment(
              "CASE WHEN ? = ? THEN 1 ELSE 0 END",
              mr.wins,
              mr.losses
            )
          )
      }
    )
    |> Repo.all()
    |> Enum.map(fn player ->
      player
      |> Map.put(:points, player.match_wins * 3 + player.match_draws * 1)
    end)
    |> Enum.sort_by(fn player -> player.points end, :desc)
    |> Enum.with_index(fn player, index -> player |> Map.put(:rank, index + 1) end)
  end

  def get_leaderboard_by_season(season_id) do
    # We want to have only 1 best event per player per week
    from(s in PauperLeague.Seasons.Season,
      join: e in PauperLeague.Seasons.Event,
      on: e.season_id == s.id,
      join: r in PauperLeague.Seasons.Event.Round,
      on: r.event_id == e.id,
      join: rm in PauperLeague.Seasons.Event.RoundMatch,
      on: rm.round_id == r.id,
      join: mr in PauperLeague.Seasons.Event.MatchResult,
      on: mr.event_round_match_id == rm.id,
      join: etp in PauperLeague.Seasons.Event.TeamPlayer,
      on: etp.event_team_id == mr.event_team_id,
      join: p in PauperLeague.Player,
      on: etp.player_id == p.id,
      where: s.id == ^season_id,
      group_by: [p.id, p.first_name, p.last_name],
      order_by: [desc: sum(fragment("CASE WHEN ? = 2 THEN 1 ELSE 0 END", mr.wins))],
      select: %{
        player_id: p.id,
        first_name: p.first_name,
        last_name: p.last_name,
        matches: count(mr.id),
        events: fragment("count(distinct ?)", e.id),
        match_wins:
          sum(
            fragment(
              "CASE WHEN ? = 2 THEN 1 WHEN ? = 1 and ? = 0 THEN 1 ELSE 0 END",
              mr.wins,
              mr.wins,
              mr.losses
            )
          ),
        match_losses:
          sum(
            fragment(
              "CASE WHEN ? = 2 THEN 1 WHEN ? = 1 and ? = 0 THEN 1 ELSE 0 END",
              mr.losses,
              mr.losses,
              mr.wins
            )
          ),
        match_draws:
          sum(
            fragment(
              "CASE WHEN ? = ? THEN 1 ELSE 0 END",
              mr.wins,
              mr.losses
            )
          )
      }
    )
    |> Repo.all()
    |> Enum.map(fn player ->
      player
      |> Map.put(:points, player.match_wins * 3 + player.match_draws * 1)
    end)
    |> Enum.sort_by(fn player -> player.points end, :desc)
    |> Enum.with_index(fn player, index -> player |> Map.put(:rank, index + 1) end)
  end
end
