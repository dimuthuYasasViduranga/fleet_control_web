defmodule Dispatch.LiveQueueAgent do
  use Agent

  alias Dispatch.LiveQueue

  @type track :: map()

  @type queue_state :: %{
          at_dig_units: list(Queue.queue()),
          at_dumps: list(Queue.queue())
        }

  @default_dump_queue [distance: 25, max: 150]

  # queue: [
  #   refresh_interval: 10_000,
  #   max_age: 2 * 60 * 1000,
  #   max_speed: 10,
  #   points: [
  #     %{name: "CRUSH_WFE", latitude: -22.726067, longitude: 119.020110, active_limit: 2},
  #     %{name: "CRUSH_EFE", latitude: -22.730741, longitude: 119.041375, active_limit: 2},
  #     %{name: "CRUSH_Y2", latitude: -22.725004, longitude: 119.040123},
  #     %{name: "CRUSH_Y1", latitude: -22.740177, longitude: 119.118046}
  #   ],
  #   distances: [
  #     dig_unit: [active_limit: 1, active_distance: 15, chain_distance: 50, max_distance: 400],
  #     loader: [active_distance: 35, chain_distance: 60],
  #     dump: [active_limit: 1, active_distance: 20, chain_distance: 50, max_distance: 150]
  #   ]
  # ],

  def start_link(_opts), do: Agent.start_link(fn -> init() end, name: __MODULE__)

  defp init() do
    %{
      dig_units: []
    }
  end

  @spec all() :: queue_state()
  def all(), do: Agent.get(__MODULE__, & &1)

  def update_tracks(haul_dispatches, track_map) do
    haul_trucks =
      Enum.map(haul_dispatches, fn d ->
        %{
          id: d.asset_id,
          dig_unit_id: d.dig_unit_id,
          track: get_simplified_track(track_map, d.asset_id)
        }
      end)
      |> Enum.filter(&(&1 && &1.dig_unit_id))
      |> Enum.group_by(& &1.dig_unit_id)
      |> Enum.map(fn {dig_unit_id, haul_trucks} ->
        %{
          id: dig_unit_id,
          track: get_simplified_track(track_map, dig_unit_id),
          haul_trucks: haul_trucks
        }
      end)
      |> Enum.reject(&is_nil(&1.track))

      
    # queues should look like
    # %{
    #   dig_unit_id: "",
    #   active: [
    #     %{
    #       id: "haul_truck_id",
    #       at: "dig unit id",
    #       start_time: "when it started"
    #       timestamp: "last timestamp"
    #     }
    #   ],
    #   queued: [
    #     # same as above
    #   ]
    # }
  end

  defp get_simplified_track(track_map, asset_id) do
    case track_map[asset_id] do
      nil ->
        nil

      track ->
        %{
          position: track.position,
          timestamp: track.timestamp
        }
    end
  end

  # @spec update_tracks(list(map), list(track), list(track)) :: queue_state
  # def update_tracks(dumps, dig_units, haul_trucks) do
  #   # queue_config = Application.get_env(:cluster_web, :queue, distances: [])[:distances]
  #   # dump_config = queue_config[:dump] || @default_dump_queue

  #   # Agent.get_and_update(__MODULE__, fn state ->
  #   #   dig_unit_queues =
  #   #     dig_units
  #   #     |> Queue.create_dig_unit_queues(haul_trucks, queue_config)
  #   #     |> Enum.map(&Queue.extend_queue(&1, state.dig_units))

  #   #   dump_queues =
  #   #     dumps
  #   #     |> Queue.create_dump_queues(haul_trucks, dump_config)
  #   #     |> Enum.map(&Queue.extend_queue(&1, state.dumps))

  #   #   new_state = %{
  #   #     dig_units: dig_unit_queues,
  #   #     dumps: dump_queues
  #   #   }

  #   #   {new_state, new_state}
  #   # end)
  # end
end
