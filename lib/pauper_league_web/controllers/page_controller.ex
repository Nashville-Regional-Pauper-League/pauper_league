defmodule PauperLeagueWeb.PageController do
  use PauperLeagueWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def board(conn, _params) do
    board_list = PauperLeague.Leaderboard.get_leaderboard_by_season()

    conn
    |> assign(:leaderboard, board_list)
    |> render(:board)
  end

  def player(conn, %{"player_id" => player_id}) do
    with {:ok, player} <- PauperLeague.Player.player_view(player_id) do
      conn
      |> assign(:player, player)
      |> render(:player)
    else
      {:error, "Player Not Found"} -> conn |> resp(404, "404 Not Found")
      error -> error
    end
  end

  def deck(conn, %{"deck_id" => deck_id}) do
    deck = PauperLeague.DeckArchetype.deck_view(deck_id)
    specialists = PauperLeague.DeckArchetype.deck_specialists(deck_id)
    matchups = PauperLeague.DeckArchetype.matchups(deck_id)

    conn
    |> assign(:deck, deck)
    |> assign(:specialists, specialists)
    |> assign(:matchups, matchups)
    |> render(:deck)
  end

  def meta(conn, _) do
    last_event = PauperLeague.DeckArchetype.get_decks_last_event()
    season_totals = PauperLeague.DeckArchetype.get_decks_by_season(1)

    conn
    |> assign(:season_totals, season_totals)
    |> assign(:last_event, last_event)
    |> render(:meta)
  end

  def events(conn, _) do
    event_list = PauperLeague.Seasons.Event.get_events_by_season(1)

    conn
    |> assign(:event_list, event_list)
    |> render(:events)
  end

  def event(conn, %{"event_id" => event_id}) do
    event = PauperLeague.Seasons.Event.event_view(event_id)
    standings = PauperLeague.Seasons.Event.standings(event_id)

    conn
    |> assign(:event, event)
    |> assign(:standings, standings)
    |> render(:event)
  end
end
