defmodule Dispatch.LiveQueueTest do
  use ExUnit.Case, async: true
  @moduletag :unit

  alias Dispatch.LiveQueue

  @dist_per_lng_at_equator 115_000

  defp to_target(name, lat, lng, opts \\ []) do
    %{
      name: name,
      lat: lat,
      lng: lng,
      location: nil,
      opts: opts
    }
  end

  defp to_track(lng), do: %{position: %{lat: 0, lng: lng}}

  defp to_track(name, lat, lng, timestamp \\ NaiveDateTime.utc_now()) do
    %{
      name: name,
      position: %{lat: lat, lng: lng},
      timestamp: timestamp
    }
  end

  describe "chain/4 -" do
    test "no tracks" do
      actual = LiveQueue.chain_from(%{lat: 0, lng: 0}, [], 50)
      assert actual == []
    end

    test "single track - within chaining" do
      start = %{lat: 0, lng: 0}
      track = to_track(1)

      actual = LiveQueue.chain_from(start, [track], @dist_per_lng_at_equator)

      assert actual == [track]
    end

    test "single track - outside of chaining" do
      start = %{lat: 0, lng: 0}
      track = to_track(2)

      actual = LiveQueue.chain_from(start, [track], @dist_per_lng_at_equator)

      assert actual == []
    end

    test "multiple tracks - inside chaining" do
      start = %{lat: 0, lng: 0}
      track_1 = to_track(1)
      track_2 = to_track(2)

      actual = LiveQueue.chain_from(start, [track_1, track_2], @dist_per_lng_at_equator)

      assert actual == [track_1, track_2]
    end

    test "multiple tracks - 1 inside, 1 outside" do
      start = %{lat: 0, lng: 0}
      track_1 = to_track(1)
      track_2 = to_track(10)

      actual = LiveQueue.chain_from(start, [track_1, track_2], @dist_per_lng_at_equator)

      assert actual == [track_1]
    end

    test "multiple track - both inside, 2nd outside max range" do
      start = %{lat: 0, lng: 0}
      track_1 = to_track(1)
      track_2 = to_track(2)

      actual =
        LiveQueue.chain_from(
          start,
          [track_1, track_2],
          @dist_per_lng_at_equator,
          @dist_per_lng_at_equator
        )

      assert actual == [track_1]
    end

    test "chain all at infinity" do
      start = %{lat: 0, lng: 0}
      track_1 = to_track(1)
      track_2 = to_track(2)
      track_3 = to_track(10)

      actual =
        LiveQueue.chain_from(
          start,
          [track_1, track_2, track_3],
          :infinity
        )

      assert actual == [track_1, track_2, track_3]
    end
  end

  describe "create_queues/2 -" do
    test "no targets, no tracks" do
      actual = LiveQueue.create_queues([], [])
      assert actual == []
    end

    test "targets, no tracks" do
      target = to_target("EX01", 0, 0)

      expected = [
        %{
          name: target.name,
          location: nil,
          last_visited: nil,
          active: [],
          queued: []
        }
      ]

      actual = LiveQueue.create_queues([target], [])
      assert actual == expected
    end

    test "no targets, tracks" do
      actual = LiveQueue.create_queues([], [to_track("DT01", 0, 0)])
      assert actual == []
    end

    test "nothing" do
      actual = LiveQueue.create_queues([], [])
      assert actual == []
    end

    test "track out of active and queue range" do
      opts = [active_distance: @dist_per_lng_at_equator, chain_distance: @dist_per_lng_at_equator]
      target = to_target("EX01", 0, 0, opts)
      track = to_track("DT01", 0, 10)

      expected = [
        %{
          name: target.name,
          location: nil,
          last_visited: nil,
          active: [],
          queued: []
        }
      ]

      actual = LiveQueue.create_queues([target], [track])

      assert actual == expected
    end

    test "track in active range" do
      opts = [active_distance: @dist_per_lng_at_equator, chain_distance: @dist_per_lng_at_equator]
      target = to_target("EX01", 0, 0, opts)
      track = to_track("DT01", 0, 1)

      expected = [
        %{
          name: target.name,
          location: nil,
          last_visited: track.timestamp,
          active: [
            %{
              name: track.name,
              at: target.name,
              start_time: track.timestamp,
              timestamp: track.timestamp
            }
          ],
          queued: []
        }
      ]

      actual = LiveQueue.create_queues([target], [track])

      assert actual == expected
    end

    test "track in queue range, but not active" do
      opts = [
        active_distance: @dist_per_lng_at_equator,
        chain_distance: 2 * @dist_per_lng_at_equator
      ]

      target = to_target("EX01", 0, 0, opts)
      track = to_track("DT01", 0, 1.5)

      expected = [
        %{
          name: target.name,
          location: nil,
          last_visited: track.timestamp,
          active: [],
          queued: [
            %{
              name: track.name,
              at: target.name,
              start_time: track.timestamp,
              timestamp: track.timestamp
            }
          ]
        }
      ]

      actual = LiveQueue.create_queues([target], [track])

      assert actual == expected
    end

    test "1 in active, 1 in queue" do
      opts = [
        active_distance: @dist_per_lng_at_equator,
        chain_distance: @dist_per_lng_at_equator
      ]

      target = to_target("EX01", 0, 0, opts)
      track_a = to_track("DT01", 0, 1)
      track_b = to_track("DT02", 0, 1.5)

      expected = [
        %{
          name: target.name,
          location: nil,
          last_visited: track_a.timestamp,
          active: [
            %{
              name: track_a.name,
              at: target.name,
              start_time: track_a.timestamp,
              timestamp: track_a.timestamp
            }
          ],
          queued: [
            %{
              name: track_b.name,
              at: target.name,
              start_time: track_b.timestamp,
              timestamp: track_b.timestamp
            }
          ]
        }
      ]

      actual = LiveQueue.create_queues([target], [track_a, track_b])

      assert actual == expected
    end

    test "one target, 2 in active (no limit)" do
      opts = [
        active_distance: @dist_per_lng_at_equator,
        chain_distance: @dist_per_lng_at_equator
      ]

      target = to_target("EX01", 0, 0, opts)
      track_a = to_track("DT01", 0, 0.5)
      track_b = to_track("DT02", 0, 1)

      expected = [
        %{
          name: target.name,
          location: nil,
          last_visited: track_a.timestamp,
          active: [
            %{
              name: track_a.name,
              at: target.name,
              start_time: track_a.timestamp,
              timestamp: track_a.timestamp
            },
            %{
              name: track_b.name,
              at: target.name,
              start_time: track_b.timestamp,
              timestamp: track_b.timestamp
            }
          ],
          queued: []
        }
      ]

      actual = LiveQueue.create_queues([target], [track_a, track_b])

      assert actual == expected
    end

    test "one target, 2 in active (limit of 1)" do
      opts = [
        active_limit: 1,
        active_distance: @dist_per_lng_at_equator,
        chain_distance: @dist_per_lng_at_equator
      ]

      target = to_target("EX01", 0, 0, opts)
      track_a = to_track("DT01", 0, 0.5)
      track_b = to_track("DT02", 0, 1)

      expected = [
        %{
          name: target.name,
          location: nil,
          last_visited: track_a.timestamp,
          active: [
            %{
              name: track_a.name,
              at: target.name,
              start_time: track_a.timestamp,
              timestamp: track_a.timestamp
            }
          ],
          queued: [
            %{
              name: track_b.name,
              at: target.name,
              start_time: track_b.timestamp,
              timestamp: track_b.timestamp
            }
          ]
        }
      ]

      actual = LiveQueue.create_queues([target], [track_a, track_b])

      assert actual == expected
    end

    test "multiple targets, single track in queue of both" do
      opts = [
        active_distance: 0,
        chain_distance: @dist_per_lng_at_equator
      ]

      target_a = to_target("EX01", 0, 0, opts)
      track = to_track("DT01", 0, 1)
      target_b = to_target("EX02", 0, 2, opts)

      expected = [
        %{
          name: target_a.name,
          location: nil,
          last_visited: track.timestamp,
          active: [],
          queued: [
            %{
              name: track.name,
              at: target_a.name,
              start_time: track.timestamp,
              timestamp: track.timestamp
            }
          ]
        },
        %{
          name: target_b.name,
          location: nil,
          last_visited: track.timestamp,
          active: [],
          queued: [
            %{
              name: track.name,
              at: target_b.name,
              start_time: track.timestamp,
              timestamp: track.timestamp
            }
          ]
        }
      ]

      actual = LiveQueue.create_queues([target_a, target_b], [track])

      assert actual == expected
    end
  end

  describe "extend_queue/2 -" do
    test "no old queue" do
      new_queue = %{
        name: "EX01",
        location: nil,
        last_visited: nil,
        active: [],
        queued: []
      }

      actual = LiveQueue.extend_queue(new_queue, [])

      assert actual == new_queue
    end

    test "merge - asset present" do
      ex = "EX01"
      dt = "DT01"
      old_timestamp = ~N[2020-01-01 00:00:00]
      new_timestamp = NaiveDateTime.add(old_timestamp, 3600)

      old_queue = %{
        name: ex,
        location: nil,
        last_visited: old_timestamp,
        active: [],
        queued: [
          %{
            name: dt,
            at: ex,
            start_time: old_timestamp,
            timestamp: old_timestamp
          }
        ]
      }

      new_queue = %{
        name: ex,
        active: [],
        location: nil,
        last_visited: new_timestamp,
        queued: [
          %{
            name: dt,
            at: ex,
            start_time: new_timestamp,
            timestamp: new_timestamp
          }
        ]
      }

      expected = %{
        name: ex,
        location: nil,
        last_visited: new_timestamp,
        active: [],
        queued: [
          %{
            name: dt,
            at: ex,
            start_time: old_timestamp,
            timestamp: new_timestamp
          }
        ]
      }

      actual = LiveQueue.extend_queue(new_queue, [old_queue])

      assert actual == expected
    end

    test "merge - missing asset" do
      ex = "EX01"
      old_timestamp = ~N[2020-01-01 00:00:00]
      new_timestamp = NaiveDateTime.add(old_timestamp, 3600)

      old_queue = %{
        name: ex,
        location: nil,
        last_visited: old_timestamp,
        active: [],
        queued: [
          %{
            name: "DT01",
            at: ex,
            start_time: old_timestamp,
            timestamp: old_timestamp
          }
        ]
      }

      new_queue = %{
        name: ex,
        location: nil,
        last_visited: new_timestamp,
        active: [],
        queued: [
          %{
            name: "DT02",
            at: ex,
            start_time: new_timestamp,
            timestamp: new_timestamp
          }
        ]
      }

      actual = LiveQueue.extend_queue(new_queue, [old_queue])

      assert actual == new_queue
    end

    test "merge - last visited held after assets leave (queued)" do
      ex = "EX01"
      old_timestamp = ~N[2020-01-01 00:00:00]

      old_queue = %{
        name: ex,
        location: nil,
        last_visited: old_timestamp,
        active: [],
        queued: [
          %{
            name: "DT01",
            at: ex,
            start_time: old_timestamp,
            timestamp: old_timestamp
          }
        ]
      }

      new_queue = %{
        name: ex,
        location: nil,
        last_visited: nil,
        active: [],
        queued: []
      }

      expected = Map.put(new_queue, :last_visited, old_timestamp)

      actual = LiveQueue.extend_queue(new_queue, [old_queue])

      assert actual == expected
    end

    test "merge - last visited held after assets leave (active)" do
      ex = "EX01"
      old_timestamp = ~N[2020-01-01 00:00:00]

      old_queue = %{
        name: ex,
        location: nil,
        last_visited: old_timestamp,
        queued: [],
        active: [
          %{
            name: "DT01",
            at: ex,
            start_time: old_timestamp,
            timestamp: old_timestamp
          }
        ]
      }

      new_queue = %{
        name: ex,
        location: nil,
        last_visited: nil,
        active: [],
        queued: []
      }

      expected = Map.put(new_queue, :last_visited, old_timestamp)

      actual = LiveQueue.extend_queue(new_queue, [old_queue])

      assert actual == expected
    end
  end
end
