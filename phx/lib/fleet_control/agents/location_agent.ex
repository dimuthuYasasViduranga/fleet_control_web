defmodule FleetControl.LocationAgent do
  @moduledoc """
  Holds all locations from point of update
  """

  alias FleetControl.{AgentHelper, Location}
  use Agent

  require Logger

  import Ecto.Query, only: [from: 2]
  alias HpsData.Repo
  alias HpsData.Dim

  @type dim_location :: %{
          id: integer,
          name: String.t()
        }
  @type location :: map

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    locations =
      pull_locations()
      |> Enum.map(&parse_geofence/1)

    %{
      dim_locations: pull_dim_locations(),
      locations: locations
    }
  end

  defp pull_dim_locations() do
    from(l in Dim.Location,
      select: %{
        id: l.id,
        name: l.name
      }
    )
    |> Repo.all()
  end

  defp pull_locations() do
    now = NaiveDateTime.utc_now()

    from(lh in Dim.LocationHistory,
      left_join: mh in Dim.LocationMaterialHistory,
      on: lh.location_id == mh.location_id and lh.start_time == mh.start_time,
      left_join: m in Dim.MaterialType,
      on: [id: mh.material_type_id],
      left_join: lgh in Dim.LocationGroupHistory,
      on: lh.location_id == lgh.location_id and lh.start_time == lgh.start_time,
      left_join: lg in Dim.LocationGroup,
      on: [id: lgh.location_group_id],
      order_by: [asc: lh.start_time, asc: lh.id],
      where: lh.deleted == false,
      where: is_nil(lh.end_time) or lh.end_time > ^now,
      select: %{
        start_time: lh.start_time,
        end_time: lh.end_time,
        history_id: lh.id,
        location_id: lh.location_id,
        name: lh.name,
        location_type_id: lh.location_type_id,
        material_type_id: m.id,
        material_type: m.name,
        location_group_id: lg.id,
        location_group: lg.name,
        type: lh.type,
        lat_min: lh.lat_min,
        lat_max: lh.lat_max,
        lon_min: lh.lon_min,
        lon_max: lh.lon_max,
        geofence: lh.geofence
      }
    )
    |> Repo.all()
  end

  @spec parse_geofence(location) :: location
  def parse_geofence(location) do
    polygon = Location.string_to_polygon(location.geofence)
    Map.put(location, :polygon, polygon)
  end

  @spec refresh!() :: :ok
  def refresh!(broadcast? \\ true) do
    Agent.update(__MODULE__, fn old_data ->
      new_data = init()

      if new_data != old_data do
        Logger.warn("new locations")

        active_locations =
          new_data.locations
          |> Enum.filter(&Location.filter_location_by_timestamp(&1, NaiveDateTime.utc_now()))
          |> Enum.map(&Map.drop(&1, [:polygon]))

        payload = %{
          dim_locations: new_data.dim_locations,
          locations: active_locations
        }

        if broadcast? do
          FleetControlWeb.Endpoint.broadcast("dispatchers:all", "set location data", payload)
          FleetControlWeb.Broadcast.broadcast_all_operators("set location data", payload)
        end
      end

      new_data
    end)
  end

  @spec dim_locations() :: list(dim_location)
  def dim_locations(), do: Agent.get(__MODULE__, & &1.dim_locations)

  @spec all() :: list(location)
  def all(), do: Agent.get(__MODULE__, & &1.locations)

  @spec active_locations() :: list(location)
  def active_locations() do
    Enum.filter(all(), &Location.filter_location_by_timestamp(&1, NaiveDateTime.utc_now()))
  end

  @spec active_locations(NaiveDateTime.t()) :: list(location)
  def active_locations(timestamp) do
    Enum.filter(
      all(),
      &Location.filter_location_by_timestamp(&1, timestamp || NaiveDateTime.utc_now())
    )
  end
end
