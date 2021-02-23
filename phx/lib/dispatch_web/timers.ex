defmodule DispatchWeb.Timers do
  @moduledoc false

  require Logger

  alias DispatchWeb.DispatcherChannel.RefreshTopics

  @default_calendar_interval 24 * 3600 * 1000
  @default_location_interval 30 * 60 * 1000
  @default_cluster_interval 24 * 3600 * 1000
  @default_fleetops_interval 10 * 60 * 1000

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

    start_interval!("cluster agent", get_interval(:cluster_interval, @default_cluster_interval))

    start_interval!(
      "fleetops agent",
      get_interval(:fleetops_interval, @default_fleetops_interval)
    )

    :ok
  end

  defp get_interval(key, fallback), do: Application.get_env(:dispatch_web, key, fallback)

  defp start_interval!(agent, interval) do
    {:ok, {:interval, _}} = :timer.apply_interval(interval, RefreshTopics, :refresh, [agent])
  end
end
