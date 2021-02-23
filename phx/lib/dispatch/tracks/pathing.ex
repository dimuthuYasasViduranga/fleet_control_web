defmodule Dispatch.Tracks.Pathing do
  alias ClusterGraph.{Agent, Closest, Graph}
  require Logger

  @type distance_errors ::
          :cannot_find_cluster | :destination_not_set | :cannot_find_target | :invalid_coordinate

  def graph(), do: Agent.get()

  @spec distance_to(map, integer) ::
          {:error, distance_errors} | {:ok, float, list}
  def distance_to(_, nil), do: {:error, :destination_not_set}

  def distance_to(nil, _), do: {:error, :invalid_coordinate}

  def distance_to(coord, final_location_id) do
    try do
      {clusters, neighbours, locations} = Agent.get()

      case select_cluster(coord, clusters) do
        nil ->
          {:error, :cannot_find_cluster}

        {_, current_cluster} ->
          case get_target(locations, final_location_id) do
            {:ok, target} ->
              clusters = to_cluster_map(clusters)

              path =
                Graph.path(
                  current_cluster.id,
                  neighbours,
                  clusters,
                  target,
                  final_location_id
                )

              distance = Graph.path_distance(path, neighbours)
              {:ok, distance, path}

            _ ->
              {:error, :cannot_find_target}
          end
      end
    rescue
      _ ->
        Logger.error("[Pathing] Unable to find path to target")
        {:error, :cannot_find_target}
    end
  end

  defp to_cluster_map(clusters) do
    clusters
    |> Enum.map(fn c ->
      {c.id, %{north: c.north, east: c.east, location_id: c.location_id}}
    end)
    |> Map.new()
  end

  defp select_cluster(%{lat: lat, lon: lon}, clusters) do
    from_coordinate = UTM.from_wgs84(lat, lon)
    Closest.closest(clusters, from_coordinate)
  end

  defp select_cluster(_, _), do: nil

  defp get_target(locations, final_location_id) do
    locations
    |> Enum.filter(&(&1.id == final_location_id))
    |> List.first()
    |> case do
      nil -> {:error, :location_not_found}
      loc -> {:ok, Map.get(loc, :center)}
    end
  end
end
