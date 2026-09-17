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
    leaderboard_view_query(season_id)
    |> Repo.all()
    |> Enum.map(fn player ->
      player
      |> Map.update(:bonus, 0, fn bonus -> bonus || 0 end)
      |> Map.put(:points, player.match_wins * 3 + player.match_draws * 1 + (player.bonus || 0))
    end)
    |> Enum.sort_by(fn player -> [player.points, player.events, player.trophies] end, :desc)
    |> Enum.with_index(fn player, index -> player |> Map.put(:rank, index + 1) end)
  end

  def leaderboard_view_query(season_id) do
    best_by_week =
      from(b in subquery(base_leaderboard_query(season_id)),
        order_by: [b.player_id, b.week, desc: b.match_wins, desc: b.match_draws],
        distinct: [b.player_id, b.week],
        select: %{
          player_id: b.player_id,
          week: b.week,
          first_name: b.first_name,
          last_name: b.last_name,
          weeks: 1,
          trophy:
            fragment(
              """
                case when ? = 3 then 1 else 0 end
              """,
              b.match_wins
            ),
          match_wins: b.match_wins,
          match_losses: b.match_losses,
          match_draws: b.match_draws
        }
      )

    player_query =
      from(player in subquery(best_by_week),
        group_by: [player.player_id, player.first_name, player.last_name],
        select: %{
          player_id: player.player_id,
          first_name: player.first_name,
          last_name: player.last_name,
          weeks: sum(player.weeks),
          trophies: sum(player.trophy),
          matches:
            sum(player.match_wins + player.match_losses + player.match_draws) |> type(:integer),
          match_wins: sum(player.match_wins) |> type(:integer),
          match_losses: sum(player.match_losses) |> type(:integer),
          match_draws: sum(player.match_draws) |> type(:integer)
        }
      )

    bonus_query = get_store_attendance(season_id)

    from(p in subquery(player_query),
      left_join: b in subquery(bonus_query),
      on: p.player_id == b.player_id,
      select: %{
        player_id: p.player_id,
        first_name: p.first_name,
        last_name: p.last_name,
        weeks: p.weeks,
        trophies: p.trophies,
        matches: p.matches,
        match_wins: p.match_wins,
        match_losses: p.match_losses,
        match_draws: p.match_draws,
        bonus: b.bonus,
        events: b.events
      }
    )
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
        e.id,
        e.event_date,
        e.store_id
      ],
      select: %{
        player_id: p.id,
        first_name: p.first_name,
        last_name: p.last_name,
        week: fragment("EXTRACT(WEEK FROM ?)", e.event_date),
        event_id: e.id,
        event_date: e.event_date,
        store_id: e.store_id,
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

  def get_store_attendance(season_id) do
    month_subquery =
      from(b in subquery(base_leaderboard_query(season_id)),
        where: b.matches == 3,
        select: %{
          player_id: b.player_id,
          event_id: b.event_id,
          month:
            fragment(
              """
               case
                  when ? between '2026-08-24' and '2026-09-30' then 1
                  when ? between '2026-10-01' and '2026-10-31' then 2
                  when ? between '2026-11-01' and '2026-12-13' then 3
                  else 0
              end
              """,
              b.event_date,
              b.event_date,
              b.event_date
            ),
          store_id: b.store_id
        }
      )

    bonus_by_month_query =
      from(months in subquery(month_subquery),
        group_by: [months.player_id, months.month],
        select: %{
          player_id: months.player_id,
          month: months.month,
          events: count(months.event_id, :distinct),
          bonus:
            fragment(
              """
                case
                  when count(distinct ?) = 4 then 3
                  when count(distinct ?) = 3 then 2
                  when count(distinct ?) = 2 then 1
                  else 0
                end
              """,
              months.store_id,
              months.store_id,
              months.store_id
            )
        }
      )

    from(player in subquery(bonus_by_month_query),
      group_by: [player.player_id],
      select: %{
        player_id: player.player_id,
        events: sum(player.events),
        bonus: sum(player.bonus)
      }
    )
  end
end
