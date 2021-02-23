defmodule Dispatch.LocationAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias HpsData.Dim
  alias Dispatch.LocationAgent
  # there needs to be a test for locations set in the future (robhustness)

  setup_all _ do
    locations = Repo.all(Dim.Location)
    location_types = Repo.all(Dim.LocationType)
    closed = Enum.find(location_types, &(&1.type == "closed"))
    [locations: locations, types: location_types, closed: closed]
  end

  setup _ do
    LocationAgent.start_link([])
    :ok
  end

  defp to_location_history(types, locations, {south, north, east, west}, name, type, timestamp) do
    geofence =
      "#{north},#{east}|#{north},#{west}|#{south},#{west}|#{south},#{east}|#{north},#{east}"

    location_id = Enum.find(locations, &(&1.name == name)).id
    type_id = Enum.find(types, &(&1.type == type)).id

    %Dim.LocationHistory{
      lat_min: south,
      lat_max: north,
      lon_min: east,
      lon_max: west,
      timestamp: timestamp,
      geofence: geofence,
      location_id: location_id,
      location_type_id: type_id,
      name: name,
      type: type
    }
  end

  defp formatter(location) do
    %{
      history_id: location.id,
      location_id: location.location_id,
      name: location.name,
      location_type_id: location.location_type_id,
      type: location.type,
      lat_min: location.lat_min,
      lat_max: location.lat_max,
      lon_min: location.lon_min,
      lon_max: location.lon_max,
      geofence: location.geofence,
      timestamp: location.timestamp
    }
  end

  describe "update -" do
    test "new location before now", %{locations: locations, types: types} do
      initial_locations = LocationAgent.all()

      inserted =
        to_location_history(
          types,
          locations,
          {40.0, 45.0, 40.0, 45.0},
          "Crusher",
          "crusher",
          ~N[2020-01-02 00:00:00.000000]
        )
        |> Repo.insert!()
        |> formatter()

      # post refresh
      LocationAgent.refresh!()

      # store (order by location_id, which crusher already has an entry for)
      [_, new_entry | _] = stored_entries = LocationAgent.all()
      assert length(stored_entries) == length(initial_locations) + 1
      assert new_entry.history_id == inserted.history_id

      # database
      assert_db_contains(Dim.LocationHistory, inserted, &formatter/1)
    end

    test "new location in the future", %{locations: locations, types: types} do
      initial_locations = LocationAgent.all()

      inserted =
        to_location_history(
          types,
          locations,
          {40.0, 45.0, 40.0, 45.0},
          "Crusher",
          "crusher",
          ~N[2040-01-02 00:00:00.000000]
        )
        |> Repo.insert!()
        |> formatter()

      # post refresh
      LocationAgent.refresh!()

      # store (order by location_id, which crusher already has an entry for)
      [_, new_entry | _] = stored_entries = LocationAgent.all()
      assert length(stored_entries) == length(initial_locations) + 1
      assert new_entry.history_id == inserted.history_id

      # database
      assert_db_contains(Dim.LocationHistory, inserted, &formatter/1)
    end
  end

  describe "active locations -" do
    test "before any locations" do
      actual = LocationAgent.active_locations(~N[1970-01-01 00:00:00])
      assert actual == []
    end

    test "after locations" do
      n_locations = length(LocationAgent.all())
      actual = LocationAgent.active_locations()

      assert length(actual) == n_locations
    end

    test "between locations (future locations test)" do
      timestamp = ~N[2040-01-01 00:00:00.000000]

      new_locations =
        LocationAgent.all()
        |> Enum.map(fn loc ->
          %{
            lat_min: loc.lat_min,
            lat_max: loc.lat_max,
            lon_min: loc.lon_min,
            lon_max: loc.lon_max,
            timestamp: timestamp,
            geofence: loc.geofence,
            location_id: loc.location_id,
            location_type_id: loc.location_type_id,
            name: loc.name,
            type: loc.type
          }
        end)

      Repo.insert_all(Dim.LocationHistory, new_locations)

      LocationAgent.refresh!()

      actual_between = LocationAgent.active_locations(~N[2020-08-11 00:00:00])
      actual_after = LocationAgent.active_locations(timestamp)

      assert Enum.all?(actual_between, &(NaiveDateTime.compare(&1.timestamp, timestamp) == :lt))
      assert Enum.all?(actual_after, &(NaiveDateTime.compare(&1.timestamp, timestamp) == :eq))
    end
  end
end
