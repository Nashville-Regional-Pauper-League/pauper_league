defmodule PauperLeague.Leaderboard do
  import Ecto.Query
  alias PauperLeague.Repo

  def get_leaderboard_by_season do
    season_id =
      from(s in PauperLeague.Seasons.Season,
        where: s.active,
        select: s.id
      )
      |> Repo.one()

    get_leaderboard_by_season(season_id)
  end

  def get_leaderboard_by_season(season_id) do
    best_by_week =
      from(b in subquery(base_leaderboard_query(season_id)),
        order_by: [b.player_id, b.week, desc: b.match_wins],
        distinct: [b.player_id, b.week],
        select: %{
          player_id: b.player_id,
          first_name: b.first_name,
          last_name: b.last_name,
          events: 1,
          match_wins: b.match_wins,
          match_losses: b.match_losses,
          match_draws: b.match_draws
        }
      )

    from(player in subquery(best_by_week),
      group_by: [player.player_id, player.first_name, player.last_name],
      select: %{
        player_id: player.player_id,
        first_name: player.first_name,
        last_name: player.last_name,
        events: sum(player.events),
        matches:
          sum(player.match_wins + player.match_losses + player.match_draws) |> type(:integer),
        match_wins: sum(player.match_wins) |> type(:integer),
        match_losses: sum(player.match_losses) |> type(:integer),
        match_draws: sum(player.match_draws) |> type(:integer)
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

  def base_leaderboard_query(season_id) do
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
      group_by: [
        p.id,
        p.first_name,
        p.last_name,
        fragment("EXTRACT(WEEK FROM ?)", e.event_date),
        e.id
      ],
      select: %{
        player_id: p.id,
        first_name: p.first_name,
        last_name: p.last_name,
        week: fragment("EXTRACT(WEEK FROM ?)", e.event_date),
        event_id: e.id,
        matches: count(mr.id),
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
  end
end
