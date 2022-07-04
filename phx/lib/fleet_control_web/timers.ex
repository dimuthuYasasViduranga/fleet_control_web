defmodule FleetControlWeb.Timers do
  @moduledoc false

  alias FleetControlWeb.DispatcherChannel.Topics
  alias FleetControl.{HaulTruckDispatchAgent, TrackAgent, LiveQueueAgent}
  alias FleetControlWeb.Broadcast

  @default_calendar_interval 24 * 3600 * 1000
  @default_location_interval 30 * 60 * 1000
  @default_fleetops_interval 10 * 60 * 1000
  @default_live_queue_interval 10 * 1000
  @default_track_interval 10 * 1000
  @default_track_broadcast_interval 60 * 1000

  @spec start() :: :ok
  def start() do
    start_refresh_interval!(
      "calendar agent",
      get_interval(:calendar_interval, @default_calendar_interval)
    )

    start_refresh_interval!(
      "location agent",
      get_interval(:location_interval, @default_location_interval)
    )

    start_refresh_interval!(
      "fleetops agent",
      get_interval(:fleetops_interval, @default_fleetops_interval)
    )

    start_live_queue_interval!(get_interval(:live_queue_interval, @default_live_queue_interval))

    start_track_interval!(get_interval(:track_interval, @default_track_interval))

    start_track_broadcast_interval!(
      get_interval(:track_broadcast_interval, @default_track_broadcast_interval)
    )

    :ok
  end

  defp get_interval(key, fallback), do: Application.get_env(:fleet_control_web, key, fallback)

  defp start_interval!(interval, module, func, args) do
    {:ok, {:interval, _}} = :timer.apply_interval(interval, module, func, args)
  end

  defp start_refresh_interval!(agent, interval) do
    start_interval!(interval, Topics.Refresh, :refresh, [agent])
  end

  defp start_live_queue_interval!(interval) do
    start_interval!(interval, __MODULE__, :update_live_queue, [])
  end

  defp start_track_interval!(interval) do
    start_interval!(interval, FleetControl.Tracks, :update_track_agent, [])
  end

  defp start_track_broadcast_interval!(interval) do
    :timer.apply_interval(interval, __MODULE__, :broadcast_tracks, [])
  end

  def update_live_queue() do
    haul_truck_dispatches = HaulTruckDispatchAgent.current()
    track_map = TrackAgent.as_map()

    case LiveQueueAgent.update_tracks(haul_truck_dispatches, track_map) do
      {:ok, :changed, queue} ->
        Broadcast.send_live_queue(queue)

      _ ->
        nil
    end
  end

  def broadcast_tracks() do
    tracks = TrackAgent.all()
    Syncro.Broadcast.broadcast("tracks:set", %{tracks: tracks})
  end
end
