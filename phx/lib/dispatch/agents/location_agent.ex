defmodule Dispatch.LocationAgent do
  @moduledoc """
  Holds all locations from point of update
  """

  alias Dispatch.{AgentHelper, Location}
  use Agent

  require Logger

  import Ecto.Query, only: [from: 2]
  alias HpsData.Repo
  alias HpsData.Dim

  @type location :: map

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init(), do: Enum.map(pull_locations(), &parse_geofence/1)

  defp pull_locations() do
    from(lh in Dim.LocationHistory,
      order_by: [asc: lh.start_time, asc: lh.id],
      select: %{
        start_time: lh.start_time,
        end_time: lh.end_time,
        history_id: lh.id,
        location_id: lh.location_id,
        name: lh.name,
        location_type_id: lh.location_type_id,
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
  def refresh!(), do: AgentHelper.set(__MODULE__, &init/0)

  @spec all() :: list(location)
  def all(), do: Agent.get(__MODULE__, & &1)

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
