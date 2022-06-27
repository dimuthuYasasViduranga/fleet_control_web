defmodule FleetControl.LiveQueueAgent do
  use Agent

  alias FleetControl.LiveQueue

  @type track :: map()

  @type queue_state :: %{
          at_dig_units: list(Queue.queue()),
          at_dumps: list(Queue.queue())
        }

  @opts [
    max_active: 1,
    chain_distance: 100,
    active_distance: 50
  ]

  def start_link(_opts), do: Agent.start_link(fn -> init() end, name: __MODULE__)

  defp init(), do: %{}

  @spec get() :: queue_state()
  def get(), do: Agent.get(__MODULE__, & &1)

  @spec update_tracks(list(map), map) :: {:ok, :changed | :unchanged, map}
  def update_tracks(haul_dispatches, track_map) do
    pending_queue =
      haul_dispatches
      |> format_input(track_map)
      |> LiveQueue.create(@opts)

    Agent.get_and_update(__MODULE__, fn old_queue ->
      new_queue = LiveQueue.extend(pending_queue, old_queue)

      status =
        cond do
          new_queue == old_queue -> :unchanged
          true -> :changed
        end

      {{:ok, status, new_queue}, new_queue}
    end)
  end

  defp format_input(haul_dispatches, track_map) do
    Enum.map(haul_dispatches, fn d ->
      %{
        id: d.asset_id,
        dig_unit_id: d.dig_unit_id
      }
      |> add_simplified_track(track_map, d.asset_id)
    end)
    |> Enum.filter(&(&1[:position] && &1[:dig_unit_id]))
    |> Enum.group_by(& &1.dig_unit_id)
    |> Enum.map(fn {dig_unit_id, haul_trucks} ->
      %{
        id: dig_unit_id,
        haul_trucks: haul_trucks
      }
      |> add_simplified_track(track_map, dig_unit_id)
    end)
    |> Enum.reject(&is_nil(&1[:position]))
  end

  defp add_simplified_track(map, track_map, asset_id) do
    case track_map[asset_id] do
      nil ->
        map

      track ->
        map
        |> Map.put(:position, track.position)
        |> Map.put(:timestamp, track.timestamp)
    end
  end
end
