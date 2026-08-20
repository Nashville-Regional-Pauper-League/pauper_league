defmodule PauperLeague.Workers.EventDataWorker do
  use Oban.Worker, max_attempts: 1, queue: :event_link

  import Ecto.Changeset
  alias PauperLeague.Repo
  alias PauperLeague.Stores.RawEvent
  alias PauperLeague.Stores.RawEventData

  def perform(%{args: %{"event_id" => eventlink_id, "store_id" => store_id}}) do
    with {_, resp} <- PauperLeague.EventlinkApi.get_event_info(eventlink_id, store_id),
         200 <- Map.get(resp, :status),
         body <- Map.get(resp, :body, %{}),
         true <- Map.has_key?(body, "data") do
      event = resp.body |> get_in(event_info_keys())

      if not is_nil(event) do
        raw_event = RawEvent |> Repo.get_by(eventlink_id: eventlink_id)

        params = %{data: event, event_id: raw_event.id}
        fields = [:data, :event_id]

        with {:ok, inserted_event_data} <-
               %RawEventData{} |> cast(params, fields) |> Repo.insert() do
          raw_event
          |> change(%{internal_state: "raw_event_data"})
          |> Repo.update()

          %{
            "event_id" => raw_event.eventlink_id,
            "store_id" => raw_event.store_id,
            "round_no" => 0,
            "event_data_id" => inserted_event_data.id
          }
          |> PauperLeague.Workers.EventDataProcessor.new()
          |> Oban.insert()
        end
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
