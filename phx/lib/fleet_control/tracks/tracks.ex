defmodule FleetControl.Tracks do
  alias FleetControl.{Location, LocationAgent, AssetAgent, TrackAgent}
  alias FleetControlWeb.Broadcast

  @type simple_track :: map
  @type extended_track :: map

  @spec add_info(simple_track) :: extended_track()
  def add_info(track) do
    asset_map = get_asset_map()

    locations = LocationAgent.active_locations()

    add_info(track, asset_map, locations)
  end

  defp get_asset_map() do
    AssetAgent.get_assets()
    |> Enum.map(&{&1.name, &1})
    |> Enum.into(%{})
  end

  defp add_info(track, asset_map, locations) do
    track
    |> add_asset(asset_map)
    |> add_location(locations)
  end

  defp add_asset(track, asset_map) do
    case asset_map[track[:name]] do
      nil ->
        track

      asset ->
        track
        |> Map.put(:asset_id, asset.id)
        |> Map.put(:asset_name, asset.name)
        |> Map.put(:asset_type, asset.type)
    end
  end

  @spec add_location(simple_track) :: simple_track | extended_track
  def add_location(track), do: add_location(track, LocationAgent.active_locations())

  @spec add_location(simple_track, list(map)) :: simple_track | extended_track
  def add_location(%{position: pos} = track, locations) do
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

  @spec update_track_agent() :: :ok
  def update_track_agent() do
    case fetch_tracks() do
      {:ok, tracks} ->
        asset_map = get_asset_map()
        locations = LocationAgent.active_locations()

        Enum.each(tracks, fn track ->
          track =
            track
            |> add_info(asset_map, locations)
            |> Map.put(:source, :server)

          with %{asset_id: _} <- track,
               {:ok, _added_track, track_delta} <- TrackAgent.add(track) do
            Broadcast.send_track_delta(track_delta)
          else
            _ -> nil
          end
        end)

      _ ->
        nil
    end

    :ok
  end

  defp fetch_tracks() do
    case GPSGateRest.get_users() do
      {:ok, users} ->
        tracks =
          users
          |> Enum.filter(&(&1.track.valid == true))
          |> Enum.map(&extract_track_data/1)

        {:ok, tracks}

      error ->
        error
    end
  end

  defp extract_track_data(raw) do
    track = raw.track
    pos = track.position
    vel = raw.track.velocity

    %{
      name: raw.name,
      user_id: raw.id,
      position: %{
        lat: pos.latitude,
        lng: pos.longitude,
        alt: pos.altitude
      },
      speed_ms: vel.speed,
      heading: vel.heading,
      timestamp: track.timestamp,
      valid: track.valid
    }
  end
end
