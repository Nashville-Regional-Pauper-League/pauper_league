defmodule PauperLeague.Workers.EventWorker do
  use Oban.Worker

  import Ecto.Changeset

  def perform(%{args: %{"type" => "new_events", "store_id" => store_id}}) do
    with {_, resp} <- PauperLeague.EventlinkApi.get_store_events(store_id),
         200 <- Map.get(resp, :status),
         body <- Map.get(resp, :body, %{}),
         true <- Map.has_key?(body, "data") do
      events = resp.body |> get_in(event_keys())

      if not is_nil(events) do
        events
        |> Enum.map(fn event ->
          store = PauperLeague.Stores.Store |> PauperLeague.Repo.get_by(eventlink_id: store_id)

          %PauperLeague.Seasons.Event{}
          |> cast(%{eventlink_id: event["id"], store_id: store.id}, [:eventlink_id, :store_id])
          |> unique_constraint([:eventlink_id])
          |> PauperLeague.Repo.insert()
        end)
      end
    end
  end

  def event_keys do
    [Access.key("data"), Access.key("storeEvents"), Access.key("events"), Access.all()]
  end
end
