defmodule PauperLeague.Workers.EventDataProcessor do
  use Oban.Worker, max_attempts: 1, queue: :test

  import Ecto.Changeset
  alias PauperLeague.Workers.Utils

  @impl true
  def perform(%{args: %{"event_data_id" => id} = args}) do
    %{event_id: event_id, data: raw_event_data} =
      PauperLeague.Stores.RawEventData |> PauperLeague.Repo.get(id)

    # update format
    {:ok, event_format} = Utils.get_value(raw_event_data, "eventFormat", :map)
    {:ok, event_format_str} = Utils.get_value(event_format, "name", :string)

    # update event date
    {:ok, start_time_str} = Utils.get_value(raw_event_data, "scheduledStartTime", :string)

    date =
      get_date_from_time(start_time_str)
      |> DateTime.shift_zone!("America/Chicago")
      |> DateTime.to_date()

    # update title, description, status
    {:ok, title} = Utils.get_value(raw_event_data, "title", :string)
    {:ok, description} = Utils.get_value(raw_event_data, "description", :string)
    {:ok, status} = Utils.get_value(raw_event_data, "status", :string)

    params = %{
      format: event_format_str,
      event_date: date,
      title: title,
      description: description,
      eventlink_status: status,
      internal_state: "raw_event_data_processed"
    }

    PauperLeague.Stores.RawEvent
    |> PauperLeague.Repo.get(event_id)
    |> change(params)
    |> PauperLeague.Repo.update()

    # add new players
    {:ok, players} = Utils.get_value(raw_event_data, "registeredPlayers", :list)
    # players |> Enum.each(fn p -> IO.inspect({p["firstName"], p["status"], p["personaId"]}) end)

    player_params =
      players
      |> Enum.filter(fn p ->
        keep_in = p["firstName"] != "[REDACTED]" or p["status"] == "GUEST"
        # IO.inspect({p["firstName"], p["status"], keep_in})
        keep_in
      end)
      |> Enum.uniq_by(fn p -> p["personaId"] end)
      |> Enum.map(fn p ->
        # IO.inspect({p["firstName"], p["status"], p["personaId"]})

        %{
          first_name: p["firstName"],
          last_name: p["lastName"],
          persona_id: p["personaId"],
          display_name: p["displayName"],
          inserted_at: {:placeholder, :timestamp},
          updated_at: {:placeholder, :timestamp}
        }
      end)

    timestamp =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    placeholders = %{timestamp: timestamp}

    PauperLeague.Repo.insert_all(
      PauperLeague.Player,
      player_params,
      placeholders: placeholders,
      on_conflict: {:replace_all_except, [:id, :persona_id, :inserted_at]},
      replace_changed: false,
      conflict_target: [:persona_id]
    )

    # Round 0 will be the latest round
    args
    |> PauperLeague.Workers.EventRoundWorker.new()
    |> Oban.insert()
  end

  def get_date_from_time(start_time_str) do
    with {:ok, time, _} <- DateTime.from_iso8601(start_time_str) do
      time
    end
  end
end
