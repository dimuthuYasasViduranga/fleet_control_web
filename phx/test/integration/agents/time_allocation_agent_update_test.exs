defmodule Dispatch.TimeAllocationAgentUpdateTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{
    Helper,
    CalendarAgent,
    AssetAgent,
    DispatcherAgent,
    TimeAllocationAgent,
    TimeCodeAgent
  }

  alias HpsData.Schemas.Dispatch.TimeAllocation

  setup_all _ do
    CalendarAgent.start_link([])
    todays_calendar = CalendarAgent.get_current()

    yesterdays_calendar =
      CalendarAgent.get_at(NaiveDateTime.add(todays_calendar.shift_start, -60))

    AssetAgent.start_link([])
    [asset, asset_b | _] = AssetAgent.get_assets()

    TimeCodeAgent.start_link([])
    time_codes = TimeCodeAgent.get_time_codes()
    ready = Enum.find(time_codes, &(&1.name == "Dig Ore")).id
    exception = Enum.find(time_codes, &(&1.name == "Damage")).id
    no_task = Enum.find(time_codes, &(&1.name == "No Task")).id

    [
      asset: asset,
      asset_b: asset_b,
      ready: ready,
      exception: exception,
      no_task: no_task,
      calendar: yesterdays_calendar
    ]
  end

  setup _ do
    TimeAllocationAgent.start_link([])
    DispatcherAgent.start_link([])
    {:ok, dispatcher} = DispatcherAgent.add("1234", "test")
    [dispatcher: dispatcher.id]
  end

  defp to_alloc(asset_id, time_code_id, start_time, end_time) do
    %{
      asset_id: asset_id,
      time_code_id: time_code_id,
      start_time: start_time,
      end_time: end_time
    }
  end

  describe "Update all -" do
    test "valid (create new active, no existing)", %{asset: asset, ready: ready} do
      start_time = NaiveDateTime.utc_now()

      {:ok, deleted, completed, new_active} =
        TimeAllocationAgent.update_all([
          %{
            asset_id: asset.id,
            time_code_id: ready,
            start_time: start_time,
            end_time: nil
          }
        ])

      # return
      assert deleted == []
      assert completed == []
      assert new_active.end_time == nil

      # store
      assert TimeAllocationAgent.active() == [new_active]
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, new_active)
    end

    test "valid (create new complete, no existing)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, deleted, [complete], new_active} =
        TimeAllocationAgent.update_all([
          %{
            asset_id: asset.id,
            time_code_id: ready,
            start_time: start_time,
            end_time: end_time
          }
        ])

      # return
      assert deleted == []
      assert new_active == nil
      assert NaiveDateTime.compare(complete.start_time, start_time) == :eq
      assert NaiveDateTime.compare(complete.end_time, end_time) == :eq
      assert complete.time_code_id == ready
      assert complete.asset_id == asset.id
      assert complete.deleted == false

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [complete]

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, complete)
    end

    test "valid (create new completed, unix timestamps)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, deleted, [complete], new_active} =
        TimeAllocationAgent.update_all([
          %{
            asset_id: asset.id,
            time_code_id: ready,
            start_time: Helper.to_unix(start_time),
            end_time: Helper.to_unix(end_time)
          }
        ])

      # return
      assert deleted == []
      assert new_active == nil
      assert NaiveDateTime.compare(complete.start_time, start_time) == :eq
      assert NaiveDateTime.compare(complete.end_time, end_time) == :eq

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [complete]

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, complete)
    end

    test "valid (create new active, existing active)", %{asset: asset, ready: ready} do
      start_time = NaiveDateTime.utc_now()
      initial_timestamp = NaiveDateTime.add(start_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, initial_timestamp, nil)
        |> TimeAllocationAgent.add()

      {:ok, [deleted], [completed], new_active} =
        TimeAllocationAgent.update_all([
          %{
            asset_id: asset.id,
            time_code_id: ready,
            start_time: start_time,
            end_time: nil
          }
        ])

      # return
      assert initial.deleted == false

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert NaiveDateTime.compare(new_active.start_time, start_time) == :eq
      assert new_active.end_time == nil

      assert NaiveDateTime.compare(completed.start_time, initial.start_time) == :eq
      assert NaiveDateTime.compare(completed.end_time, start_time) == :eq
      assert completed.deleted == false

      # store
      assert TimeAllocationAgent.active() == [new_active]
      assert TimeAllocationAgent.historic() == [completed]

      # database
      assert_db_count(TimeAllocation, 2, 1)
      assert_db_contains(TimeAllocation, [deleted, completed, new_active])
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (create new active before existing)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00.000000]
      new_start_time = NaiveDateTime.add(start_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, deleted, completed, new_active} =
        TimeAllocationAgent.update_all([
          %{
            asset_id: asset.id,
            time_code_id: ready,
            start_time: new_start_time,
            end_time: nil
          }
        ])

      # return
      assert initial.deleted == false
      assert deleted == []
      assert completed == []
      assert new_active == nil

      # store
      assert TimeAllocationAgent.active() == [initial]
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "valid (create new complete, before existing active)", %{asset: asset, ready: ready} do
      active_start = NaiveDateTime.utc_now()
      end_time = NaiveDateTime.add(active_start, -3600)
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, active_start, nil)
        |> TimeAllocationAgent.add()

      {:ok, deleted, [completed], new_active} =
        TimeAllocationAgent.update_all([
          %{
            asset_id: asset.id,
            time_code_id: ready,
            start_time: start_time,
            end_time: end_time
          }
        ])

      # return
      assert initial.deleted == false
      assert deleted == []
      assert new_active == nil

      assert NaiveDateTime.compare(completed.start_time, start_time) == :eq
      assert NaiveDateTime.compare(completed.end_time, end_time) == :eq
      assert completed.deleted == false

      # store
      assert TimeAllocationAgent.active() == [initial]
      assert TimeAllocationAgent.historic() == [completed]

      # database
      assert_db_count(TimeAllocation, 2, 0)
      assert_db_contains(TimeAllocation, [initial, completed])
    end

    test "valid (create new complete, during existing active)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)
      initial_timestamp = NaiveDateTime.add(start_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, initial_timestamp, nil)
        |> TimeAllocationAgent.add()

      {:ok, deleted, [completed], new_active} =
        TimeAllocationAgent.update_all([
          %{
            asset_id: asset.id,
            time_code_id: ready,
            start_time: start_time,
            end_time: end_time
          }
        ])

      # return
      assert deleted == []
      assert new_active == nil
      assert NaiveDateTime.compare(completed.start_time, start_time) == :eq
      assert NaiveDateTime.compare(completed.end_time, end_time) == :eq
      assert completed.deleted == false

      # store
      assert TimeAllocationAgent.active() == [initial]
      assert TimeAllocationAgent.historic() == [completed]

      # database
      assert_db_count(TimeAllocation, 2, 0)
      assert_db_contains(TimeAllocation, [initial, completed])
    end

    test "valid (delete active and create new one)", %{asset: asset, ready: ready} do
      now = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(now, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, [deleted], completed, new_active} =
        TimeAllocationAgent.update_all([
          Map.put(initial, :deleted, true),
          %{
            asset_id: asset.id,
            time_code_id: ready,
            start_time: start_time,
            end_time: nil
          }
        ])

      # return
      assert initial.deleted == false
      assert deleted.id == initial.id
      assert deleted.deleted == true
      assert completed == []

      assert NaiveDateTime.compare(new_active.start_time, start_time) == :eq
      assert new_active.end_time == nil
      assert new_active.id != initial.id
      assert new_active.id != deleted.id

      # store
      assert TimeAllocationAgent.active() == [new_active]
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 1)
      assert_db_contains(TimeAllocation, [deleted, new_active])
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (end active element)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, [deleted], [completed], new_active} =
        TimeAllocationAgent.update_all([
          Map.put(initial, :end_time, end_time)
        ])

      # return
      assert initial.deleted == false

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert NaiveDateTime.compare(completed.start_time, deleted.start_time) == :eq
      assert NaiveDateTime.compare(new_active.start_time, end_time) == :eq

      assert new_active.end_time == nil
      assert new_active.time_code_id == TimeCodeAgent.no_task_id()

      # store
      assert TimeAllocationAgent.active() == [new_active]
      assert TimeAllocationAgent.historic() == [completed]

      # database
      assert_db_count(TimeAllocation, 2, 1)
      assert_db_contains(TimeAllocation, [deleted, completed, new_active])
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (update active time code)", %{asset: asset, ready: ready, exception: exception} do
      now = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(now, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, [deleted], completed, new_active} =
        TimeAllocationAgent.update_all([
          Map.put(initial, :time_code_id, exception)
        ])

      # return
      assert initial.deleted == false

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert completed == []

      assert NaiveDateTime.compare(new_active.start_time, initial.start_time) == :eq
      assert new_active.end_time == nil
      assert new_active.time_code_id == exception

      # store
      assert TimeAllocationAgent.active() == [new_active]
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 1)
      assert_db_contains(TimeAllocation, [deleted, new_active])
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (update completed time code)", %{asset: asset, ready: ready, exception: exception} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [deleted], [completed], new_active} =
        TimeAllocationAgent.update_all([
          Map.put(initial, :time_code_id, exception)
        ])

      # return
      assert new_active == nil

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert NaiveDateTime.compare(completed.start_time, start_time) == :eq
      assert NaiveDateTime.compare(completed.end_time, end_time) == :eq
      assert completed.time_code_id == exception

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [completed]

      # database
      assert_db_count(TimeAllocation, 1, 1)
      assert_db_contains(TimeAllocation, [deleted, completed])
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (delete active element)", %{asset: asset, ready: ready} do
      start_time = NaiveDateTime.utc_now()

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, [deleted], completed, new_active} =
        TimeAllocationAgent.update_all([
          Map.put(initial, :deleted, true)
        ])

      # return
      assert deleted.id == initial.id
      assert deleted.deleted == true
      assert completed == []
      assert new_active.time_code_id == TimeCodeAgent.no_task_id()

      # store
      assert TimeAllocationAgent.active() == [new_active]
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 1)
      assert_db_contains(TimeAllocation, [deleted, new_active])
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (delete completed element)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [deleted], completed, new_active} =
        TimeAllocationAgent.update_all([
          Map.put(initial, :deleted, true)
        ])

      # return
      assert completed == []
      assert new_active == nil
      assert deleted.id == initial.id
      assert deleted.deleted == true

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 0, 1)
      assert_db_contains(TimeAllocation, deleted)
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (insert no changes)" do
      {:ok, deleted, completed, new_active} = TimeAllocationAgent.update_all([])

      # return
      assert deleted == []
      assert completed == []
      assert new_active == nil

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 0, 0)
    end

    test "valid (insert no effective changes [insert new deleted])", %{asset: asset, ready: ready} do
      {:ok, deleted, completed, new_active} =
        TimeAllocationAgent.update_all([
          %{
            asset_id: asset.id,
            time_code_id: ready,
            start_time: ~N[2020-01-01 00:00:00],
            end_time: nil,
            deleted: true
          }
        ])

      # return
      assert deleted == []
      assert completed == []
      assert new_active == nil

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 0, 0)
    end

    test "valid (nil time codes converted to no task)", %{asset: asset, no_task: no_task} do
      {:ok, deleted, completed, new_active} =
        TimeAllocationAgent.update_all([
          %{
            asset_id: asset.id,
            time_code_id: nil,
            start_time: NaiveDateTime.utc_now(),
            end_time: nil,
            deleted: false
          }
        ])

      # return
      assert deleted == []
      assert completed == []
      assert new_active.time_code_id == no_task

      # store
      assert TimeAllocationAgent.active() == [new_active]
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_contains(TimeAllocation, new_active)
      assert_db_count(TimeAllocation, 1, 0)
    end

    test "invalid (insert completed with end before start)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, -3600)

      actual =
        TimeAllocationAgent.update_all([
          %{
            asset_id: asset,
            time_code_id: ready,
            start_time: start_time,
            end_time: end_time
          }
        ])

      assert actual == {:error, :invalid}
    end

    test "invalid (end active in the past)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00.000000]
      end_time = NaiveDateTime.add(start_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      error =
        TimeAllocationAgent.update_all([
          Map.put(initial, :end_time, end_time)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert TimeAllocationAgent.active() == [initial]
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (create multiple actives)", %{asset: asset, ready: ready} do
      actual =
        TimeAllocationAgent.update_all([
          %{
            asset_id: asset.id,
            time_code_id: ready,
            start_time: ~N[2020-01-01 00:00:00],
            end_time: nil,
            deleted: false
          },
          %{
            asset_id: asset.id,
            time_code_id: ready,
            start_time: ~N[2020-01-02 00:00:00],
            end_time: nil,
            deleted: false
          }
        ])

      assert actual == {:error, :multiple_actives}
    end

    test "invalid (update multiple assets)", %{asset: asset_a, asset_b: asset_b, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, 3600)

      actual =
        TimeAllocationAgent.update_all([
          %{
            asset_id: asset_a.id,
            time_code_id: ready,
            start_time: start_time,
            end_time: end_time,
            deleted: false
          },
          %{
            asset_id: asset_b.id,
            time_code_id: ready,
            start_time: start_time,
            end_time: nil,
            deleted: false
          }
        ])

      assert actual == {:error, :multiple_assets}
    end

    test "invalid (remove active start)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      error =
        TimeAllocationAgent.update_all([
          Map.put(initial, :start_time, nil)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert TimeAllocationAgent.active() == [initial]
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (remove completed start)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      error =
        TimeAllocationAgent.update_all([
          Map.put(initial, :start_time, nil)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [initial]

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (remove completed end)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      error =
        TimeAllocationAgent.update_all([
          Map.put(initial, :end_time, nil)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [initial]

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (end active element in future)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      future = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      error =
        TimeAllocationAgent.update_all([
          Map.put(initial, :end_time, future)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert TimeAllocationAgent.active() == [initial]
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (move active start into future)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      future = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      error =
        TimeAllocationAgent.update_all([
          Map.put(initial, :start_time, future)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert TimeAllocationAgent.active() == [initial]
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (move completed into future)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, 3600)
      future_start = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600)
      future_end = NaiveDateTime.add(future_start, 3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      error =
        TimeAllocationAgent.update_all([
          initial
          |> Map.put(:start_time, future_start)
          |> Map.put(:end_time, future_end)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert TimeAllocationAgent.active() == []
      # completed is very old
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (change asset on active)", %{asset: asset_a, asset_b: asset_b, ready: ready} do
      start_time = NaiveDateTime.utc_now()

      {:ok, initial} =
        to_alloc(asset_a.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      actual =
        TimeAllocationAgent.update_all([
          Map.put(initial, :asset_id, asset_b.id)
        ])

      # return
      assert actual == {:error, :multiple_assets}

      # store
      assert TimeAllocationAgent.active() == [initial]
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (change asset on completed)", %{asset: asset_a, asset_b: asset_b, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, initial} =
        to_alloc(asset_a.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      actual =
        TimeAllocationAgent.update_all([
          Map.put(initial, :asset_id, asset_b.id)
        ])

      # return
      assert actual == {:error, :multiple_assets}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [initial]

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (update staled (race condition) element)", %{
      asset: asset,
      ready: ready,
      exception: exception
    } do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [deleted], [completed], new_active} =
        TimeAllocationAgent.update_all([
          Map.put(initial, :time_code_id, exception)
        ])

      error =
        TimeAllocationAgent.update_all([
          Map.put(initial, :time_code_id, exception)
        ])

      # return
      assert error == {:error, :stale}

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert new_active == nil

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [completed]

      # database
      assert_db_count(TimeAllocation, 1, 1)
      assert_db_contains(TimeAllocation, completed)
      refute_db_contains(TimeAllocation, initial)
    end

    test "invalid (update deleted element)", %{asset: asset, ready: ready, exception: exception} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [deleted], completed, new_active} =
        TimeAllocationAgent.update_all([Map.put(initial, :deleted, true)])

      error =
        TimeAllocationAgent.update_all([
          Map.put(deleted, :time_code_id, exception)
        ])

      # return
      assert completed == []
      assert new_active == nil

      assert error == {:error, :stale}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_count(TimeAllocation, 0, 1)
      assert_db_contains(TimeAllocation, deleted)
      refute_db_contains(TimeAllocation, initial)
    end

    test "invalid (id doesnt exist)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, 3600)

      actual =
        TimeAllocationAgent.update_all([
          %{
            id: -1,
            asset_id: asset.id,
            time_code_id: ready,
            start_time: start_time,
            end_time: end_time
          }
        ])

      assert actual == {:error, :ids_not_found}
    end

    test "invalid (one id doesnt exist)", %{asset: asset, ready: ready, exception: exception} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      actual =
        TimeAllocationAgent.update_all([
          # valid change
          Map.put(initial, :time_code_id, exception),
          # invalid id
          %{
            id: -1,
            asset_id: asset.id,
            time_code_id: ready,
            start_time: start_time,
            end_time: end_time
          }
        ])

      # return
      assert actual == {:error, :ids_not_found}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [initial]

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (one element is locked)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: r_start, shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [locked], [], [deleted], lock} =
        TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      error = TimeAllocationAgent.update_all([Map.put(locked, :start_time, r_start)])

      # return
      assert error == {:error, :cannot_change_locked}

      assert locked.id != initial.id
      assert locked.lock_id == lock.id
      assert deleted.id == initial.id
      assert deleted.deleted == true

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [locked]

      # database
      assert_db_contains(TimeAllocation, [locked, deleted])
      refute_db_contains(TimeAllocation, initial)
    end

    test "invalid (update element to locked)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.add(NaiveDateTime.utc_now(), -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      error = TimeAllocationAgent.update_all([Map.put(initial, :lock_id, 1)])

      # return
      assert error == {:error, :cannot_set_locked}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [initial]

      # database
      assert_db_contains(TimeAllocation, initial)
    end
  end
end
