defmodule PauperLeague.Workers.EventDataWorker do
  use Oban.Worker, max_attempts: 1, queue: :event_link

  import Ecto.Changeset

  def perform(%{args: %{"event_id" => eventlink_id, "store_id" => store_id}}) do
    with {_, resp} <- PauperLeague.EventlinkApi.get_event_info(eventlink_id, store_id),
         200 <- Map.get(resp, :status),
         body <- Map.get(resp, :body, %{}),
         true <- Map.has_key?(body, "data") do
      event = resp.body |> get_in(event_info_keys())

      if not is_nil(event) do
        raw_event =
          PauperLeague.Stores.RawEvent
          |> PauperLeague.Repo.get_by(eventlink_id: eventlink_id)

        params = %{data: event, event_id: raw_event.id}
        fields = [:data, :event_id]

        %PauperLeague.Stores.RawEventData{}
        |> cast(params, fields)
        |> PauperLeague.Repo.insert()
      end
    else
      429 ->
        {:error, "Rate Limited"}

      503 ->
        {:error, "Rate Limited"}

      err ->
        {:error, "Other error - state #{inspect(err)}"}
    end
  end

  def event_info_keys do
    [Access.key("data"), Access.key("event")]
  end
end
