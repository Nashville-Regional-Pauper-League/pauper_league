defmodule PauperLeagueWeb.AdminLive.PublishedEvent do
  use PauperLeagueWeb, :live_view

  # import Ecto.Query
  import Ecto.Changeset
  alias PauperLeague.Repo
  @impl true
  def mount(_params, _session, socket) do
    changeset = %PauperLeague.Seasons.Event.EventTeam{} |> change()

    socket =
      assign(socket, default_decks: PauperLeague.DeckArchetype.all())
      |> assign(:form, to_form(changeset))
      |> assign(:ready_to_publish, false)
      |> assign(:published_id, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"published_event_id" => stage_event_id} = _params, _, socket) do
    event = PauperLeague.Seasons.Event.event_view(stage_event_id) |> IO.inspect()

    season_event =
      PauperLeague.Seasons.Event
      |> PauperLeague.Repo.get_by(eventlink_id: event.eventlink_id)
      |> IO.inspect()

    season_event_id = if not is_nil(season_event), do: season_event.id, else: nil |> IO.inspect()

    standings =
      PauperLeague.Seasons.Event.standings(stage_event_id)

    all_players_have_decks =
      standings
      |> Enum.filter(fn p -> is_nil(p.deck_id) end)
      |> length()
      |> Kernel.==(0)
      |> IO.inspect(label: "ready to publish")

    {:noreply,
     socket
     |> assign(:event, event)
     |> assign(:ready_to_publish, all_players_have_decks)
     |> assign(:standings, standings)
     |> assign(:published_id, season_event_id)}
  end

  @impl true
  def handle_event("live_select_change", %{"id" => id, "text" => text}, socket) do
    options =
      if text == "" do
        socket.assigns.default_decks
      else
        socket.assigns.default_decks
        |> Enum.map(fn d -> Map.get(d, :label) end)
        |> Enum.filter(&(String.downcase(&1) |> String.contains?(String.downcase(text))))
      end

    send_update(LiveSelect.Component, options: options, id: id)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "add-deck-" <> event_team_id,
        %{"event_team" => %{"deck_archetype_id" => deck_archetype_id}},
        socket
      ) do
    found_deck_archetype = lookup_deck(deck_archetype_id)

    PauperLeague.Seasons.Event.EventTeam
    |> Repo.get(event_team_id)
    |> change(%{deck_archetype_id: found_deck_archetype.id})
    |> Repo.update()

    standings =
      PauperLeague.Seasons.Event.standings(socket.assigns.event.event_id)

    all_players_have_decks =
      standings
      |> Enum.filter(fn p -> is_nil(p.deck_id) end)
      |> length()
      |> Kernel.==(0)
      |> IO.inspect(label: "ready to publish")

    {:noreply,
     socket
     |> assign(:standings, standings)
     |> assign(:ready_to_publish, all_players_have_decks)
     |> put_flash(:info, "Deck updated")}
  end

  def lookup_deck(deck_id) do
    case Integer.parse(deck_id) do
      :error ->
        PauperLeague.DeckArchetype.get_by_name(deck_id)

      {parsed_deck_id, _} ->
        PauperLeague.DeckArchetype.get_by_id(parsed_deck_id)
    end
  end
end
