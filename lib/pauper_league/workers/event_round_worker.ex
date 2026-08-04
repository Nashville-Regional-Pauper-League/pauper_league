defmodule PauperLeague.Workers.EventRoundWorker do
  use Oban.Worker, max_attempts: 1, queue: :event_link

  import Ecto.Changeset
  alias PauperLeague.Repo
  alias PauperLeague.Stores.RawEvent
  alias PauperLeague.Stores.RawEventRound
  alias PauperLeague.EventlinkApi
  alias PauperLeague.Workers.Utils

  def perform(%{
        args: %{"event_id" => eventlink_id, "round_no" => 0 = round_no, "store_id" => store_id}
      }) do
    with {_, resp} <- EventlinkApi.get_event_round_info(eventlink_id, round_no, store_id),
         200 <- Map.get(resp, :status),
         body <- Map.get(resp, :body, %{}),
         true <- Map.has_key?(body, "data") do
      event = resp.body |> get_in(round_info_keys())

      if not is_nil(event) do
        raw_event = RawEvent |> Repo.get_by(eventlink_id: eventlink_id)

        params = %{data: event, event_id: raw_event.id, round_no: round_no}
        fields = [:data, :round_no, :event_id]

        with {:ok, _} <- %RawEventRound{} |> cast(params, fields) |> Repo.insert(),
             {:ok, current_round} <- get_current_round(event),
             {:ok, is_final} <- Utils.get_value(current_round, "isFinalRound", :boolean),
             {:ok, last_round_no} <- Utils.get_value(current_round, "roundNumber", :integer) do
          # Schedule rest of rounds
          if is_final do
            1..last_round_no
            |> Enum.map(fn i ->
              %{"event_id" => eventlink_id, "round_no" => i, "store_id" => store_id}
              |> __MODULE__.new()
              |> Oban.insert()
            end)

            :ok
          else
            {:error, "Not final round #{inspect(event)}"}
          end
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

  def perform(%{
        args: %{"event_id" => eventlink_id, "round_no" => round_no, "store_id" => store_id}
      }) do
    with {_, resp} <- EventlinkApi.get_event_round_info(eventlink_id, round_no, store_id),
         200 <- Map.get(resp, :status),
         body <- Map.get(resp, :body, %{}),
         true <- Map.has_key?(body, "data") do
      event = resp.body |> get_in(round_info_keys())

      if not is_nil(event) do
        raw_event = RawEvent |> Repo.get_by(eventlink_id: eventlink_id)

        params = %{data: event, event_id: raw_event.id, round_no: round_no}
        fields = [:data, :round_no, :event_id]

        %RawEventRound{} |> cast(params, fields) |> Repo.insert()

        :ok
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

  def round_info_keys do
    [Access.key("data"), Access.key("gameStateV2AtRound")]
  end

  def get_current_round(event) do
    round_list = event |> Map.get("rounds")
    event_id = event |> Map.get("eventId", "Error no event id obj: #{inspect(event)}")

    case round_list do
      nil -> {:error, "No rounds #{event_id}"}
      round_list when not is_list(round_list) -> {:error, "Round list not a list #{event_id}"}
      [] -> {:error, "Round list empty #{event_id}"}
      round_list when length(round_list) > 1 -> {:error, "Too many rounds #{event_id}"}
      round_list -> {:ok, round_list |> hd()}
    end
  end
end
