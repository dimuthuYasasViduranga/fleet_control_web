defmodule FleetControl.TimeAllocation.UnlockTest do
  use FleetControlWeb.RepoCase
  @moduletag :agent

  alias FleetControl.{
    CalendarAgent,
    AssetAgent,
    TimeCodeAgent,
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
    {result, log} = with_log(fn -> FleetControl.TimeAllocation.Agent.add(ta) end)
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

    FleetControl.TimeAllocation.Agent.start_link([])
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

  describe "unlock/1" do
    test "valid (all locked)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: shift_start} = context.calendar

      start_time = shift_start
      end_time = NaiveDateTime.add(shift_start, 60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      {:ok, lock_data} =
        FleetControl.TimeAllocation.Agent.lock([initial.id], cal_id, context.dispatcher)

      [locked] = lock_data.new

      {:ok, unlocked_data} = FleetControl.TimeAllocation.Agent.unlock([locked.id])
      [unlocked] = unlocked_data.new

      # Return
      assert unlocked_data.deleted_ids == [locked.id]
      assert unlocked_data.ignored_ids == []

      assert unlocked.id != locked.id
      assert_naive_equal(unlocked.start_time, locked.start_time)
      assert_naive_equal(unlocked.end_time, locked.end_time)
      assert unlocked.lock_id == nil
      assert unlocked.time_code_id == initial.time_code_id

      # Store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [unlocked]

      # Database
      assert_db_contains(TimeAllocation, unlocked)
      refute_db_contains(TimeAllocation, [initial, locked])
      assert_db_count(TimeAllocation, 1, 2, :deleted)
    end

    test "valid (no ids)" do
      {:ok, unlocked_data} = FleetControl.TimeAllocation.Agent.unlock([])

      # Return
      assert unlocked_data.deleted_ids == []
      assert unlocked_data.ignored_ids == []
      assert unlocked_data.new == []

      # Store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # Database
      assert_db_count(TimeAllocation, 0)
    end

    test "valid (some ids locked)", %{asset: asset, ready: ready} = context do
      %{id: cal_id, shift_start: shift_start} = context.calendar

      a_start = shift_start
      a_end = NaiveDateTime.add(a_start, 60)
      b_start = a_end
      b_end = NaiveDateTime.add(b_start, 60)

      {:ok, initial_a} =
        to_alloc(asset.id, ready, a_start, b_start)
        |> add_with_logs()

      {:ok, initial_b} =
        to_alloc(asset.id, ready, b_start, b_end)
        |> add_with_logs()

      {:ok, lock_data} =
        FleetControl.TimeAllocation.Agent.lock([initial_a.id], cal_id, context.dispatcher)

      [locked_a] = lock_data.new

      {:ok, unlocked_data} = FleetControl.TimeAllocation.Agent.unlock([locked_a.id, initial_b.id])
      [unlocked] = unlocked_data.new

      # Return
      assert unlocked_data.deleted_ids == [locked_a.id]
      assert unlocked_data.ignored_ids == [initial_b.id]

      assert unlocked.id != locked_a.id
      assert_naive_equal(unlocked.start_time, locked_a.start_time)
      assert_naive_equal(unlocked.end_time, locked_a.end_time)
      assert unlocked.lock_id == nil
      assert unlocked.time_code_id == initial_a.time_code_id

      # Store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [initial_b, unlocked]

      # Database
      assert_db_contains(TimeAllocation, [initial_b, unlocked])
      refute_db_contains(TimeAllocation, [initial_a, locked_a])
      assert_db_count(TimeAllocation, 2, 2, :deleted)
    end

    test "valid (invalid ids)" do
      {:ok, unlocked_data} = FleetControl.TimeAllocation.Agent.unlock([-1])

      # Return
      assert unlocked_data.ignored_ids == [-1]
      assert unlocked_data.deleted_ids == []
      assert unlocked_data.new == []

      # Store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # Database
      assert_db_count(TimeAllocation, 0)
    end
  end
end
