defmodule PauperLeagueWeb.AdminLive.Store do
  use PauperLeagueWeb, :live_view

  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"store_id" => store_id} = _params, _, socket) do
    store = PauperLeague.Stores.Store |> PauperLeague.Repo.get(store_id)

    events =
      PauperLeague.Stores.RawEvent
      |> join(:left, [e], se in PauperLeague.Seasons.Event, on: e.eventlink_id == se.eventlink_id)
      |> join(:left, [e], ste in PauperLeague.Stage.Event, on: e.eventlink_id == ste.eventlink_id)
      |> where([e], e.store_id == ^store_id)
      |> where([e], e.format == "Pauper")
      |> order_by([e], desc: e.event_date)
      |> select_merge([_, se, ste], %{season_event_id: se.id, stage_event_id: ste.id})
      |> PauperLeague.Repo.all()
      |> PauperLeague.Repo.preload(event_rounds: &most_recent_round_data/1)
      |> Enum.map(fn event ->
        completed_rounds_ct =
          event.event_rounds
          |> Enum.filter(fn round ->
            # all rounds have matches
            matches =
              round
              |> Map.get(:data, %{})
              |> Map.get("rounds", [%{}])
              |> hd()
              |> Map.get("matches", [])

            matches_with_results =
              matches
              |> Enum.map(fn match ->
                match |> Map.get("results")
              end)
              |> Enum.filter(fn results -> not is_nil(results) end)

            # all matches have results
            length(matches) > 0 and length(matches) == length(matches_with_results)
          end)
          |> length()

        event
        |> Map.put(:completed_rounds, completed_rounds_ct)
      end)

    {:noreply, socket |> assign(:store, store) |> assign(:event_list, events)}
  end

  def most_recent_round_data(event_round_ids) do
    from(er in PauperLeague.Stores.RawEventRound)
    |> where([er], er.event_id in ^event_round_ids)
    |> where([er], er.round_no in [1, 2, 3])
    |> order_by([er], asc: er.round_no, desc: er.inserted_at)
    |> distinct([er], [er.event_id, er.round_no])
    |> PauperLeague.Repo.all()
  end

  @impl true
  def handle_event("check", %{"value" => direction}, socket) do
    store_id = socket.assigns.store.id
    store_eventlink_id = socket.assigns.store.eventlink_id

    # Initiate Job to Check Store Events
    %{
      "type" => "new_events",
      "store_id" => store_id,
      "store_eventlink_id" => store_eventlink_id,
      "direction" => direction
    }
    |> PauperLeague.Workers.EventWorker.new()
    |> Oban.insert()

    {:noreply, socket}
  end

  @impl true
  def handle_event("check_event_status", _unsigned_params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("check_event_rounds", %{"value" => event_id}, socket) do
    raw_event = PauperLeague.Stores.RawEvent |> PauperLeague.Repo.get(event_id)

    %{
      "event_id" => raw_event.eventlink_id,
      "store_id" => raw_event.store_id
    }
    |> PauperLeague.Workers.EventDataWorker.new()
    |> Oban.insert()

    {:noreply, socket}
  end

  @impl true
  def handle_event("stage_event", %{"value" => event_id}, socket) do
    PauperLeague.Stores.RawEvent.stage_event_data(event_id)

    {:noreply, socket}
  end
end
