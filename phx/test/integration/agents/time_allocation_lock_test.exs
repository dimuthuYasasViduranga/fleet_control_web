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

  def assert_naive_equal(nil, nil), do: true

  def assert_naive_equal(actual, expected) do
    cond do
      actual !== nil && expected !== nil && NaiveDateTime.compare(actual, expected) == :eq ->
        true

      true ->
        raise ExUnit.AssertionError,
          message: "Naive timestamps are not equal",
          left: actual,
          right: expected
    end
  end

  def assert_naive_equal(a, b), do: assert(NaiveDateTime.compare(a, b) == :eq)

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

  describe "lock/3 complete elements -" do
    test "valid (no split: completely within)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: shift_end} = context.calendar

      end_time = NaiveDateTime.add(shift_end, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)
      lock = data.lock
      [locked] = data.new

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial.id]
      assert data.ignored_ids == []

      assert locked.id != initial.id
      assert_naive_equal(locked.start_time, initial.start_time)
      assert_naive_equal(locked.end_time, initial.end_time)
      assert locked.lock_id == lock.id
      assert locked.time_code_id == initial.time_code_id

      # Store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [locked]

      # Database
      assert_db_contains(TimeAllocation, locked)
      assert_db_count(TimeAllocation, 1, 1, :deleted)
    end

    test "valid (no split: start on boundary, end inside)",
         %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: shift_start} = context.calendar

      start_time = shift_start
      end_time = NaiveDateTime.add(start_time, 60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)
      lock = data.lock
      [locked] = data.new

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial.id]
      assert data.ignored_ids == []

      assert locked.id != initial.id
      assert_naive_equal(locked.start_time, initial.start_time)
      assert_naive_equal(locked.end_time, initial.end_time)
      assert locked.lock_id == lock.id
      assert locked.time_code_id == initial.time_code_id

      # Store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [locked]

      # Database
      assert_db_contains(TimeAllocation, locked)
      assert_db_count(TimeAllocation, 1, 1, :deleted)
    end

    test "valid (no split: start inside, end on boundary)",
         %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: shift_end} = context.calendar

      end_time = shift_end
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)
      lock = data.lock
      [locked] = data.new

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial.id]
      assert data.ignored_ids == []

      assert locked.id != initial.id
      assert_naive_equal(locked.start_time, initial.start_time)
      assert_naive_equal(locked.end_time, initial.end_time)
      assert locked.lock_id == lock.id
      assert locked.time_code_id == initial.time_code_id

      # Store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [locked]

      # Database
      assert_db_contains(TimeAllocation, locked)
      assert_db_count(TimeAllocation, 1, 1, :deleted)
    end

    test "valid (split: start outside, end inside)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: shift_start} = context.calendar

      start_time = NaiveDateTime.add(shift_start, -60)
      end_time = NaiveDateTime.add(shift_start, 60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)
      lock = data.lock
      [locked, split] = data.new

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial.id]
      assert data.ignored_ids == []

      assert locked.id != initial.id
      assert_naive_equal(locked.start_time, shift_start)
      assert_naive_equal(locked.end_time, initial.end_time)
      assert locked.lock_id == lock.id
      assert locked.time_code_id == initial.time_code_id

      assert split.id != initial.id
      assert_naive_equal(split.start_time, initial.start_time)
      assert_naive_equal(split.end_time, shift_start)
      assert split.lock_id == nil
      assert split.time_code_id == initial.time_code_id

      # Store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [locked, split]

      # Database
      assert_db_contains(TimeAllocation, [locked, split])
      assert_db_count(TimeAllocation, 2, 1, :deleted)
    end

    test "valid (split: start inside, end outside)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: shift_end} = context.calendar

      start_time = NaiveDateTime.add(shift_end, -60)
      end_time = NaiveDateTime.add(shift_end, 60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)
      lock = data.lock
      [locked, split] = Enum.sort_by(data.new, & &1.start_time, {:asc, NaiveDateTime})

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial.id]
      assert data.ignored_ids == []

      assert locked.id != initial.id
      assert_naive_equal(locked.start_time, initial.start_time)
      assert_naive_equal(locked.end_time, shift_end)
      assert locked.lock_id == lock.id
      assert locked.time_code_id == initial.time_code_id

      assert split.id != initial.id
      assert_naive_equal(split.start_time, shift_end)
      assert_naive_equal(split.end_time, initial.end_time)
      assert split.lock_id == nil
      assert split.time_code_id == initial.time_code_id

      # Store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [split, locked]

      # Database
      assert_db_contains(TimeAllocation, [locked, split])
      assert_db_count(TimeAllocation, 2, 1, :deleted)
    end

    test "valid (split: completely covers)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: shift_start, shift_end: shift_end} = context.calendar

      start_time = NaiveDateTime.add(shift_start, -60)
      end_time = NaiveDateTime.add(shift_end, 60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)
      lock = data.lock

      [split_before, locked, split_after] =
        Enum.sort_by(data.new, & &1.start_time, {:asc, NaiveDateTime})

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial.id]
      assert data.ignored_ids == []

      assert split_before.id != initial.id
      assert_naive_equal(split_before.start_time, initial.start_time)
      assert_naive_equal(split_before.end_time, shift_start)
      assert split_before.lock_id == nil
      assert split_before.time_code_id == initial.time_code_id

      assert locked.id != initial.id
      assert_naive_equal(locked.start_time, shift_start)
      assert_naive_equal(locked.end_time, shift_end)
      assert locked.lock_id == lock.id
      assert locked.time_code_id == initial.time_code_id

      assert split_after.id != initial.id
      assert_naive_equal(split_after.start_time, shift_end)
      assert_naive_equal(split_after.end_time, initial.end_time)
      assert split_after.lock_id == nil
      assert split_after.time_code_id == initial.time_code_id

      # Store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [split_after, locked, split_before]

      # Database
      assert_db_contains(TimeAllocation, [split_before, locked, split_after])
      assert_db_count(TimeAllocation, 3, 1, :deleted)
    end

    test "valid (element completely outside shift)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: shift_end} = context.calendar

      start_time = NaiveDateTime.add(shift_end, 60)
      end_time = NaiveDateTime.add(start_time, 60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> TimeAllocationAgent.add()

      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      # Return
      assert data.lock == nil
      assert data.deleted_ids == []
      assert data.ignored_ids == [initial.id]
      assert data.new == []

      # Store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [initial]

      # Database
      assert_db_contains(TimeAllocation, [initial])
      assert_db_count(TimeAllocation, 1, 0, :deleted)
    end

    test "valid (no elements)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: shift_end} = context.calendar

      {:ok, data} = TimeAllocationAgent.lock([], cal_id, context.dispatcher)

      # Return
      assert data.lock == nil
      assert data.deleted_ids == []
      assert data.ignored_ids == []
      assert data.new == []

      # Store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == []

      # Database
      assert_db_count(TimeAllocation, 0)
    end

    test "valid (multiple assets)", %{asset: asset_a, asset_b: asset_b, ready: ready} = context do
      %{id: cal_id, shift_start: shift_start} = context.calendar_today

      a_start = NaiveDateTime.add(shift_start, 60)
      a_end = NaiveDateTime.add(a_start, 60)
      b_start = NaiveDateTime.add(a_end, 60)
      b_end = NaiveDateTime.add(b_start, 60)

      {:ok, initial_a} =
        to_alloc(asset_a.id, ready, a_start, a_end)
        |> TimeAllocationAgent.add()

      {:ok, initial_b} =
        to_alloc(asset_b.id, ready, b_start, b_end)
        |> TimeAllocationAgent.add()

      {:ok, data} =
        TimeAllocationAgent.lock([initial_a.id, initial_b.id], cal_id, context.dispatcher)

      lock = data.lock
      [locked_a, locked_b] = Enum.sort_by(data.new, & &1.start_time, {:asc, NaiveDateTime})

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial_b.id, initial_a.id]
      assert data.ignored_ids == []

      assert locked_a.id != initial_a.id
      assert_naive_equal(locked_a.start_time, initial_a.start_time)
      assert_naive_equal(locked_a.end_time, initial_a.end_time)
      assert locked_a.lock_id == lock.id
      assert locked_a.time_code_id == initial_a.time_code_id

      assert locked_b.id != initial_b.id
      assert_naive_equal(locked_b.start_time, initial_b.start_time)
      assert_naive_equal(locked_b.end_time, initial_b.end_time)
      assert locked_b.lock_id == lock.id
      assert locked_b.time_code_id == initial_b.time_code_id

      # Store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == [locked_b, locked_a]

      # Database
      assert_db_contains(TimeAllocation, [locked_a, locked_b])
      assert_db_count(TimeAllocation, 2, 2, :deleted)
    end

    test "valid (no allocs found for ids)", context do
      {:ok, data} = TimeAllocationAgent.lock([-1], context.calendar.id, context.dispatcher)

      # Return
      assert data.lock == nil
      assert data.deleted_ids == []
      assert data.ignored_ids == [-1]
      assert data.new == []

      # Store
      assert TimeAllocationAgent.active() == []
      assert TimeAllocationAgent.historic() == []

      # Database
      assert_db_count(TimeAllocation, 0)
    end

    test "invalid (no dispatcher id)", context do
      error = TimeAllocationAgent.lock([], context.calendar.id, nil)
      assert error == {:error, :invalid_dispatcher}
    end

    test "invalid (invalid dispatcher)", context do
      error = TimeAllocationAgent.lock([], context.calendar.id, -1)
      assert error == {:error, :invalid_dispatcher}
    end

    test "invalid (no calendar id)", context do
      error = TimeAllocationAgent.lock([], nil, context.dispatcher)
      assert error == {:error, :invalid_calendar}
    end

    test "invalid (invalid calendar)", context do
      error = TimeAllocationAgent.lock([], -1, context.dispatcher)
      assert error == {:error, :invalid_calendar}
    end
  end

  # it is theoretically possible for these tests to fail if you run them 1 second into the start of a shift
  describe "lock/3 active elements -" do
    test "valid (no split: completely within)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: shift_start} = context.calendar_today

      start_time = NaiveDateTime.add(shift_start, 1)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)
      lock = data.lock
      [locked, active] = Enum.sort_by(data.new, & &1.start_time, {:asc, NaiveDateTime})

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial.id]
      assert data.ignored_ids == []

      assert locked.id != initial.id
      assert_naive_equal(locked.start_time, initial.start_time)
      assert locked.end_time != nil
      assert_naive_equal(locked.end_time, active.start_time)
      assert active.end_time == nil
      assert locked.lock_id == lock.id
      assert locked.time_code_id == initial.time_code_id
      assert active.lock_id == nil
      assert active.time_code_id == initial.time_code_id

      # Store
      assert TimeAllocationAgent.active() == [active]
      assert TimeAllocationAgent.historic() == [locked]

      # Database
      assert_db_contains(TimeAllocation, [locked, active])
      assert_db_count(TimeAllocation, 2, 1, :deleted)
    end

    test "valid (no split: start on boundary, end inside)",
         %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: shift_start} = context.calendar_today

      start_time = shift_start

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)
      lock = data.lock
      [locked, active] = Enum.sort_by(data.new, & &1.start_time, {:asc, NaiveDateTime})

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial.id]
      assert data.ignored_ids == []

      assert locked.id != initial.id
      assert_naive_equal(locked.start_time, initial.start_time)
      assert locked.end_time != nil
      assert_naive_equal(locked.end_time, active.start_time)
      assert active.end_time == nil
      assert locked.lock_id == lock.id
      assert locked.time_code_id == initial.time_code_id
      assert active.lock_id == nil
      assert active.time_code_id == initial.time_code_id

      # Store
      assert TimeAllocationAgent.active() == [active]
      assert TimeAllocationAgent.historic() == [locked]

      # Database
      assert_db_contains(TimeAllocation, [locked, active])
      assert_db_count(TimeAllocation, 2, 1, :deleted)
    end

    test "valid (split: start outside, end inside)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: shift_start} = context.calendar_today

      start_time = NaiveDateTime.add(shift_start, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)
      lock = data.lock
      [before, locked, active] = Enum.sort_by(data.new, & &1.start_time, {:asc, NaiveDateTime})

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial.id]
      assert data.ignored_ids == []

      assert before.id != initial.id
      assert_naive_equal(before.start_time, initial.start_time)
      assert_naive_equal(before.end_time, shift_start)
      assert before.lock_id == nil
      assert before.time_code_id == initial.time_code_id

      assert locked.id != initial.id
      assert_naive_equal(locked.start_time, shift_start)
      assert_naive_equal(locked.end_time, active.start_time)
      assert locked.lock_id == lock.id
      assert locked.time_code_id == initial.time_code_id

      assert active.id != initial.id
      assert_naive_equal(active.start_time, locked.end_time)
      assert active.end_time == nil
      assert active.lock_id == nil
      assert active.time_code_id == initial.time_code_id

      # Store
      assert TimeAllocationAgent.active() == [active]
      assert TimeAllocationAgent.historic() == [locked, before]

      # Database
      assert_db_contains(TimeAllocation, [before, locked, active])
      assert_db_count(TimeAllocation, 3, 1, :deleted)
    end

    test "valid (split: start inside, end outside)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: shift_end} = context.calendar

      start_time = NaiveDateTime.add(shift_end, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)
      lock = data.lock

      [locked, alloc_after, active] =
        Enum.sort_by(data.new, & &1.start_time, {:asc, NaiveDateTime})

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial.id]
      assert data.ignored_ids == []

      assert locked.id != initial.id
      assert_naive_equal(locked.start_time, initial.start_time)
      assert_naive_equal(locked.end_time, shift_end)
      assert locked.lock_id == lock.id
      assert locked.time_code_id == initial.time_code_id

      assert alloc_after.id != initial.id
      assert_naive_equal(alloc_after.start_time, shift_end)
      assert_naive_equal(alloc_after.end_time, active.start_time)

      assert active.id != initial.id
      assert_naive_equal(active.start_time, alloc_after.end_time)
      assert active.end_time == nil
      assert active.lock_id == nil
      assert active.time_code_id == initial.time_code_id

      # Store
      assert TimeAllocationAgent.active() == [active]
      assert TimeAllocationAgent.historic() == [alloc_after, locked]

      # Database
      assert_db_contains(TimeAllocation, [locked, alloc_after, active])
      assert_db_count(TimeAllocation, 3, 1, :deleted)
    end

    test "valid (split: completely covers)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: shift_start, shift_end: shift_end} = context.calendar

      start_time = NaiveDateTime.add(shift_start, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)
      lock = data.lock

      [alloc_before, locked, alloc_after, active] =
        Enum.sort_by(data.new, & &1.start_time, {:asc, NaiveDateTime})

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial.id]
      assert data.ignored_ids == []

      assert alloc_before.id != initial.id
      assert_naive_equal(alloc_before.start_time, initial.start_time)
      assert_naive_equal(alloc_before.end_time, shift_start)
      assert alloc_before.lock_id == nil
      assert alloc_before.time_code_id == initial.time_code_id

      assert locked.id != initial.id
      assert_naive_equal(locked.start_time, shift_start)
      assert_naive_equal(locked.end_time, shift_end)
      assert locked.lock_id == lock.id
      assert locked.time_code_id == initial.time_code_id

      assert alloc_after.id != initial.id
      assert_naive_equal(alloc_after.start_time, shift_end)
      assert_naive_equal(alloc_after.end_time, active.start_time)

      assert active.id != initial.id
      assert_naive_equal(active.start_time, alloc_after.end_time)
      assert active.end_time == nil
      assert active.lock_id == nil
      assert active.time_code_id == initial.time_code_id

      # Store
      assert TimeAllocationAgent.active() == [active]
      assert TimeAllocationAgent.historic() == [alloc_after, locked, alloc_before]

      # Database
      assert_db_contains(TimeAllocation, [alloc_before, locked, alloc_after, active])
      assert_db_count(TimeAllocation, 4, 1, :deleted)
    end

    test "valid (element completely outside shift)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: shift_end} = context.calendar

      start_time = NaiveDateTime.add(shift_end, 60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> TimeAllocationAgent.add()

      {:ok, data} = TimeAllocationAgent.lock([initial.id], cal_id, context.dispatcher)

      # Return
      assert data.lock == nil
      assert data.deleted_ids == []
      assert data.ignored_ids == [initial.id]
      assert data.new == []

      # Store
      assert TimeAllocationAgent.active() == [initial]
      assert TimeAllocationAgent.historic() == []

      # Database
      assert_db_contains(TimeAllocation, [initial])
      assert_db_count(TimeAllocation, 1, 0, :deleted)
    end

    test "valid (multiple assets)", %{asset: asset_a, asset_b: asset_b, ready: ready} = context do
      %{id: cal_id, shift_start: shift_start} = context.calendar_today

      start_a = NaiveDateTime.add(shift_start, 1)
      start_b = NaiveDateTime.add(start_a, 1)

      {:ok, initial_a} =
        to_alloc(asset_a.id, ready, start_a, nil)
        |> TimeAllocationAgent.add()

      {:ok, initial_b} =
        to_alloc(asset_b.id, ready, start_b, nil)
        |> TimeAllocationAgent.add()

      {:ok, data} =
        TimeAllocationAgent.lock([initial_a.id, initial_b.id], cal_id, context.dispatcher)

      lock = data.lock

      [locked_a, locked_b, active_a, active_b] =
        egg = Enum.sort_by(data.new, & &1.start_time, {:asc, NaiveDateTime})

      # Return
      assert lock.calendar_id == cal_id
      assert lock.dispatcher_id == context.dispatcher

      assert data.deleted_ids == [initial_b.id, initial_a.id]
      assert data.ignored_ids == []

      assert locked_a.id != initial_a.id
      assert_naive_equal(locked_a.start_time, initial_a.start_time)
      assert locked_a.end_time != nil
      assert locked_a.lock_id == lock.id
      assert locked_a.time_code_id == initial_a.time_code_id

      assert active_a.lock_id == nil
      assert_naive_equal(active_a.start_time, locked_a.end_time)
      assert active_a.end_time == nil
      assert active_a.time_code_id == initial_a.time_code_id

      assert locked_b.id != initial_b.id
      assert_naive_equal(locked_b.start_time, initial_b.start_time)
      assert locked_b.end_time != nil
      assert locked_b.lock_id == lock.id
      assert locked_b.time_code_id == initial_b.time_code_id

      assert active_b.lock_id == nil
      assert_naive_equal(active_b.start_time, locked_b.end_time)
      assert active_b.end_time == nil
      assert active_b.time_code_id == initial_b.time_code_id

      # Store
      assert TimeAllocationAgent.active() == [active_a, active_b]

      assert Enum.sort_by(TimeAllocationAgent.historic(), & &1.asset_id) == [locked_a, locked_b]

      # Database
      assert_db_contains(TimeAllocation, [locked_a, locked_b, active_a, active_b])
      assert_db_count(TimeAllocation, 4, 2, :deleted)
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
