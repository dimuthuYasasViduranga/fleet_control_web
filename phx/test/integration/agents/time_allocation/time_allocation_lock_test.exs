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

  alias HpsData.Schemas.Dispatch.{TimeAllocation, TimeCode, TimeCodeGroup}

  import ExUnit.CaptureLog

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

  defp add_with_logs(ta) do
    {result, log} = with_log(fn -> TimeAllocationAgent.add(ta) end)
    assert log =~ "[error] Time allocation created without recording it's source"
    result
  end

  setup do
    group_map =
      Repo.all(TimeCodeGroup)
      |> Enum.map(&{&1.name, &1.id})
      |> Enum.into(%{})

    # insert example time codes
    Repo.insert!(%TimeCode{code: "1000", name: "Dig Ore", group_id: group_map["Ready"]})
    Repo.insert!(%TimeCode{code: "2000", name: "Damage", group_id: group_map["Down"]})

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

    TimeAllocationAgent.start_link([])
    DispatcherAgent.start_link([])
    {:ok, dispatcher} = DispatcherAgent.add("1234", "test")

    [
      asset: asset,
      asset_b: asset_b,
      ready: ready,
      exception: exception,
      calendar: yesterdays_calendar,
      calendar_today: todays_calendar,
      calendar_future: future_calendar,
      dispatcher: dispatcher.id
    ]
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

  describe "lock/3 complete elements -" do
    test "valid (no split: completely within)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_end: shift_end} = context.calendar

      end_time = NaiveDateTime.add(shift_end, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

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
        |> add_with_logs()

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
        |> add_with_logs()

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
        |> add_with_logs()

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
        |> add_with_logs()

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
        |> add_with_logs()

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
        |> add_with_logs()

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

    test "valid (no elements)", context do
      {:ok, data} = TimeAllocationAgent.lock([], context.calendar.id, context.dispatcher)

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
        |> add_with_logs()

      {:ok, initial_b} =
        to_alloc(asset_b.id, ready, b_start, b_end)
        |> add_with_logs()

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
        |> add_with_logs()

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
        |> add_with_logs()

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
        |> add_with_logs()

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
        |> add_with_logs()

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
        |> add_with_logs()

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
        |> add_with_logs()

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
        |> add_with_logs()

      {:ok, initial_b} =
        to_alloc(asset_b.id, ready, start_b, nil)
        |> add_with_logs()

      {:ok, data} =
        TimeAllocationAgent.lock([initial_a.id, initial_b.id], cal_id, context.dispatcher)

      lock = data.lock

      [locked_a, locked_b, active_a, active_b] =
        Enum.sort_by(data.new, & &1.start_time, {:asc, NaiveDateTime})

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
end
