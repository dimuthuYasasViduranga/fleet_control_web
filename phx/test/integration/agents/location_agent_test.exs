defmodule FleetControl.LocationAgentTest do
  use FleetControlWeb.RepoCase
  @moduletag :agent

  alias HpsData.Dim
  alias FleetControl.LocationAgent
  # there needs to be a test for locations set in the future (robhustness)

  setup_all _ do
    locations = Repo.all(Dim.Location)
    location_types = Repo.all(Dim.LocationType)
    closed = Enum.find(location_types, &(&1.type == "closed"))
    [locations: locations, types: location_types, closed: closed]
  end

  setup do
    LocationAgent.start_link([])
    :ok
  end

  defp to_location_history(
         types,
         locations,
         {south, north, east, west},
         name,
         type,
         start_time,
         end_time \\ nil
       ) do
    geofence =
      "#{north},#{east}|#{north},#{west}|#{south},#{west}|#{south},#{east}|#{north},#{east}"

    location_id = Enum.find(locations, &(&1.name == name)).id
    type_id = Enum.find(types, &(&1.type == type)).id

    %Dim.LocationHistory{
      lat_min: south,
      lat_max: north,
      lon_min: east,
      lon_max: west,
      timestamp: start_time,
      start_time: start_time,
      end_time: end_time,
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
      timestamp: location.timestamp,
      start_time: location.start_time,
      end_time: location.end_time
    }
  end

  describe "update -" do
    test "new location before now", %{locations: locations, types: types} do
      initial_locations = LocationAgent.all()

      existing_crusher = Enum.find(initial_locations, &(&1.name == "Crusher"))

      new_time = NaiveDateTime.add(existing_crusher.start_time, 3600)

      # end the old history
      Repo.get_by(Dim.LocationHistory, %{id: existing_crusher.history_id})
      |> Dim.LocationHistory.changeset(%{end_time: new_time})
      |> Repo.update!()

      # create a new one
      inserted =
        to_location_history(
          types,
          locations,
          {40.0, 45.0, 40.0, 45.0},
          "Crusher",
          "dump",
          new_time
        )
        |> Repo.insert!()
        |> formatter()

      # post refresh
      LocationAgent.refresh!(false)

      # store
      stored_entries = LocationAgent.all()
      new_entry = List.last(stored_entries)
      assert length(stored_entries) == length(initial_locations)
      assert new_entry.history_id == inserted.history_id

      # database
      assert_db_contains(Dim.LocationHistory, inserted, &formatter/1)
    end

    test "new location in the future", %{locations: locations, types: types} do
      initial_locations = LocationAgent.all()

      existing_crusher = Enum.find(initial_locations, &(&1.name == "Crusher"))

      new_time = ~N[3000-01-02 00:00:00.000000]

      # end the old history
      Repo.get_by(Dim.LocationHistory, %{id: existing_crusher.history_id})
      |> Dim.LocationHistory.changeset(%{end_time: new_time})
      |> Repo.update!()

      # create a new one
      inserted =
        to_location_history(
          types,
          locations,
          {40.0, 45.0, 40.0, 45.0},
          "Crusher",
          "dump",
          new_time
        )
        |> Repo.insert!()
        |> formatter()

      # post refresh
      LocationAgent.refresh!(false)

      # store
      stored_entries = LocationAgent.all()
      assert length(stored_entries) == length(initial_locations)

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
      timestamp = ~N[3000-01-01 00:00:00.000000]

      existing_locations = LocationAgent.all()

      # close existing
      Repo.update_all(Dim.LocationHistory, set: [end_time: timestamp])

      # add new locations

      new_locations =
        Enum.map(existing_locations, fn loc ->
          %{
            lat_min: loc.lat_min,
            lat_max: loc.lat_max,
            lon_min: loc.lon_min,
            lon_max: loc.lon_max,
            timestamp: timestamp,
            start_time: timestamp,
            end_time: nil,
            geofence: loc.geofence,
            location_id: loc.location_id,
            location_type_id: loc.location_type_id,
            name: loc.name,
            type: loc.type
          }
        end)

      Repo.insert_all(Dim.LocationHistory, new_locations)

      LocationAgent.refresh!(false)

      actual_between = LocationAgent.active_locations(~N[2020-08-11 00:00:00])
      actual_after = LocationAgent.active_locations(timestamp)

      assert Enum.all?(actual_between, &(NaiveDateTime.compare(&1.start_time, timestamp) == :lt))
      assert Enum.all?(actual_after, &(NaiveDateTime.compare(&1.start_time, timestamp) == :eq))
    end
  end
end
