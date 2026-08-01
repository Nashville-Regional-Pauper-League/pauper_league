defmodule PauperLeague.Workers.EventWorker do
  use Oban.Worker, max_attempts: 1, queue: :event_link

  import Ecto.Changeset
  alias PauperLeague.Stores.Store
  alias PauperLeague.Repo

  def perform(%{
        args:
          %{
            "type" => "new_events",
            "store_eventlink_id" => store_eventlink_id,
            "store_id" => store_id
          } = args
      }) do
    now = DateTime.utc_now()
    start_date = args |> Map.get("start_date", now |> DateTime.to_iso8601())

    end_date = args |> Map.get("end_date", now |> DateTime.add(7, :day) |> DateTime.to_iso8601())

    with {_, resp} <-
           PauperLeague.EventlinkApi.get_store_events(
             store_id,
             store_eventlink_id,
             start_date,
             end_date
           ),
         200 <- Map.get(resp, :status),
         body <- Map.get(resp, :body, %{}),
         true <- Map.has_key?(body, "data") do
      events = resp.body |> get_in(event_keys())

      if not is_nil(events) do
        events
        |> Enum.map(fn event ->
          store = Store |> Repo.get_by(eventlink_id: store_eventlink_id)

          params = %{eventlink_id: event["id"], store_id: store.id, internal_state: "new"}
          fields = [:eventlink_id, :store_id, :internal_state]

          %PauperLeague.Stores.RawEvent{}
          |> cast(params, fields)
          |> unique_constraint([:eventlink_id])
          |> PauperLeague.Repo.insert()
        end)
        |> Enum.filter(fn {ok, _} -> :ok == ok end)
        |> Enum.map(fn {:ok, inserted_event} ->
          %{
            "event_id" => inserted_event.eventlink_id,
            "store_id" => inserted_event.store_id
          }
          |> PauperLeague.Workers.EventDataWorker.new()
          |> Oban.insert()
        end)
      end

      :ok
    else
      429 ->
        {:error, "Rate Limited"}

      503 ->
        {:error, "Rate Limited"}

      err ->
        {:error, "Other error - state #{inspect(err)}"}
    end
  end

  def event_keys do
    [Access.key("data"), Access.key("storeEvents"), Access.key("events"), Access.all()]
  end
end
