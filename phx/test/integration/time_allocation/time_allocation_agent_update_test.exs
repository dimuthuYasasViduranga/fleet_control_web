defmodule FleetControl.FleetControl.TimeAllocation.AgentUpdateTest do
  use FleetControlWeb.RepoCase
  @moduletag :agent

  alias FleetControl.{
    Helper,
    CalendarAgent,
    AssetAgent,
    DispatcherAgent,
    TimeCodeAgent
  }

  alias HpsData.Schemas.Dispatch.{TimeAllocation, TimeCode, TimeCodeGroup}

  import ExUnit.CaptureLog

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

    yesterdays_calendar =
      CalendarAgent.get_at(NaiveDateTime.add(todays_calendar.shift_start, -60))

    AssetAgent.start_link([])
    [asset, asset_b | _] = AssetAgent.get_assets()

    TimeCodeAgent.start_link([])
    time_codes = TimeCodeAgent.get_time_codes()
    ready = Enum.find(time_codes, &(&1.name == "Dig Ore")).id
    exception = Enum.find(time_codes, &(&1.name == "Damage")).id
    no_task = Enum.find(time_codes, &(&1.name == "No Task")).id

    FleetControl.TimeAllocation.Agent.start_link([])
    DispatcherAgent.start_link([])
    {:ok, dispatcher} = DispatcherAgent.add("1234", "test")

    [
      asset: asset,
      asset_b: asset_b,
      ready: ready,
      exception: exception,
      no_task: no_task,
      calendar: yesterdays_calendar,
      dispatcher: dispatcher.id
    ]
  end

  defp to_alloc(asset_id, time_code_id, start_time, end_time) do
    %{
      asset_id: asset_id,
      time_code_id: time_code_id,
      start_time: start_time,
      end_time: end_time
    }
  end

  defp update_all_with_logs(updates) do
    {result, log} = with_log(fn -> FleetControl.TimeAllocation.Agent.update_all(updates) end)
    assert log =~ "[error] Time allocation updated without recording the source of the update"
    result
  end

  defp add_with_logs(ta) do
    {result, log} = with_log(fn -> FleetControl.TimeAllocation.Agent.add(ta) end)
    assert log =~ "[error] Time allocation created without recording it's source"
    result
  end

  describe "Update all -" do
    test "valid (create new active, no existing)", %{asset: asset, ready: ready} do
      start_time = NaiveDateTime.utc_now()

      {:ok, deleted, completed, new_active} =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == [new_active]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, new_active)
    end

    test "valid (create new complete, no existing)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, deleted, [complete], new_active} =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [complete]

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, complete)
    end

    test "valid (create new completed, unix timestamps)", %{asset: asset, ready: ready} do
      end_time =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.truncate(:millisecond)

      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, deleted, [complete], new_active} =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [complete]

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, complete)
    end

    test "valid (create new active, existing active)", %{asset: asset, ready: ready} do
      start_time = NaiveDateTime.utc_now()
      initial_timestamp = NaiveDateTime.add(start_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, initial_timestamp, nil)
        |> add_with_logs()

      {:ok, [deleted], [completed], new_active} =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == [new_active]
      assert FleetControl.TimeAllocation.Agent.historic() == [completed]

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
        |> add_with_logs()

      {:ok, deleted, completed, new_active} =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == [initial]
      assert FleetControl.TimeAllocation.Agent.historic() == []

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
        |> add_with_logs()

      {:ok, deleted, [completed], new_active} =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == [initial]
      assert FleetControl.TimeAllocation.Agent.historic() == [completed]

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
        |> add_with_logs()

      {:ok, deleted, [completed], new_active} =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == [initial]
      assert FleetControl.TimeAllocation.Agent.historic() == [completed]

      # database
      assert_db_count(TimeAllocation, 2, 0)
      assert_db_contains(TimeAllocation, [initial, completed])
    end

    test "valid (delete active and create new one)", %{asset: asset, ready: ready} do
      now = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(now, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> add_with_logs()

      {:ok, [deleted], completed, new_active} =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == [new_active]
      assert FleetControl.TimeAllocation.Agent.historic() == []

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
        |> add_with_logs()

      {:ok, [deleted], [completed], new_active} =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == [new_active]
      assert FleetControl.TimeAllocation.Agent.historic() == [completed]

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
        |> add_with_logs()

      {:ok, [deleted], completed, new_active} =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == [new_active]
      assert FleetControl.TimeAllocation.Agent.historic() == []

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
        |> add_with_logs()

      {:ok, [deleted], [completed], new_active} =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [completed]

      # database
      assert_db_count(TimeAllocation, 1, 1)
      assert_db_contains(TimeAllocation, [deleted, completed])
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (delete active element)", %{asset: asset, ready: ready} do
      start_time = NaiveDateTime.utc_now()

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> add_with_logs()

      {:ok, [deleted], completed, new_active} =
        update_all_with_logs([
          Map.put(initial, :deleted, true)
        ])

      # return
      assert deleted.id == initial.id
      assert deleted.deleted == true
      assert completed == []
      assert new_active.time_code_id == TimeCodeAgent.no_task_id()

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [new_active]
      assert FleetControl.TimeAllocation.Agent.historic() == []

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
        |> add_with_logs()

      {:ok, [deleted], completed, new_active} =
        update_all_with_logs([
          Map.put(initial, :deleted, true)
        ])

      # return
      assert completed == []
      assert new_active == nil
      assert deleted.id == initial.id
      assert deleted.deleted == true

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_count(TimeAllocation, 0, 1)
      assert_db_contains(TimeAllocation, deleted)
      refute_db_contains(TimeAllocation, initial)
    end

    test "valid (insert no changes)" do
      {:ok, deleted, completed, new_active} = FleetControl.TimeAllocation.Agent.update_all([])

      # return
      assert deleted == []
      assert completed == []
      assert new_active == nil

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_count(TimeAllocation, 0, 0)
    end

    test "valid (insert no effective changes [insert new deleted])", %{asset: asset, ready: ready} do
      {:ok, deleted, completed, new_active} =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_count(TimeAllocation, 0, 0)
    end

    test "valid (nil time codes converted to no task)", %{asset: asset, no_task: no_task} do
      {:ok, deleted, completed, new_active} =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == [new_active]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, new_active)
      assert_db_count(TimeAllocation, 1, 0)
    end

    test "invalid (insert completed with end before start)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, -3600)

      actual =
        update_all_with_logs([
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
        |> add_with_logs()

      error =
        update_all_with_logs([
          Map.put(initial, :end_time, end_time)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [initial]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (create multiple actives)", %{asset: asset, ready: ready} do
      actual =
        update_all_with_logs([
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
        update_all_with_logs([
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
        |> add_with_logs()

      error =
        update_all_with_logs([
          Map.put(initial, :start_time, nil)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [initial]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (remove completed start)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      error =
        update_all_with_logs([
          Map.put(initial, :start_time, nil)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [initial]

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (remove completed end)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      error =
        update_all_with_logs([
          Map.put(initial, :end_time, nil)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [initial]

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (end active element in future)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      future = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> add_with_logs()

      error =
        update_all_with_logs([
          Map.put(initial, :end_time, future)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [initial]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (move active start into future)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      future = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, nil)
        |> add_with_logs()

      error =
        update_all_with_logs([
          Map.put(initial, :start_time, future)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [initial]
      assert FleetControl.TimeAllocation.Agent.historic() == []

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
        |> add_with_logs()

      error =
        update_all_with_logs([
          initial
          |> Map.put(:start_time, future_start)
          |> Map.put(:end_time, future_end)
        ])

      # return
      assert error == {:error, :invalid}

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      # completed is very old
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (change asset on active)", %{asset: asset_a, asset_b: asset_b, ready: ready} do
      start_time = NaiveDateTime.utc_now()

      {:ok, initial} =
        to_alloc(asset_a.id, ready, start_time, nil)
        |> add_with_logs()

      actual =
        update_all_with_logs([
          Map.put(initial, :asset_id, asset_b.id)
        ])

      # return
      assert actual == {:error, :multiple_assets}

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [initial]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_count(TimeAllocation, 1, 0)
      assert_db_contains(TimeAllocation, initial)
    end

    test "invalid (change asset on completed)", %{asset: asset_a, asset_b: asset_b, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, initial} =
        to_alloc(asset_a.id, ready, start_time, end_time)
        |> add_with_logs()

      actual =
        update_all_with_logs([
          Map.put(initial, :asset_id, asset_b.id)
        ])

      # return
      assert actual == {:error, :multiple_assets}

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [initial]

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
        |> add_with_logs()

      {:ok, [deleted], [completed], new_active} =
        update_all_with_logs([
          Map.put(initial, :time_code_id, exception)
        ])

      error =
        update_all_with_logs([
          Map.put(initial, :time_code_id, exception)
        ])

      # return
      assert error == {:error, :stale}

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert new_active == nil

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [completed]

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
        |> add_with_logs()

      {:ok, [deleted], completed, new_active} =
        update_all_with_logs([Map.put(initial, :deleted, true)])

      error =
        update_all_with_logs([
          Map.put(deleted, :time_code_id, exception)
        ])

      # return
      assert completed == []
      assert new_active == nil

      assert error == {:error, :stale}

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_count(TimeAllocation, 0, 1)
      assert_db_contains(TimeAllocation, deleted)
      refute_db_contains(TimeAllocation, initial)
    end

    test "invalid (id doesnt exist)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, 3600)

      actual =
        update_all_with_logs([
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
        |> add_with_logs()

      actual =
        update_all_with_logs([
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
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [initial]

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
        |> add_with_logs()

      {:ok, lock_data} = FleetControl.TimeAllocation.Agent.lock([initial.id], cal_id, context.dispatcher)
      [locked] = lock_data.new
      [deleted_id] = lock_data.deleted_ids

      error = update_all_with_logs([Map.put(locked, :start_time, r_start)])

      # return
      assert error == {:error, :cannot_change_locked}

      assert locked.id != initial.id
      assert locked.lock_id == lock_data.lock.id
      assert deleted_id == initial.id

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [locked]

      # database
      assert_db_contains(TimeAllocation, locked)
      refute_db_contains(TimeAllocation, initial)
      assert_db_count(TimeAllocation, 1, 1, :deleted)
    end

    test "invalid (update element to locked)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.add(NaiveDateTime.utc_now(), -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      error = update_all_with_logs([Map.put(initial, :lock_id, 1)])

      # return
      assert error == {:error, :cannot_set_locked}

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [initial]

      # database
      assert_db_contains(TimeAllocation, initial)
    end
  end
end
