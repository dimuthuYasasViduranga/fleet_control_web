defmodule Dispatch.Tracks do
  alias Dispatch.{Location, LocationAgent, AssetAgent, HaulTruckDispatchAgent}
  alias __MODULE__.Pathing

  @type simple_track :: map
  @type extended_track :: map

  @spec add_info(simple_track) :: extended_track()
  def add_info(track) do
    track
    |> add_asset()
    |> add_location()
    |> add_asset_type_info()
  end

  defp add_asset(track) do
    case AssetAgent.get_asset(%{name: track.name}) do
      nil ->
        track

      asset ->
        track
        |> Map.put(:asset_id, asset.id)
        |> Map.put(:asset_name, asset.name)
        |> Map.put(:asset_type, asset.type)
    end
  end

  defp add_location(%{position: pos} = track) do
    locations = LocationAgent.active_locations()

    case Location.find_location(locations, pos.lat, pos.lng) do
      nil ->
        track

      location ->
        track
        |> Map.put(:location_id, location.location_id)
        |> Map.put(:location_history_id, location.history_id)
        |> Map.put(:location_name, location.name)
        |> Map.put(:location_type_id, location.location_type_id)
        |> Map.put(:location_type, location.type)
    end
  end

  defp add_asset_type_info(%{asset_type: "Haul Truck"} = track) do
    case HaulTruckDispatchAgent.get(%{asset_id: track.asset_id}) do
      nil ->
        track

      assignment ->
        cur_loc_id = Map.get(track, :location_id)
        coord = track.position
        coord = Map.put(coord, :lon, coord.lng)

        # TODO: replace with dig_unit tracking (all other tracks must come along with this call)
        # {load_location_distance, load_location_path} =
        #   get_cluster_path(coord, assignment.load_location_id, cur_loc_id)

        {dump_location_distance, dump_location_path} =
          get_cluster_path(coord, assignment.dump_location_id, cur_loc_id)

        haul_truck_info = %{
          current_cluster_id: get_cluster_id(coord),
          dump_location_id: assignment.dump_location_id,
          dump_location_distance: dump_location_distance,
          dump_location_path: dump_location_path
        }

        Map.put(track, :haul_truck_info, haul_truck_info)
    end
  end

  defp add_asset_type_info(track), do: track

  defp get_cluster_id(%{lat: lat, lon: lon}) do
    {clusters, _neighbours, _locations} = ClusterGraph.Agent.get()
    from_coordinate = UTM.from_wgs84(lat, lon)

    case ClusterGraph.Closest.closest(clusters, from_coordinate) do
      nil -> nil
      {_dist, %{id: id}} -> id
    end
  end

  defp get_cluster_path(nil, _, _), do: {nil, []}

  defp get_cluster_path(_, nil, _), do: {nil, []}

  defp get_cluster_path(_, _, nil), do: {nil, []}

  defp get_cluster_path(coord, target_location_id, current_location_id) do
    case target_location_id == current_location_id do
      true ->
        {0, []}

      _ ->
        case Pathing.distance_to(coord, target_location_id) do
          {:ok, distance, path} -> {distance, path}
          {:error, _} -> {nil, []}
        end
    end
  end
end
