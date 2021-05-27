defmodule Dispatch.TimeAllocation.LockTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{
    CalendarAgent,
    AssetAgent,
    TimeCodeAgent,
    TimeAllocationAgent,
    DispatcherAgent
  }

  alias Dispatch.TimeAllocationAgent.Lock
  alias HpsData.Schemas.Dispatch.{TimeAllocation, TimeAllocationLock}

  setup_all _ do
    CalendarAgent.start_link([])
    todays_calendar = CalendarAgent.get_current()

    future_calendar = CalendarAgent.get_at(NaiveDateTime.add(NaiveDateTime.utc_now(), 24 * 3600))

    yesterdays_calendar =
      CalendarAgent.get_at(NaiveDateTime.add(todays_calendar.shift_start, -60))

    AssetAgent.start_link([])
    [asset, asset_b | _] = AssetAgent.get_assets()

    TimeCodeAgent.start_link([])
    time_codes = TimeCodeAgent.get_time_codes()
    ready = Enum.find(time_codes, &(&1.name == "Dig Ore")).id
    exception = Enum.find(time_codes, &(&1.name == "Damage")).id

    [
      asset: asset,
      asset_b: asset_b,
      ready: ready,
      exception: exception,
      calendar: yesterdays_calendar,
      calendar_today: todays_calendar,
      calendar_future: future_calendar
    ]
  end

  setup _ do
    DispatcherAgent.start_link([])
    TimeAllocationAgent.start_link([])

    {:ok, dispatcher} = DispatcherAgent.add("1234", "test")
    [dispatcher: dispatcher.id]
  end

  defp to_span(start_time, end_time) do
    %{start_time: start_time, end_time: end_time}
  end

  defp to_span(id, start_time, end_time) do
    %{id: id, start_time: start_time, end_time: end_time}
  end

  defp to_alloc(asset_id, time_code_id, start_time, end_time) do
    :timer.sleep(2)

    %{
      asset_id: asset_id,
      time_code_id: time_code_id,
      start_time: start_time,
      end_time: end_time
    }
  end

  describe "split_allocation/2 -" do
    test "valid (no split required)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(NaiveDateTime.add(r_start, 60), NaiveDateTime.add(r_end, -60))

      {:unchanged, actual} = Lock.split_allocation(initial, range)

      assert actual == initial
    end

    test "valid (no split required, exactly covering)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(r_start, r_end)

      {:unchanged, actual} = Lock.split_allocation(initial, range)

      assert actual == initial
    end

    test "valid (no split required, start on range start)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(r_start, NaiveDateTime.add(r_end, -60))

      {:unchanged, actual} = Lock.split_allocation(initial, range)

      assert actual == initial
    end

    test "valid (no split required, end on range end)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(NaiveDateTime.add(r_start, 60), r_end)

      {:unchanged, actual} = Lock.split_allocation(initial, range)

      assert actual == initial
    end

    test "valid (split start time before range)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(NaiveDateTime.add(r_start, -60), NaiveDateTime.add(r_end, -60))

      {:split, right, [left]} = Lock.split_allocation(initial, range)

      assert left.start_time == initial.start_time
      assert left.end_time == r_start

      assert right.start_time == r_start
      assert right.end_time == initial.end_time
    end

    test "valid (split end time after range)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(NaiveDateTime.add(r_start, 60), NaiveDateTime.add(r_end, 60))

      {:split, left, [right]} = Lock.split_allocation(initial, range)

      assert left.start_time == initial.start_time
      assert left.end_time == r_end

      assert right.start_time == r_end
      assert right.end_time == initial.end_time
    end

    test "valid (split element completely covering)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(NaiveDateTime.add(r_start, -60), NaiveDateTime.add(r_end, 60))

      {:split, middle, [left, right]} = Lock.split_allocation(initial, range)

      assert left.start_time == initial.start_time
      assert left.end_time == r_start

      assert middle.start_time == r_start
      assert middle.end_time == r_end

      assert right.start_time == r_end
      assert right.end_time == initial.end_time
    end
  end

  describe "split_allocations/2 -" do
    test "valid (no split required)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(1, NaiveDateTime.add(r_start, 60), NaiveDateTime.add(r_end, -60))

      {outside_range, inside_range} = Lock.split_allocations([initial], range)

      assert outside_range == []
      assert inside_range == [initial]
    end

    test "valid (no split required, exactly covering)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(1, r_start, r_end)

      {outside_range, inside_range} = Lock.split_allocations([initial], range)

      assert outside_range == []
      assert inside_range == [initial]
    end

    test "valid (start on range start, no split)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(1, r_start, NaiveDateTime.add(r_end, -60))

      {outside_range, inside_range} = Lock.split_allocations([initial], range)

      assert outside_range == []
      assert inside_range == [initial]
    end

    test "valid (end on range end, no split)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(1, NaiveDateTime.add(r_start, 60), r_end)

      {outside_range, inside_range} = Lock.split_allocations([initial], range)

      assert outside_range == []
      assert inside_range == [initial]
    end

    test "valid (start time outside, end time inside)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(1, NaiveDateTime.add(r_start, -60), NaiveDateTime.add(r_end, -60))

      {[new_left], [new_right]} = Lock.split_allocations([initial], range)

      assert new_left.id == initial.id
      assert new_left.start_time == initial.start_time
      assert new_left.end_time == r_start

      assert new_right.id == initial.id
      assert new_right.start_time == r_start
      assert new_right.end_time == initial.end_time
    end

    test "valid (start time inside, end time outside)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(1, NaiveDateTime.add(r_start, 60), NaiveDateTime.add(r_end, 60))

      {[new_right], [new_left]} = Lock.split_allocations([initial], range)

      assert new_left.id == initial.id
      assert new_left.start_time == initial.start_time
      assert new_left.end_time == r_end

      assert new_right.id == initial.id
      assert new_right.start_time == r_end
      assert new_right.end_time == initial.end_time
    end

    test "valid (split element completely covering)" do
      r_start = ~N[2020-01-02 00:00:00]
      r_end = ~N[2020-01-03 00:00:00]
      range = to_span(r_start, r_end)
      initial = to_span(1, NaiveDateTime.add(r_start, -60), NaiveDateTime.add(r_end, 60))

      {[new_left, new_right], [new_middle]} = Lock.split_allocations([initial], range)

      assert new_left.id == initial.id
      assert new_left.start_time == initial.start_time
      assert new_left.end_time == r_start

      assert new_middle.id == initial.id
      assert new_middle.start_time == r_start
      assert new_middle.end_time == r_end

      assert new_right.id == initial.id
      assert new_right.start_time == r_end
      assert new_right.end_time == initial.end_time
    end
  end

  describe "lock/3 -" do
    test "valid (lock single element)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      # {:ok, [locked], new, [deleted], lock} =
      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)
      lock = data.lock
      [locked] = data.new

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial.id]
      assert data.ignored_ids == []

      assert locked.id != initial.id
      assert NaiveDateTime.compare(locked.start_time, initial.start_time)
      assert NaiveDateTime.compare(locked.end_time, initial.end_time)
      assert locked.lock_id == lock.id
      assert locked.time_code_id == initial.time_code_id

      # Store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [locked]

      # Database
      assert_db_contains(TimeAllocation, locked)
      assert_db_count(TimeAllocation, 1, 1, :deleted)
    end

    test "valid (no split on start boundary)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: r_start, shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, -60)
      start_time = r_start

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [locked], new, [deleted], lock} =
        TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      # return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert new == []

      assert locked.id != initial.id
      assert NaiveDateTime.compare(locked.start_time, initial.start_time)
      assert NaiveDateTime.compare(locked.end_time, initial.end_time)
      assert locked.time_code_id == initial.time_code_id

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [locked]

      # database
      assert_db_contains(TimeAllocation, [locked, deleted])
      assert_db_contains(TimeAllocationLock, lock)
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (no split end boundary)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: r_end} = context.calendar

      end_time = r_end
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [locked], new, [deleted], lock} =
        TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      # return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert new == []

      assert locked.id != initial.id
      assert NaiveDateTime.compare(locked.start_time, initial.start_time)
      assert NaiveDateTime.compare(locked.end_time, initial.end_time)
      assert locked.time_code_id == initial.time_code_id

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [locked]

      # database
      assert_db_contains(TimeAllocation, [locked, deleted])
      assert_db_contains(TimeAllocationLock, lock)
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (split, start outside, end inside)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: r_start, shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, -60)
      start_time = NaiveDateTime.add(r_start, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [locked], [new_left], [deleted], lock} =
        TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      # return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert new_left.start_time == initial.start_time
      assert new_left.end_time == r_start
      assert new_left.lock_id == nil

      assert locked.id != initial.id
      assert NaiveDateTime.compare(locked.start_time, initial.start_time)
      assert NaiveDateTime.compare(locked.end_time, initial.end_time)
      assert locked.time_code_id == initial.time_code_id

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [locked, new_left]

      # database
      assert_db_contains(TimeAllocation, [new_left, locked, deleted])
      assert_db_contains(TimeAllocationLock, lock)
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (split, start inside, end outside)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: r_start, shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, 60)
      start_time = NaiveDateTime.add(r_start, 60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [locked], [new_right], [deleted], lock} =
        TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      # return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert new_right.start_time == r_end
      assert new_right.end_time == initial.end_time
      assert new_right.lock_id == nil

      assert locked.id != initial.id
      assert NaiveDateTime.compare(locked.start_time, initial.start_time)
      assert NaiveDateTime.compare(locked.end_time, initial.end_time)
      assert locked.time_code_id == initial.time_code_id

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [new_right, locked]

      # database
      assert_db_contains(TimeAllocation, [locked, new_right, deleted])
      assert_db_contains(TimeAllocationLock, lock)
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (split element over entire boundary)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: r_start, shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, 60)
      start_time = NaiveDateTime.add(r_start, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [locked], [new_left, new_right], [deleted], lock} =
        TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      # return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert new_left.start_time == initial.start_time
      assert new_left.end_time == r_start
      assert new_left.lock_id == nil

      assert new_right.start_time == r_end
      assert new_right.end_time == initial.end_time
      assert new_right.lock_id == nil

      assert locked.id != initial.id
      assert NaiveDateTime.compare(locked.start_time, initial.start_time)
      assert NaiveDateTime.compare(locked.end_time, initial.end_time)
      assert locked.time_code_id == initial.time_code_id

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [new_right, locked, new_left]

      # database
      assert_db_contains(TimeAllocation, [new_left, locked, new_right, deleted])
      assert_db_contains(TimeAllocationLock, lock)
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (lock multiple elements)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: r_end} = context.calendar

      time_c = NaiveDateTime.add(r_end, -60)
      time_b = NaiveDateTime.add(time_c, -60)
      time_a = NaiveDateTime.add(time_b, -60)

      {:ok, alloc_a} =
        to_alloc(asset.id, ready, time_a, time_b)
        |> TimeAllocationAgent.add()

      {:ok, alloc_b} =
        to_alloc(asset.id, ready, time_b, time_c)
        |> TimeAllocationAgent.add()

      {:ok, [locked_b, locked_a], new, [deleted_a, deleted_b], lock} =
        TimeAllocationAgent.lock([alloc_a.id, alloc_b.id], cal_id, context.dispatcher)

      # return
      assert new == []

      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert deleted_a.id == alloc_a.id
      assert deleted_a.deleted == true
      assert deleted_b.id == alloc_b.id
      assert deleted_b.deleted == true

      assert locked_a.id != alloc_a.id
      assert NaiveDateTime.compare(locked_a.start_time, alloc_a.start_time)
      assert NaiveDateTime.compare(locked_a.end_time, alloc_b.end_time)

      assert locked_b.id != alloc_b.id
      assert NaiveDateTime.compare(locked_b.start_time, alloc_b.start_time)
      assert NaiveDateTime.compare(locked_b.end_time, alloc_b.end_time)

      assert locked_a.lock_id == lock.id
      assert locked_b.lock_id == lock.id

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [locked_b, locked_a]

      # database
      assert_db_contains(TimeAllocation, [locked_a, locked_b])
      assert_db_contains(TimeAllocation, [deleted_a, deleted_b])
      assert_db_contains(TimeAllocationLock, lock)
      refute_db_contains(TimeAllocation, [alloc_a, alloc_b])
    end

    test "valid (no elements)" do
      {:ok, locked, new, deleted, lock} = TimeAllocationAgent.lock([], nil, nil)

      assert locked == []
      assert new == []
      assert deleted == []
      assert lock == nil
    end

    test "invalid (no dispatcher id)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      error = TimeAllocationAgent.lock([initial.id], cal_id, nil)

      # return
      assert error == {:error, :invalid_dispatcher}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [initial]

      # database
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (invalid dispatcher id)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      error = TimeAllocationAgent.lock([initial.id], cal_id, -1)

      # return
      assert error == {:error, :invalid_dispatcher}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [initial]

      # database
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (no calendar id)", %{asset: asset, ready: ready} = context do
      %{shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      error = TimeAllocationAgent.lock([initial.id], nil, context.dispatcher)

      # return
      assert error == {:error, :invalid_calendar}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [initial]

      # database
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (invalid calendar id)", %{asset: asset, ready: ready} = context do
      %{shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      error = TimeAllocationAgent.lock([initial.id], -1, context.dispatcher)

      # return
      assert error == {:error, :invalid_calendar}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [initial]

      # database
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (any id does not fall within calendar)",
         %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: r_start} = context.calendar

      end_time = NaiveDateTime.add(r_start, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      error = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      # return
      assert error == {:error, :outside_calendar}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [initial]

      # database
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (any id does not exist)", %{calendar: cal, dispatcher: dispatcher} do
      error = TimeAllocationAgent.lock([-1, nil], cal.id, dispatcher)
      assert error == {:error, :invalid_ids}
    end

    test "invalid (any element already locked)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [locked], [], [deleted], lock} =
        TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      error = TimeAllocationAgent.lock([locked.id], cal_id, context.dispatcher)

      # return
      assert locked.id != initial.id
      assert locked.lock_id == lock.id

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert error == {:error, :deleted_locked_or_active}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [locked]

      # database
      assert_db_contains(TimeAllocation, [locked, deleted])
      assert_db_contains(TimeAllocationLock, lock)
      refute_db_contains(TimeAllocation, initial)
    end

    test "invalid (any element already deleted)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [deleted], completed, active} =
        TimeAllocationAgent.update_all([Map.put(initial, :deleted, true)])

      error = TimeAllocationAgent.lock([deleted.id], cal_id, context.dispatcher)

      # return
      assert completed == []
      assert active == nil

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert error == {:error, :deleted_locked_or_active}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_contains(TimeAllocation, deleted)
      refute_db_contains(TimeAllocation, initial)
    end
  end

  describe "lock/2 active elements - " do
    test "valid (active start within calendar, end within calendar)",
         %{asset: asset, ready: ready} = context do
      now = NaiveDateTime.utc_now()
      %{id: cal_id, shift_start: r_start} = context.calendar_today

      start_time = NaiveDateTime.add(r_start, 1)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, [locked], [new_active], [deleted], lock} =
        TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      # return
      assert locked.id != initial.id
      assert locked.lock_id == lock.id
      assert NaiveDateTime.compare(locked.start_time, initial.start_time) == :eq
      assert NaiveDateTime.compare(locked.end_time, now) != :lt

      assert new_active.id != initial.id
      assert NaiveDateTime.compare(new_active.start_time, locked.end_time) == :eq
      assert new_active.end_time == nil

      assert deleted.deleted == true

      # store
      assert TimeAllocationAgent.active() == [new_active]
      assert TimeAllocationAgent.historic() == [locked]

      # database
      assert_db_contains(TimeAllocation, [locked, new_active, deleted])
      refute_db_contains(TimeAllocation, initial)
      assert_db_contains(TimeAllocationLock, lock)
    end

    test "valid (active starts outside calendar, end within calendar)",
         %{asset: asset, ready: ready} = context do
      now = NaiveDateTime.utc_now()

      %{id: cal_id, shift_start: r_start, shift_end: r_end} = context.calendar_today

      # make sure that now is within todays calendar
      assert NaiveDateTime.compare(now, r_start) != :lt
      assert NaiveDateTime.compare(now, r_end) == :lt

      start_time = NaiveDateTime.add(r_start, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, [locked], [left_alloc, new_active], [deleted], lock} =
        TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      # return
      assert locked.id != initial.id
      assert locked.lock_id == lock.id
      assert NaiveDateTime.compare(locked.start_time, r_start) == :eq
      assert NaiveDateTime.compare(locked.end_time, now) != :lt

      assert new_active.id != initial.id
      assert NaiveDateTime.compare(new_active.start_time, locked.end_time) == :eq
      assert new_active.end_time == nil

      assert left_alloc.id != initial.id
      assert NaiveDateTime.compare(left_alloc.start_time, initial.start_time)
      assert NaiveDateTime.compare(left_alloc.end_time, r_start)

      assert deleted.deleted == true

      # store
      assert TimeAllocationAgent.active() == [new_active]
      assert TimeAllocationAgent.historic() == [locked, left_alloc]

      # database
      assert_db_contains(TimeAllocation, [locked, new_active, deleted])
      refute_db_contains(TimeAllocation, initial)
      assert_db_contains(TimeAllocationLock, lock)
    end

    test "valid (active starts inside calendar, end outside calendar)",
         %{asset: asset, ready: ready} = context do
      now = NaiveDateTime.utc_now()

      %{id: cal_id, shift_end: r_end} = context.calendar

      start_time = NaiveDateTime.add(r_end, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, [locked], [right_alloc, new_active], [deleted], lock} =
        TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      # return
      assert locked.id != initial.id
      assert locked.lock_id == lock.id
      assert NaiveDateTime.compare(locked.start_time, initial.start_time) == :eq
      assert NaiveDateTime.compare(locked.end_time, r_end) == :eq

      assert right_alloc.id != initial.id
      assert NaiveDateTime.compare(right_alloc.start_time, r_end)
      assert NaiveDateTime.compare(right_alloc.end_time, now) != :lt

      assert new_active.id != initial.id
      assert NaiveDateTime.compare(new_active.start_time, right_alloc.end_time) == :eq
      assert new_active.end_time == nil

      assert deleted.deleted == true

      # store
      assert TimeAllocationAgent.active() == [new_active]
      assert TimeAllocationAgent.historic() == [right_alloc, locked]

      # database
      assert_db_contains(TimeAllocation, [locked, new_active, right_alloc, deleted])
      refute_db_contains(TimeAllocation, initial)
      assert_db_contains(TimeAllocationLock, lock)
    end

    test "valid (active starts before calendar, end after calendar)",
         %{asset: asset, ready: ready} = context do
      now = NaiveDateTime.utc_now()

      %{id: cal_id, shift_start: r_start, shift_end: r_end} = context.calendar

      start_time = NaiveDateTime.add(r_start, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, [locked], [left_alloc, right_alloc, new_active], [deleted], lock} =
        TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      # return
      assert locked.id != initial.id
      assert locked.lock_id == lock.id
      assert NaiveDateTime.compare(locked.start_time, r_start) == :eq
      assert NaiveDateTime.compare(locked.end_time, r_end) == :eq

      assert left_alloc.id != initial.id
      assert NaiveDateTime.compare(left_alloc.start_time, initial.start_time) == :eq
      assert NaiveDateTime.compare(left_alloc.end_time, r_start) == :eq

      assert right_alloc.id != initial.id
      assert NaiveDateTime.compare(right_alloc.start_time, r_end)
      assert NaiveDateTime.compare(right_alloc.end_time, now) != :lt

      assert new_active.id != initial.id
      assert NaiveDateTime.compare(new_active.start_time, right_alloc.end_time) == :eq
      assert new_active.end_time == nil

      assert deleted.deleted == true

      # store
      assert TimeAllocationAgent.active() == [new_active]
      assert TimeAllocationAgent.historic() == [right_alloc, locked, left_alloc]

      # database
      assert_db_contains(TimeAllocation, [locked, new_active, left_alloc, right_alloc, deleted])
      refute_db_contains(TimeAllocation, initial)
      assert_db_contains(TimeAllocationLock, lock)
    end

    test "invalid (active after calendar to lock on)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: r_end} = context.calendar

      start_time = NaiveDateTime.add(r_end, 60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      error = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      assert error == {:error, :outside_calendar}
    end

    test "invalid (active end before future calendar)", %{asset: asset, ready: ready} = context do
      start_time = NaiveDateTime.utc_now()

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      error =
        TimeAllocationAgent.lock([initial.id], context.calendar_future.id, context.dispatcher)

      assert error == {:error, :outside_calendar}
    end
  end

  describe "unlock/1 -" do
    test "valid (all locked)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [locked], [], [deleted], lock} =
        TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      {:ok, [unlocked], [deleted_locked]} = TimeAllocationAgent.unlock([locked.id])

      # return
      assert locked.id != initial.id
      assert locked.lock_id == lock.id

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert unlocked.id != locked.id
      assert unlocked.lock_id == nil

      assert deleted_locked.id == locked.id
      assert deleted_locked.deleted == true

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [unlocked]

      # database
      assert_db_contains(TimeAllocation, [unlocked, deleted_locked])
      assert_db_contains(TimeAllocationLock, lock)
      refute_db_contains(TimeAllocation, [initial, locked, deleted])
    end

    test "valid (no ids)" do
      {:ok, unlocked, deleted} = TimeAllocationAgent.unlock([])
      assert unlocked == []
      assert deleted == []
    end

    test "invalid (some ids dont exist)" do
      error = TimeAllocationAgent.unlock([-1, nil])
      assert error == {:error, :invalid_ids}
    end

    test "invalid (some ids not locked)", %{asset: asset, ready: ready} = context do
      %{shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      error = TimeAllocationAgent.unlock([initial.id])

      # return
      assert error == {:error, :not_unlockable}

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [initial]

      # database
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (some ids deleted)", %{asset: asset, ready: ready} = context do
      %{shift_end: r_end} = context.calendar

      end_time = NaiveDateTime.add(r_end, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, [deleted], completed, active} =
        TimeAllocationAgent.update_all([Map.put(initial, :deleted, true)])

      error = TimeAllocationAgent.unlock([deleted.id])

      # return
      assert error == {:error, :not_unlockable}

      assert completed == []
      assert active == nil

      assert deleted.id == initial.id
      assert deleted.deleted == true

      # store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == []

      # database
      assert_db_contains(TimeAllocation, deleted)
      refute_db_contains(TimeAllocation, initial)
    end
  end
end
