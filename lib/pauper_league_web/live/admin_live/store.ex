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
      |> where([e], e.store_id == ^store_id)
      |> PauperLeague.Repo.all()

    {:noreply, socket |> assign(:store, store) |> assign(:event_list, events)}
  end

  @impl true
  def handle_event("check", _unsigned_params, socket) do
    store_id = socket.assigns.store.id
    store_eventlink_id = socket.assigns.store.eventlink_id

    # Initiate Job to Check Store Events
    %{
      "type" => "new_events",
      "store_id" => store_id,
      "store_eventlink_id" => store_eventlink_id
    }
    |> PauperLeague.Workers.EventWorker.new()
    |> Oban.insert()

    {:noreply, socket}
  end
end
