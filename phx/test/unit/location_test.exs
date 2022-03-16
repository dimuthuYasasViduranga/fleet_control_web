defmodule Dispatch.LocationTest do
  use ExUnit.Case, async: true
  @moduletag :unit

  alias Dispatch.Location

  setup do
    geofence = %Geo.Polygon{
      coordinates: [
        [
          # {lat, long}
          {0, 0},
          {0, 1},
          {1, 1},
          {1, 0},
          {0, 0}
        ]
      ]
    }

    %{geofence: geofence}
  end

  describe "find timed location -" do
    setup _ do
      crusher = %{
        geofence: "32.1,116.0|32.1,116.1|32.0,116.1|32.0,116.0|32.1,116.0",
        history_id: 1,
        lat_max: 32.1,
        lat_min: 32.0,
        location_id: 1,
        location_type_id: 3,
        lon_max: 116.1,
        lon_min: 116.0,
        name: "Crusher",
        polygon: %Geo.Polygon{
          coordinates: [
            [
              {32.1, 116.0},
              {32.1, 116.1},
              {32.0, 116.1},
              {32.0, 116.0},
              {32.1, 116.0}
            ]
          ],
          properties: %{},
          srid: nil
        },
        start_time: ~N[2020-01-01 00:00:00.000000],
        end_time: nil,
        type: "crusher"
      }

      closed = %{id: 1, type: "closed"}

      [crusher: crusher, closed: closed]
    end

    test "within valid", %{crusher: crusher} do
      actual = Location.find_location([crusher], 32.05, 116.05, ~N[2020-08-01 00:00:00])

      assert actual.name == "Crusher"
      assert NaiveDateTime.compare(actual.start_time, ~N[2020-01-01 00:00:00.000000]) == :eq
    end

    test "within no geofence" do
      actual = Location.find_location([], 32.05, 116.05)
      assert is_nil(actual)
    end

    test "within closed only", %{crusher: crusher, closed: closed} do
      closed_crusher =
        crusher
        |> Map.put(:location_type_id, closed.id)
        |> Map.put(:type, closed.type)

      actual = Location.find_location([closed_crusher], 32.05, 116.05, ~N[2020-08-01 00:00:00])

      assert is_nil(actual)
    end

    test "within crusher (open, closed stacked)", %{crusher: crusher, closed: closed} do
      closed_crusher =
        crusher
        |> Map.put(:location_type_id, closed.id)
        |> Map.put(:type, closed.type)
        |> Map.put(:start_time, ~N[2020-02-01 00:00:00])

      locations = [crusher, closed_crusher]

      actual = Location.find_location(locations, 32.05, 116.05, ~N[2020-08-01 00:00:00])

      assert actual == crusher
    end

    test "within different closed and open (ie name change)", %{crusher: crusher} do
      closed_geofence =
        crusher
        |> Map.put(:name, "other goefence")
        |> Map.put(:location_id, -1)
        |> Map.put(:type, "closed")

      locations = [crusher, closed_geofence]

      actual = Location.find_location(locations, 32.05, 116.05, ~N[2020-08-01 00:00:00])

      assert actual.type == "crusher"
      assert actual.name == "Crusher"
    end

    test "find no location (within geofence but before valid timestamp)", %{crusher: crusher} do
      actual = Location.find_location([crusher], 32.05, 116.05, ~N[1970-08-01 00:00:00])
      assert is_nil(actual)
    end
  end

  describe "polygon conversions" do
    test "polygon -> string" do
      expected =
        actual =
        Location.polygon_to_string(%Geo.Polygon{
          coordinates: [
            [
              {32.1, 116.0},
              {32.1, 116.1},
              {32.0, 116.1},
              {32.0, 116.0},
              {32.1, 116.0}
            ]
          ],
          properties: %{},
          srid: nil
        })

      assert actual == expected
    end

    test "string -> polygon" do
      expected = %Geo.Polygon{
        coordinates: [
          [
            {32.1, 116.0},
            {32.1, 116.1},
            {32.0, 116.1},
            {32.0, 116.0},
            {32.1, 116.0}
          ]
        ],
        properties: %{},
        srid: nil
      }

      actual =
        Location.string_to_polygon("32.1,116.0|32.1,116.1|32.0,116.1|32.0,116.0|32.1,116.0")

      assert actual == expected
    end
  end

  describe "is_within? -" do
    test "Not within", %{geofence: geofence} do
      track = %{
        position: %{latitude: 10, longitude: 10}
      }

      assert(Location.is_within?(geofence, track) == false)
    end

    test "Within", %{geofence: geofence} do
      track = %{
        position: %{latitude: 0.5, longitude: 0.5}
      }

      assert(Location.is_within?(geofence, track) == true)
    end
  end

  describe "any_within? -" do
    test "Not within", %{geofence: geofence} do
      tracks = [
        %{position: %{latitude: 10, longitude: 10}},
        %{position: %{latitude: 0, longitude: -2}},
        %{position: %{latitude: 1, longitude: 1.1}}
      ]

      assert(Location.any_within?(geofence, tracks) == false)
    end

    test "Within", %{geofence: geofence} do
      tracks = [
        %{position: %{latitude: 10, longitude: 10}},
        %{position: %{latitude: 0, longitude: -2}},
        %{position: %{latitude: 0.5, longitude: 0.5}}
      ]

      assert(Location.any_within?(geofence, tracks) == true)
    end
  end

  describe "is_stationary_within? -" do
    test "{stationary, within}", %{geofence: geofence} do
      track = %{
        position: %{latitude: 0.5, longitude: 0.5},
        velocity: %{speed: 0}
      }

      assert(Location.is_stationary_within?(geofence, track) == true)
    end

    test "{stationary, not within}", %{geofence: geofence} do
      track = %{
        position: %{latitude: 2, longitude: 2},
        velocity: %{speed: 0}
      }

      assert(Location.is_stationary_within?(geofence, track) == false)
    end

    test "{not stationary, within}", %{geofence: geofence} do
      track = %{
        position: %{latitude: 0.5, longitude: 0.5},
        velocity: %{speed: 1}
      }

      assert(Location.is_stationary_within?(geofence, track) == false)
    end

    test "{not stationary, not within}", %{geofence: geofence} do
      track = %{
        position: %{latitude: 2, longitude: 2},
        velocity: %{speed: 0.1}
      }

      assert(Location.is_stationary_within?(geofence, track) == false)
    end
  end

  describe "any_stationary_within? -" do
    test "within and stationary", %{geofence: geofence} do
      tracks = [
        %{
          position: %{latitude: 10, longitude: 10},
          velocity: %{speed: 0}
        },
        %{
          position: %{latitude: 0, longitude: -2},
          velocity: %{speed: 2}
        },
        %{
          position: %{latitude: 0.5, longitude: 0.5},
          velocity: %{speed: 0}
        }
      ]

      assert(Location.any_stationary_within?(geofence, tracks) == true)
    end

    test "Not within or stationary", %{geofence: geofence} do
      tracks = [
        %{
          position: %{latitude: 10, longitude: 10},
          velocity: %{speed: 0}
        },
        %{
          position: %{latitude: 0, longitude: -2},
          velocity: %{speed: 2}
        },
        %{
          position: %{latitude: 0.5, longitude: 0.5},
          velocity: %{speed: 1}
        }
      ]

      assert(Location.any_stationary_within?(geofence, tracks) == false)
    end
  end
end
