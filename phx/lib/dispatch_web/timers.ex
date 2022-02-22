defmodule DispatchWeb.Timers do
  @moduledoc false

  alias DispatchWeb.DispatcherChannel.RefreshTopics
  alias Dispatch.{HaulTruckDispatchAgent, TrackAgent, LiveQueueAgent}

  @default_calendar_interval 24 * 3600 * 1000
  @default_location_interval 30 * 60 * 1000
  @default_fleetops_interval 10 * 60 * 1000
  @default_live_queue_interval 10 * 1000

  @spec start() :: :ok
  def start() do
    start_interval!(
      "calendar agent",
      get_interval(:calendar_interval, @default_calendar_interval)
    )

    start_interval!(
      "location agent",
      get_interval(:location_interval, @default_location_interval)
    )

    start_interval!(
      "fleetops agent",
      get_interval(:fleetops_interval, @default_fleetops_interval)
    )

    start_live_queue_interval!(get_interval(:live_queue_interval, @default_live_queue_interval))

    :ok
  end

  defp get_interval(key, fallback), do: Application.get_env(:dispatch_web, key, fallback)

  defp start_interval!(agent, interval) do
    {:ok, {:interval, _}} = :timer.apply_interval(interval, RefreshTopics, :refresh, [agent])
  end

  defp start_live_queue_interval!(interval) do
    {:ok, {:interval, _}} = :timer.apply_interval(interval, __MODULE__, :update_live_queue, [])
  end

  def update_live_queue() do
    IO.inspect("---- update live queueu")

    LiveQueueAgent.update_tracks(HaulTruckDispatchAgent.current(), TrackAgent.as_map())

    # get all tracks a map

    # get all relevant info
    # get haul dispatches
    # get dig unit activities

    # for each set, group with track and filter out if missing
  end
end
