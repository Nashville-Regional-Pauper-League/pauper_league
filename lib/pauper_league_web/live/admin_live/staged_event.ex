defmodule PauperLeagueWeb.AdminLive.StagedEvent do
  use PauperLeagueWeb, :live_view

  # import Ecto.Query
  import Ecto.Changeset
  alias PauperLeague.Repo
  @impl true
  def mount(_params, _session, socket) do
    changeset = %PauperLeague.Stage.Event.EventTeam{} |> change()

    socket =
      assign(socket, default_decks: PauperLeague.DeckArchetype.all())
      |> assign(:form, to_form(changeset))
      |> assign(:ready_to_publish, false)
      |> assign(:published_id, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"stage_event_id" => stage_event_id} = _params, _, socket) do
    event = PauperLeague.Stage.Event.event_view(stage_event_id)

    season_event =
      PauperLeague.Seasons.Event
      |> PauperLeague.Repo.get_by(eventlink_id: event.eventlink_id)

    season_event_id = if not is_nil(season_event), do: season_event.id, else: nil

    standings =
      PauperLeague.Stage.Event.standings(stage_event_id)

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

    PauperLeague.Stage.Event.EventTeam
    |> Repo.get(event_team_id)
    |> change(%{deck_archetype_id: found_deck_archetype.id})
    |> Repo.update()

    standings =
      PauperLeague.Stage.Event.standings(socket.assigns.event.event_id)

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

  @impl true
  def handle_event("remove-deck", %{"value" => event_team_id}, socket) do
    PauperLeague.Stage.Event.EventTeam
    |> Repo.get(event_team_id)
    |> change(%{deck_archetype_id: nil})
    |> Repo.update()

    standings =
      PauperLeague.Stage.Event.standings(socket.assigns.event.event_id)

    {:noreply,
     socket
     |> assign(:standings, standings)
     |> assign(:ready_to_publish, false)
     |> put_flash(:info, "Deck updated")}
  end

  @impl true
  def handle_event(
        "publish-event",
        %{"value" => staged_event_id},
        # %{"event_team" => %{"deck_archetype_id" => deck_archetype_id}} = params,
        socket
      ) do
    case Integer.parse(staged_event_id) do
      :error ->
        {:noreply, socket}

      {parsed_staged_event_id, _} ->
        PauperLeague.Stage.Event.publish_staged_event(parsed_staged_event_id)
        stage_event = PauperLeague.Stage.Event |> Repo.get(parsed_staged_event_id)

        season_event =
          PauperLeague.Seasons.Event
          |> PauperLeague.Repo.get_by(eventlink_id: stage_event.eventlink_id)

        {:noreply,
         socket |> assign(:ready_to_publish, false) |> assign(:published_id, season_event.id)}
    end
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
