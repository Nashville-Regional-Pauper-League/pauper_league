defmodule PauperLeagueWeb.AdminLive.Store do
  use PauperLeagueWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"store_id" => store_id} = params, _, socket) do
    IO.inspect(params, label: "params")
    IO.inspect(socket, label: "socket")

    store = PauperLeague.Stores.Store |> PauperLeague.Repo.get(store_id)

    {:noreply, socket |> assign(:store, store)}
  end

  @impl true
  def handle_event("check", _unsigned_params, socket) do
    IO.inspect(socket)
    _store_eventlink_id = socket.assigns.store.eventlink_id

    # Initiate Job to Check Store Events

    {:noreply, socket}
  end
end
