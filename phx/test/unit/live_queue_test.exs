defmodule Dispatch.LiveQueueTest do
  use ExUnit.Case, async: true
  @moduletag :unit

  alias Dispatch.LiveQueue

  @dist_per_lng_at_equator 115_000

  defp to_position(lng), do: %{lat: 0, lng: lng}

  defp distance_between(a, b) do
    a_pos = {a.position.lat, a.position.lng}
    b_pos = {b.position.lat, b.position.lng}

    Distance.GreatCircle.distance(a_pos, b_pos)
  end

  describe "create/2 -" do
    test "no dig units" do
      dig_units = []

      actual = LiveQueue.create(dig_units)

      assert actual == %{}
    end

    test "dig unit with no assets" do
      timestamp = ~N[2022-01-01 00:00:00]

      dig_unit = %{
        id: "dig_unit_1",
        position: to_position(0),
        timestamp: timestamp,
        haul_trucks: []
      }

      actual = LiveQueue.create([dig_unit])

      expected = %{
        dig_unit.id => %{
          id: dig_unit.id,
          last_visited: nil,
          active: %{},
          queued: %{},
          out_of_range: %{}
        }
      }

      assert actual == expected
    end

    test "has asset - active" do
      timestamp = ~N[2022-01-01 00:00:00]
      opts = [active_distance: @dist_per_lng_at_equator * 2]

      haul_truck = %{
        id: "ht_1",
        position: to_position(1),
        timestamp: timestamp
      }

      dig_unit = %{
        id: "dig_unit_1",
        position: to_position(0),
        timestamp: timestamp,
        haul_trucks: [
          haul_truck
        ]
      }

      actual = LiveQueue.create([dig_unit], opts)

      expected = %{
        dig_unit.id => %{
          id: dig_unit.id,
          last_visited: timestamp,
          active: %{
            haul_truck.id => %{
              id: haul_truck.id,
              started_at: haul_truck.timestamp,
              last_updated: haul_truck.timestamp,
              distance_to_excavator: distance_between(haul_truck, dig_unit),
              chain_distance: distance_between(haul_truck, dig_unit)
            }
          },
          queued: %{},
          out_of_range: %{}
        }
      }

      assert actual == expected
    end

    test "has asset - queued" do
      timestamp = ~N[2022-01-01 00:00:00]
      opts = [chain_distance: @dist_per_lng_at_equator * 2]

      haul_truck = %{
        id: "ht_1",
        position: to_position(1),
        timestamp: timestamp
      }

      dig_unit = %{
        id: "dig_unit_1",
        position: to_position(0),
        timestamp: timestamp,
        haul_trucks: [
          haul_truck
        ]
      }

      actual = LiveQueue.create([dig_unit], opts)

      expected = %{
        dig_unit.id => %{
          id: dig_unit.id,
          last_visited: nil,
          active: %{},
          queued: %{
            haul_truck.id => %{
              id: haul_truck.id,
              started_at: haul_truck.timestamp,
              last_updated: haul_truck.timestamp,
              distance_to_excavator: distance_between(haul_truck, dig_unit),
              chain_distance: distance_between(haul_truck, dig_unit)
            }
          },
          out_of_range: %{}
        }
      }

      assert actual == expected
    end

    test "has asset - out_of_range" do
      timestamp = ~N[2022-01-01 00:00:00]
      opts = [chain_distance: 0]

      haul_truck = %{
        id: "ht_1",
        position: to_position(1),
        timestamp: timestamp
      }

      dig_unit = %{
        id: "dig_unit_1",
        position: to_position(0),
        timestamp: timestamp,
        haul_trucks: [
          haul_truck
        ]
      }

      actual = LiveQueue.create([dig_unit], opts)

      expected = %{
        dig_unit.id => %{
          id: dig_unit.id,
          last_visited: nil,
          active: %{},
          queued: %{},
          out_of_range: %{
            haul_truck.id => %{
              id: haul_truck.id,
              started_at: haul_truck.timestamp,
              last_updated: haul_truck.timestamp,
              distance_to_excavator: distance_between(haul_truck, dig_unit),
              chain_distance: distance_between(haul_truck, dig_unit)
            }
          }
        }
      }

      assert actual == expected
    end
  end

  describe "extend/2 -" do
    test "empty, empty" do
      actual = LiveQueue.extend(%{})

      assert actual == %{}
    end

    test "data, empty" do
      input = %{
        "dig unit 1" => %{
          id: "dig unit 1",
          last_visited: nil,
          active: %{},
          queued: %{},
          out_of_range: %{}
        }
      }

      actual = LiveQueue.extend(input)

      assert actual == input
    end

    test "out_of_range -> queued" do
      timestamp_a = ~N[2022-01-01 00:00:00]
      timestamp_b = NaiveDateTime.add(timestamp_a, 3600)

      dig_unit_id = "dig_unit_id"
      haul_truck_id = "haul_truck_id"

      queue_old = %{
        dig_unit_id => %{
          id: dig_unit_id,
          last_visited: nil,
          active: %{},
          queued: %{},
          out_of_range: %{
            haul_truck_id => %{
              id: haul_truck_id,
              started_at: timestamp_a,
              last_updated: timestamp_a,
              distance_to_excavator: nil,
              chain_distance: nil
            }
          }
        }
      }

      queue_new = %{
        dig_unit_id => %{
          id: dig_unit_id,
          last_visited: nil,
          active: %{},
          queued: %{
            haul_truck_id => %{
              id: haul_truck_id,
              started_at: timestamp_b,
              last_updated: timestamp_b,
              distance_to_excavator: nil,
              chain_distance: nil
            }
          },
          out_of_range: %{}
        }
      }

      actual = LiveQueue.extend(queue_new, queue_old)

      assert actual == queue_new
    end

    test "queued -> active" do
      timestamp_a = ~N[2022-01-01 00:00:00]
      timestamp_b = NaiveDateTime.add(timestamp_a, 3600)

      dig_unit_id = "dig_unit_id"
      haul_truck_id = "haul_truck_id"

      queue_old = %{
        dig_unit_id => %{
          id: dig_unit_id,
          last_visited: nil,
          active: %{},
          queued: %{
            haul_truck_id => %{
              id: haul_truck_id,
              started_at: timestamp_a,
              last_updated: timestamp_a,
              distance_to_excavator: nil,
              chain_distance: nil
            }
          },
          out_of_range: %{}
        }
      }

      queue_new = %{
        dig_unit_id => %{
          id: dig_unit_id,
          last_visited: timestamp_b,
          active: %{
            haul_truck_id => %{
              id: haul_truck_id,
              started_at: timestamp_b,
              last_updated: timestamp_b,
              distance_to_excavator: nil,
              chain_distance: nil
            }
          },
          queued: %{},
          out_of_range: %{}
        }
      }

      actual = LiveQueue.extend(queue_new, queue_old)

      assert actual == queue_new
    end

    test "active -> active (still in active)" do
      timestamp_a = ~N[2022-01-01 00:00:00]
      timestamp_b = NaiveDateTime.add(timestamp_a, 3600)

      dig_unit_id = "dig_unit_id"
      haul_truck_id = "haul_truck_id"

      queue_old = %{
        dig_unit_id => %{
          id: dig_unit_id,
          last_visited: timestamp_a,
          active: %{
            haul_truck_id => %{
              id: haul_truck_id,
              started_at: timestamp_a,
              last_updated: timestamp_a,
              distance_to_excavator: 1,
              chain_distance: 1
            }
          },
          queued: %{},
          out_of_range: %{}
        }
      }

      queue_new = %{
        dig_unit_id => %{
          id: dig_unit_id,
          last_visited: timestamp_b,
          active: %{
            haul_truck_id => %{
              id: haul_truck_id,
              started_at: timestamp_b,
              last_updated: timestamp_b,
              distance_to_excavator: 2,
              chain_distance: 2
            }
          },
          queued: %{},
          out_of_range: %{}
        }
      }

      expected = %{
        dig_unit_id => %{
          id: dig_unit_id,
          last_visited: timestamp_b,
          active: %{
            haul_truck_id => %{
              id: haul_truck_id,
              started_at: timestamp_a,
              last_updated: timestamp_b,
              distance_to_excavator: 2,
              chain_distance: 2
            }
          },
          queued: %{},
          out_of_range: %{}
        }
      }

      actual = LiveQueue.extend(queue_new, queue_old)

      assert actual == expected
    end

    test "active -> queued (checking for last visisted)" do
      timestamp_a = ~N[2022-01-01 00:00:00]
      timestamp_b = NaiveDateTime.add(timestamp_a, 3600)

      dig_unit_id = "dig_unit_id"
      haul_truck_id = "haul_truck_id"

      queue_old = %{
        dig_unit_id => %{
          id: dig_unit_id,
          last_visited: timestamp_a,
          active: %{
            haul_truck_id => %{
              id: haul_truck_id,
              started_at: timestamp_a,
              last_updated: timestamp_a,
              distance_to_excavator: 1,
              chain_distance: 1
            }
          },
          queued: %{},
          out_of_range: %{}
        }
      }

      queue_new = %{
        dig_unit_id => %{
          id: dig_unit_id,
          last_visited: timestamp_b,
          active: %{},
          queued: %{},
          out_of_range: %{
            haul_truck_id => %{
              id: haul_truck_id,
              started_at: timestamp_b,
              last_updated: timestamp_b,
              distance_to_excavator: 2,
              chain_distance: 2
            }
          }
        }
      }

      expected = %{
        dig_unit_id => %{
          id: dig_unit_id,
          last_visited: timestamp_a,
          active: %{},
          queued: %{},
          out_of_range: %{
            haul_truck_id => %{
              id: haul_truck_id,
              started_at: timestamp_b,
              last_updated: timestamp_b,
              distance_to_excavator: 2,
              chain_distance: 2
            }
          }
        }
      }

      actual = LiveQueue.extend(queue_new, queue_old)

      assert actual == expected
    end
  end
end
