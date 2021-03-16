defmodule Dispatch.Tracks do
  alias Dispatch.{Location, LocationAgent, AssetAgent}

  @type simple_track :: map
  @type extended_track :: map

  @spec add_info(simple_track) :: extended_track()
  def add_info(track) do
    track
    |> add_asset()
    |> add_location()
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
end
