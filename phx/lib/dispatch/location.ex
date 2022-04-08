defmodule Dispatch.Location do
  alias Geo.{Polygon, Point}

  @type track :: map
  @type location :: map

  @spec find_location(list(location), float, float) :: location | nil
  def find_location(locations, lat, lon) do
    locations
    |> Stream.reject(&(&1.type == "closed"))
    |> Stream.filter(&(lat >= &1.lat_min))
    |> Stream.filter(&(lat <= &1.lat_max))
    |> Stream.filter(&(lon >= &1.lon_min))
    |> Stream.filter(&(lon <= &1.lon_max))
    |> Stream.filter(&point_within_geofence(&1, lat, lon))
    |> Enum.to_list()
    |> List.first()
  end

  @spec find_location(list(location), float, float, NaiveDateTime.t()) :: location | nil
  def find_location(locations, lat, lon, timestamp) do
    locations
    |> Stream.filter(&filter_location_by_timestamp(&1, timestamp))
    |> find_location(lat, lon)
  end

  defp point_within_geofence(location, lat, lon) do
    point = %Point{coordinates: {lat, lon}}
    polygon = location.polygon
    Topo.Contains.contains?(polygon, point)
  end

  @spec filter_location_by_timestamp(location, NaiveDateTime.t()) :: bool
  def filter_location_by_timestamp(location, timestamp) do
    NaiveDateTime.compare(timestamp, location.start_time) != :lt and
      (is_nil(location[:end_time]) or NaiveDateTime.compare(timestamp, location.end_time) == :lt)
  end

  @spec polygon_to_string(Polygon.t()) :: String.t()
  def polygon_to_string(%Polygon{coordinates: coords}) do
    coords
    |> List.first()
    |> Enum.map(fn {lat, lng} -> "#{lat},#{lng}" end)
    |> Enum.join("|")
  end

  @spec string_to_polygon(String.t()) :: Polygon.t()
  def string_to_polygon(string) do
    coords =
      string
      |> String.split("|")
      |> Enum.map(&build_coordinate/1)

    %Polygon{coordinates: [coords]}
  end

  defp build_coordinate(string) do
    string
    |> String.split(",")
    |> Enum.map(&parse_float/1)
    |> Enum.reduce({}, &Tuple.append(&2, &1))
  end

  defp parse_float(string) do
    {float, _} = Float.parse(string)
    float
  end

  @spec is_stationary_within?(Polygon.t(), track) :: boolean()
  def is_stationary_within?(polygon, track) do
    cond do
      track.velocity.speed < 0.01 -> is_within?(polygon, track)
      true -> false
    end
  end

  @spec is_within?(Polygon.t(), track) :: boolean()
  def is_within?(polygon, %{position: pos}) do
    point = %Point{coordinates: {pos.latitude, pos.longitude}}
    Topo.Contains.contains?(polygon, point)
  end

  @spec any_stationary_within?(Polygon.t(), list(track)) :: boolean()
  def any_stationary_within?(polygon, tracks) do
    Enum.reduce_while(tracks, false, fn track, _acc ->
      case is_stationary_within?(polygon, track) do
        true -> {:halt, true}
        false -> {:cont, false}
      end
    end)
  end

  @spec any_within?(Polygon.t(), list(track)) :: boolean()
  def any_within?(polygon, tracks) do
    Enum.reduce_while(tracks, false, fn track, _acc ->
      case is_within?(polygon, track) do
        true -> {:halt, true}
        false -> {:cont, false}
      end
    end)
  end
end
