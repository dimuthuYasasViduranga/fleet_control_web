defmodule FleetControl.FleetControl.TimeAllocation.AgentTest do
  use FleetControlWeb.RepoCase
  @moduletag :agent

  alias FleetControl.{Helper, AssetAgent, TimeCodeAgent}
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

    AssetAgent.start_link([])
    [asset, asset_b | _] = AssetAgent.get_assets()
    TimeCodeAgent.start_link([])

    time_codes = TimeCodeAgent.get_time_codes()
    ready = Enum.find(time_codes, &(&1.name == "Dig Ore")).id
    exception = Enum.find(time_codes, &(&1.name == "Damage")).id
    no_task = Enum.find(time_codes, &(&1.name == "No Task")).id

    FleetControl.TimeAllocation.Agent.start_link([])
    [asset: asset, asset_b: asset_b, ready: ready, exception: exception, no_task: no_task]
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

  defp get_allocation(id) do
    TimeAllocation
    |> Repo.get_by(%{id: id})
    |> TimeAllocation.to_map()
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

  describe "Refresh -" do
    test "load no entries on startup" do
      # the agent _used_ to insert nulled maps for every asset
      initial = FleetControl.TimeAllocation.Agent.active()
      :ok = FleetControl.TimeAllocation.Agent.refresh!()
      current = FleetControl.TimeAllocation.Agent.active()

      # store
      assert initial == []
      assert current == []

      # database
      assert_db_count(TimeAllocation, 0, 0)
    end

    test "cached data equal to refresh", %{asset: asset, ready: ready} do
      now = NaiveDateTime.utc_now()
      second_at = NaiveDateTime.add(now, -1000)
      first_at = NaiveDateTime.add(second_at, -1000)

      {:ok, first} =
        to_alloc(asset.id, ready, first_at, nil)
        |> add_with_logs()

      {:ok, second} =
        to_alloc(asset.id, ready, second_at, nil)
        |> add_with_logs()

      cache_active = FleetControl.TimeAllocation.Agent.active()
      cache_historic = FleetControl.TimeAllocation.Agent.historic()

      :ok = FleetControl.TimeAllocation.Agent.refresh!(now)

      # return
      assert cache_active == [second]

      [historic_a] = cache_historic
      assert historic_a.deleted == false
      assert historic_a.deleted_at == nil
      assert NaiveDateTime.compare(historic_a.end_time, second.start_time)

      # store
      assert FleetControl.TimeAllocation.Agent.active() == cache_active
      assert FleetControl.TimeAllocation.Agent.historic() == cache_historic

      # database
      assert_db_contains(TimeAllocation, second)
      refute_db_contains(TimeAllocation, first)

      assert_db_count(TimeAllocation, 2, 1)
    end

    test "load most recent of 2 active allocs", %{asset: asset, ready: ready} do
      valid_start = NaiveDateTime.utc_now()
      invalid_start = NaiveDateTime.add(valid_start, -3600)

      invalid =
        to_alloc(asset.id, ready, invalid_start, nil)
        |> TimeAllocation.new()
        |> Repo.insert!()
        |> TimeAllocation.to_map()

      valid =
        to_alloc(asset.id, ready, valid_start, nil)
        |> TimeAllocation.new()
        |> Repo.insert!()
        |> TimeAllocation.to_map()

      :ok = FleetControl.TimeAllocation.Agent.refresh!()

      # return
      assert invalid.end_time == nil
      assert valid.end_time == nil

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [valid]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, [invalid, valid])
      assert_db_count(TimeAllocation, 2, 0)
    end

    test "ability to delete older of 2 active allocs", %{asset: asset, ready: ready} do
      valid_start = NaiveDateTime.utc_now()
      invalid_start = NaiveDateTime.add(valid_start, -3600)

      invalid =
        to_alloc(asset.id, ready, invalid_start, nil)
        |> TimeAllocation.new()
        |> Repo.insert!()
        |> TimeAllocation.to_map()

      valid =
        to_alloc(asset.id, ready, valid_start, nil)
        |> TimeAllocation.new()
        |> Repo.insert!()
        |> TimeAllocation.to_map()

      :ok = FleetControl.TimeAllocation.Agent.refresh!()

      {:ok, [deleted], updated, active_after_delete} =
        update_all_with_logs([Map.put(invalid, :deleted, true)])

      # return
      assert updated == []
      assert invalid.end_time == nil
      assert valid.end_time == nil

      assert deleted.id == invalid.id
      assert deleted.deleted == true
      assert active_after_delete == nil

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [valid]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, [valid, deleted])
      refute_db_contains(TimeAllocation, invalid)
      assert_db_count(TimeAllocation, 1, 1)
    end
  end

  describe "cached historic -" do
    test "add new (no existing)", %{asset: asset, ready: ready} do
      start_time = NaiveDateTime.utc_now()

      {:ok, actual} =
        to_alloc(asset.id, ready, start_time, nil)
        |> add_with_logs()

      # return
      assert actual.end_time == nil

      # store (actives never in historic)
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, actual)
      assert_db_count(TimeAllocation, 1, 0)
    end

    test "add new (existing)", %{asset: asset, ready: ready} do
      time_b = NaiveDateTime.utc_now()
      time_a = NaiveDateTime.add(time_b, -3600)

      {:ok, first} =
        to_alloc(asset.id, ready, time_a, nil)
        |> add_with_logs()

      {:ok, second} =
        to_alloc(asset.id, ready, time_b, nil)
        |> add_with_logs()

      completed_first = get_allocation(first.id + 1)

      # return
      assert first.end_time == nil
      assert second.end_time == nil

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [second]
      assert FleetControl.TimeAllocation.Agent.historic() == [completed_first]

      # database
      assert_db_contains(TimeAllocation, second)
      refute_db_contains(TimeAllocation, first)
      assert_db_contains(TimeAllocation, completed_first)
    end

    test "add completed (within culling range)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, completed} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      # return
      assert NaiveDateTime.compare(completed.end_time, end_time)

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [completed]

      # database
      assert_db_contains(TimeAllocation, completed)
      assert_db_count(TimeAllocation, 1, 0)
    end

    test "add completed (end in culling range)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -48 * 3600)

      {:ok, completed} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      # return
      assert NaiveDateTime.compare(completed.end_time, end_time)

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [completed]

      # database
      assert_db_contains(TimeAllocation, completed)
      assert_db_count(TimeAllocation, 1, 0)
    end

    test "add completed (out of culling range)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, 3600)

      {:ok, completed} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      # return
      assert NaiveDateTime.compare(completed.end_time, end_time)

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, completed)
      assert_db_count(TimeAllocation, 1, 0)
    end

    test "delete (initial within culling range)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, completed} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      historic_before = FleetControl.TimeAllocation.Agent.historic()

      {:ok, [deleted], updated, new_active} =
        update_all_with_logs([Map.put(completed, :deleted, true)])

      historic_after = FleetControl.TimeAllocation.Agent.historic()

      # return
      assert updated == []
      assert completed.deleted == false
      assert deleted.deleted == true
      assert new_active == nil

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert historic_before == [completed]
      assert historic_after == []

      # database
      assert_db_contains(TimeAllocation, deleted)
      refute_db_contains(TimeAllocation, completed)

      assert_db_count(TimeAllocation, 0, 1)
    end

    test "delete (initial out of culling range)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, 3600)

      {:ok, completed} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      historic_before = FleetControl.TimeAllocation.Agent.historic()

      {:ok, [deleted], updated, new_active} =
        update_all_with_logs([Map.put(completed, :deleted, true)])

      historic_after = FleetControl.TimeAllocation.Agent.historic()

      # return
      assert updated == []
      assert completed.deleted == false
      assert deleted.deleted == true
      assert new_active == nil

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert historic_before == []
      assert historic_after == []

      # database
      assert_db_contains(TimeAllocation, deleted)
      refute_db_contains(TimeAllocation, completed)

      assert_db_count(TimeAllocation, 0, 1)
    end

    test "update all (insert new completed in culling range)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)

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
      assert completed.deleted == false
      assert deleted == []
      assert new_active == nil

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [completed]

      # database
      assert_db_contains(TimeAllocation, completed)
      assert_db_count(TimeAllocation, 1, 0)
    end

    test "update all (insert completed out of culling range)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, 3600)
      updated_end_time = NaiveDateTime.add(end_time, 3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      {:ok, [deleted], [completed], new_active} =
        update_all_with_logs([
          Map.put(initial, :end_time, updated_end_time)
        ])

      # return
      assert new_active == nil

      assert initial.deleted == false
      assert initial.end_time != nil

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert completed.id != initial.id
      assert completed.deleted == false
      assert NaiveDateTime.compare(completed.end_time, updated_end_time)

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, [completed, deleted])
      refute_db_contains(TimeAllocation, initial)
      assert_db_count(TimeAllocation, 1, 1)
    end

    test "update all (modify completed within culling range)", %{asset: asset, ready: ready} do
      end_time = NaiveDateTime.utc_now()
      start_time = NaiveDateTime.add(end_time, -3600)
      updated_start_time = NaiveDateTime.add(start_time, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      {:ok, [deleted], [updated], new_active} =
        update_all_with_logs([
          Map.put(initial, :start_time, updated_start_time)
        ])

      # return
      assert new_active == nil

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert updated.id != initial.id
      assert updated.deleted == false
      assert NaiveDateTime.compare(updated.start_time, updated_start_time)

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == [updated]

      # database
      assert_db_contains(TimeAllocation, [updated, deleted])
      refute_db_contains(TimeAllocation, initial)
      assert_db_count(TimeAllocation, 1, 1)
    end

    test "update all (modify completed outside culling range)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, 3600)
      updated_end_time = NaiveDateTime.add(end_time, 3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      {:ok, [deleted], [updated], new_active} =
        update_all_with_logs([
          Map.put(initial, :end_time, updated_end_time)
        ])

      # return
      assert new_active == nil

      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert updated.id != initial.id
      assert updated.deleted == false
      assert NaiveDateTime.compare(updated.end_time, updated_end_time)

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, [updated, deleted])
      refute_db_contains(TimeAllocation, initial)
      assert_db_count(TimeAllocation, 1, 1)
    end

    test "update all (move completed outside => inside culling range)", %{
      asset: asset,
      ready: ready
    } do
      outside_start = ~N[2020-01-01 00:00:00]
      outside_end = NaiveDateTime.add(outside_start, 3600)

      inside_end = NaiveDateTime.utc_now()

      {:ok, outside_range} =
        to_alloc(asset.id, ready, outside_start, outside_end)
        |> add_with_logs()

      cached_historic = FleetControl.TimeAllocation.Agent.historic()

      {:ok, [deleted], [inside_range], new_active} =
        update_all_with_logs([
          Map.put(outside_range, :end_time, inside_end)
        ])

      # return
      assert new_active == nil

      assert new_active == nil

      assert deleted.id == outside_range.id
      assert deleted.deleted == true

      assert inside_range.id != outside_range.id
      assert inside_range.deleted == false
      assert NaiveDateTime.compare(inside_range.end_time, inside_end)

      # store
      assert cached_historic == []
      assert FleetControl.TimeAllocation.Agent.historic() == [inside_range]
      assert FleetControl.TimeAllocation.Agent.active() == []

      # database
      assert_db_contains(TimeAllocation, [deleted, inside_range])
      refute_db_contains(TimeAllocation, outside_range)
      assert_db_count(TimeAllocation, 1, 1)
    end

    test "update all (move completed inside => outside culling range)", %{
      asset: asset,
      ready: ready
    } do
      inside_end = NaiveDateTime.utc_now()
      inside_start = NaiveDateTime.add(inside_end, -3600)

      outside_start = ~N[2020-01-01 00:00:00]
      outside_end = NaiveDateTime.add(outside_start, 3600)

      {:ok, inside_range} =
        to_alloc(asset.id, ready, inside_start, inside_end)
        |> add_with_logs()

      cached_historic = FleetControl.TimeAllocation.Agent.historic()

      {:ok, [deleted], [outside_range], new_active} =
        update_all_with_logs([
          inside_range
          |> Map.put(:start_time, outside_start)
          |> Map.put(:end_time, outside_end)
        ])

      # return
      assert new_active == nil

      assert deleted.id == inside_range.id
      assert deleted.deleted == true

      assert outside_range.id != inside_range.id
      assert outside_range.deleted == false
      assert NaiveDateTime.compare(outside_range.start_time, outside_start)
      assert NaiveDateTime.compare(outside_range.end_time, outside_end)

      # store
      assert cached_historic == [inside_range]
      assert FleetControl.TimeAllocation.Agent.historic() == []
      assert FleetControl.TimeAllocation.Agent.active() == []

      # database
      assert_db_contains(TimeAllocation, [deleted, outside_range])
      refute_db_contains(TimeAllocation, inside_range)
      assert_db_count(TimeAllocation, 1, 1)
    end
  end

  describe "add active -" do
    test "valid (no previous allocation)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00.000000]

      alloc = to_alloc(asset.id, ready, start_time, nil)
      {:ok, actual} = add_with_logs(alloc)

      # return
      assert actual.asset_id == asset.id
      assert actual.time_code_id == ready
      assert NaiveDateTime.compare(actual.start_time, start_time) == :eq
      assert actual.end_time == nil

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [actual]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, actual)
      assert_db_count(TimeAllocation, 1, 0)
    end

    test "valid (unix timestamp)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00.123]

      alloc = to_alloc(asset.id, ready, Helper.to_unix(start_time), nil)
      {:ok, actual} = add_with_logs(alloc)

      # return
      assert actual.asset_id == asset.id
      assert actual.time_code_id == ready
      assert NaiveDateTime.compare(actual.start_time, start_time) == :eq
      assert actual.end_time == nil

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [actual]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, actual)
      assert_db_count(TimeAllocation, 1, 0)
    end

    test "valid (end previous active)", %{asset: asset, ready: ready, exception: exception} do
      next_start = NaiveDateTime.utc_now()
      initial_start = NaiveDateTime.add(next_start, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, initial_start, nil)
        |> add_with_logs()

      {:ok, active} =
        to_alloc(asset.id, exception, next_start, nil)
        |> add_with_logs()

      completed = get_allocation(initial.id + 1)

      # return
      assert active.end_time == nil

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [active]
      assert FleetControl.TimeAllocation.Agent.historic() == [completed]

      # database
      assert_db_contains(TimeAllocation, [active, completed])
      refute_db_contains(TimeAllocation, initial)
      assert_db_count(TimeAllocation, 2, 1)
    end

    test "valid (exception can end ready)", %{asset: asset, ready: ready, exception: exception} do
      next_start = NaiveDateTime.utc_now()
      initial_start = NaiveDateTime.add(next_start, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, initial_start, nil)
        |> add_with_logs()

      {:ok, active} =
        to_alloc(asset.id, exception, next_start, nil)
        |> add_with_logs()

      completed = get_allocation(initial.id + 1)

      # return
      assert active.end_time == nil

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [active]
      assert FleetControl.TimeAllocation.Agent.historic() == [completed]

      # database
      assert_db_contains(TimeAllocation, [active, completed])
      refute_db_contains(TimeAllocation, initial)
      assert_db_count(TimeAllocation, 2, 1)
    end

    test "valid (future rounded to now)", %{asset: asset, ready: ready} do
      future = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600)

      {:ok, actual} =
        to_alloc(asset.id, ready, future, nil)
        |> add_with_logs()

      # return
      assert NaiveDateTime.compare(actual.start_time, future) == :lt

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [actual]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, actual)
      assert_db_count(TimeAllocation, 1, 0)
    end

    test "valid (ready can end exception)", %{
      asset: asset,
      ready: ready,
      exception: exception
    } do
      initial_start = ~N[2020-01-01 00:00:00]
      next_start = NaiveDateTime.add(initial_start, 3600)

      {:ok, initial} =
        to_alloc(asset.id, exception, initial_start, nil)
        |> add_with_logs()

      {:ok, actual} =
        to_alloc(asset.id, ready, next_start, nil)
        |> add_with_logs()

      # return
      assert actual.time_code_id == ready
      assert NaiveDateTime.compare(actual.start_time, next_start) == :eq

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [actual]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, actual)
      refute_db_contains(TimeAllocation, initial)
      assert_db_count(TimeAllocation, 2, 1)
    end

    test "valid (null time code convereted to no task)", %{asset: asset, no_task: no_task} do
      now = NaiveDateTime.utc_now()

      {:ok, actual} =
        to_alloc(asset.id, nil, now, nil)
        |> add_with_logs()

      # return
      assert actual.time_code_id == no_task

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [actual]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, actual)
      assert_db_count(TimeAllocation, 1, 0)
    end

    test "invalid (invalid time code id)", %{asset: asset} do
      alloc = to_alloc(asset.id, -9000, NaiveDateTime.utc_now(), nil)
      error = add_with_logs(alloc)
      assert_ecto_error(error)
    end

    test "invalid (invalid asset)", %{ready: ready} do
      alloc = to_alloc(-9000, ready, NaiveDateTime.utc_now(), nil)
      actual = add_with_logs(alloc)
      assert_ecto_error(actual)
    end

    test "invalid (start active before current)", %{asset: asset, ready: ready} do
      now = ~N[2020-01-02 00:00:00]
      before = NaiveDateTime.add(now, -3600)

      {:ok, initial} =
        to_alloc(asset.id, ready, now, nil)
        |> add_with_logs()

      error =
        to_alloc(asset.id, ready, before, nil)
        |> add_with_logs()

      # return
      assert error == {:error, :start_before_active}

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [initial]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, initial)
      assert_db_count(TimeAllocation, 1, 0)
    end
  end

  describe "add complete -" do
    test "valid (no previous allocation)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, 3600)

      {:ok, completed} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      # return
      assert completed.deleted == false
      assert NaiveDateTime.compare(completed.start_time, start_time) == :eq
      assert NaiveDateTime.compare(completed.end_time, end_time) == :eq

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, completed)
      assert_db_count(TimeAllocation, 1, 0)
    end

    test "valid (insert before active)", %{asset: asset, ready: ready} do
      active_timestamp = ~N[2020-01-01 05:00:00]
      end_time = NaiveDateTime.add(active_timestamp, -3600)
      start_time = NaiveDateTime.add(end_time, -3600)

      {:ok, active} =
        to_alloc(asset.id, ready, active_timestamp, nil)
        |> add_with_logs()

      {:ok, completed} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      # return
      assert active.end_time == nil
      assert NaiveDateTime.compare(completed.start_time, start_time) == :eq
      assert NaiveDateTime.compare(completed.end_time, end_time) == :eq

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [active]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, [active, completed])
      assert_db_count(TimeAllocation, 2, 0)
    end

    test "valid (insert with end within active)", %{asset: asset, ready: ready} do
      active_start = ~N[2020-01-01 05:00:00]
      start_time = NaiveDateTime.add(active_start, -3600)
      end_time = NaiveDateTime.add(active_start, 3600)

      {:ok, active} =
        to_alloc(asset.id, ready, active_start, nil)
        |> add_with_logs()

      {:ok, completed} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      # return
      assert active.end_time == nil
      assert NaiveDateTime.compare(completed.start_time, start_time) == :eq
      assert NaiveDateTime.compare(completed.end_time, end_time) == :eq

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [active]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, [active, completed])
      assert_db_count(TimeAllocation, 2, 0)
    end

    test "valid (insert within active period)", %{asset: asset, ready: ready} do
      active_start = ~N[2020-01-01 05:00:00]
      start_time = NaiveDateTime.add(active_start, 3600)
      end_time = NaiveDateTime.add(start_time, 3600)

      {:ok, active} =
        to_alloc(asset.id, ready, active_start, nil)
        |> add_with_logs()

      {:ok, completed} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      # return
      assert active.end_time == nil
      assert NaiveDateTime.compare(completed.start_time, start_time) == :eq
      assert NaiveDateTime.compare(completed.end_time, end_time) == :eq

      # store
      assert FleetControl.TimeAllocation.Agent.active() == [active]
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, [active, completed])
      assert_db_count(TimeAllocation, 2, 0)
    end

    test "valid (delete zero duration element)", %{asset: asset, ready: ready} do
      timestamp = ~N[2020-01-01 05:00:00]

      {:ok, completed} =
        to_alloc(asset.id, ready, timestamp, timestamp)
        |> add_with_logs()

      # return
      assert completed.deleted == true
      assert completed.deleted_at != nil
      assert NaiveDateTime.compare(completed.start_time, timestamp) == :eq
      assert NaiveDateTime.compare(completed.end_time, timestamp) == :eq

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, completed)
      assert_db_count(TimeAllocation, 0, 1)
    end

    test "valid (delete when start before end)", %{asset: asset, ready: ready} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, -3600)

      {:ok, completed} =
        to_alloc(asset.id, ready, start_time, end_time)
        |> add_with_logs()

      # return
      assert completed.deleted == true
      assert completed.deleted_at != nil
      assert NaiveDateTime.compare(completed.start_time, start_time) == :eq
      assert NaiveDateTime.compare(completed.end_time, start_time) == :eq

      # store
      assert FleetControl.TimeAllocation.Agent.active() == []
      assert FleetControl.TimeAllocation.Agent.historic() == []

      # database
      assert_db_contains(TimeAllocation, completed)
      assert_db_count(TimeAllocation, 0, 1)
    end

    test "invalid (insert in the future)", %{asset: asset, ready: ready} do
      future_start = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600)
      future_end = NaiveDateTime.add(future_start, 3600)

      actual =
        to_alloc(asset.id, ready, future_start, future_end)
        |> add_with_logs()

      assert_ecto_error(actual)
    end

    test "invalid (time code)", %{asset: asset} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, 3600)

      actual =
        to_alloc(asset.id, -9000, start_time, end_time)
        |> add_with_logs()

      assert_ecto_error(actual)
    end
  end
end
