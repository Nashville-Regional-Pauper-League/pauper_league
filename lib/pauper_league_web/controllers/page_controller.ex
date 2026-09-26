defmodule PauperLeagueWeb.PageController do
  use PauperLeagueWeb, :controller

  import Ecto.Query

  @qualifier_list [
    %{store: "The Game Lodge", date: ~D[2026-10-24]},
    %{store: "Game Knight", date: ~D[2026-11-21]},
    %{store: "Infinity", date: ~D[2026-12-05]},
    %{store: "Middle Tennessee Gaming", date: "TBD"}
  ]

  @store_list [
    %{
      store: "Infinity Game Lounge",
      league_night: %{day: "Mondays", time: "7:00 PM"},
      address: %{line_1: "2051 Fort Campbell Blvd", line_2: "Clarksville, TN 37042"},
      logo: "images/infinity-logo.png",
      url: "https://igl2.infinitygamelounge.com"
    },
    %{
      store: "The Game Lodge",
      league_night: %{day: "Tuesdays", time: "6:00 PM"},
      address: %{line_1: "1123 N Castle Heights Ave", line_2: "Lebanon, TN 37087"},
      logo: "images/game-lodge-logo.jpg",
      url: "https://thegamelodge.store"
    },
    %{
      store: "Game Knight",
      league_night: %{day: "Tuesdays", time: "6:00 PM"},
      address: %{line_1: "119 Nashville Hwy #117", line_2: "Columbia, TN 38401"},
      logo: "images/game-knight-logo.png",
      url: "https://gameknighttn.com"
    },
    %{
      store: "Middle TN Gaming",
      league_night: %{day: "Thursdays", time: "7:00 PM"},
      address: %{line_1: "7648 Hwy 70 S #20", line_2: "Nashville, TN 37221"},
      logo: "images/mid-tn-gaming-logo.png",
      url: "https://middletennesseegaming.com"
    }
  ]

  def home(conn, _params) do
    conn
    |> assign(:qualifiers, @qualifier_list)
    |> assign(:store_list, @store_list)
    |> render(:home)
  end

  def board(conn, %{"season_id" => season_id}) do
    board_list = PauperLeague.Leaderboard.get_leaderboard_by_season(season_id)

    seasons =
      PauperLeague.Seasons.Season
      |> select([s], %{id: s.id, name: s.name})
      |> order_by([s], s.season_number)
      |> PauperLeague.Repo.all()

    conn
    |> assign(:leaderboard, board_list)
    |> assign(:title, "Leaderboard")
    |> assign(:seasons, seasons)
    |> assign(:season_id, String.to_integer(season_id))
    |> render(:board)
  end

  def board(conn, _params) do
    board_list = PauperLeague.Leaderboard.get_leaderboard_by_season()

    seasons =
      PauperLeague.Seasons.Season
      |> select([s], %{id: s.id, name: s.name, active: s.active})
      |> order_by([s], s.season_number)
      |> PauperLeague.Repo.all()

    season_id = seasons |> Enum.find(fn s -> s.active end) |> Map.get(:id)

    conn
    |> assign(:leaderboard, board_list)
    |> assign(:seasons, seasons)
    |> assign(:title, "Leaderboard")
    |> assign(:season_id, season_id)
    |> render(:board)
  end

  def player(conn, %{"player_id" => player_id}) do
    with {:ok, player} <- PauperLeague.Player.player_view(player_id) do
      conn
      # |> assign(:title, "Player Info")
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
    |> assign(:title, "Deck Info")
    |> assign(:specialists, specialists)
    |> assign(:matchups, matchups)
    |> render(:deck)
  end

  def meta(conn, _) do
    last_event = PauperLeague.DeckArchetype.get_decks_last_event()
    season_totals = PauperLeague.DeckArchetype.get_decks_by_season(1)

    conn
    |> assign(:title, "Metagame")
    |> assign(:season_totals, season_totals)
    |> assign(:last_event, last_event)
    |> render(:meta)
  end

  def events(conn, _) do
    event_list = PauperLeague.Seasons.Event.get_all_events()

    conn
    |> assign(:title, "Events")
    |> assign(:event_list, event_list)
    |> render(:events)
  end

  def event(conn, %{"event_id" => event_id}) do
    event = PauperLeague.Seasons.Event.event_view(event_id)
    standings = PauperLeague.Seasons.Event.standings(event_id)

    conn
    |> assign(:title, "Event Info")
    |> assign(:event, event)
    |> assign(:standings, standings)
    |> render(:event)
  end

  def rules(conn, _) do
    conn
    |> assign(:title, "Rules")
    |> assign(:qualifiers, @qualifier_list)
    |> render(:rules)
  end
end
