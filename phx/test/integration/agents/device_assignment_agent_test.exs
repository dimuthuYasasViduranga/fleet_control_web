defmodule Dispatch.DeviceAssignmentAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{Helper, AssetAgent, OperatorAgent, DeviceAssignmentAgent, DeviceAgent}
  alias HpsData.Schemas.Dispatch.DeviceAssignment

  setup _ do
    AssetAgent.start_link([])
    DeviceAgent.start_link([])
    DeviceAssignmentAgent.start_link([])

    OperatorAgent.start_link([])
    [operator_a, operator_b | _] = OperatorAgent.active()

    [asset_a, asset_b | _] = AssetAgent.get_assets(%{type: "Haul Truck"})

    {:ok, _, device_a} = DeviceAgent.add("device a")
    {:ok, _, device_b} = DeviceAgent.add("device b")

    [
      device: device_a,
      device_b: device_b,
      asset: asset_a,
      asset_b: asset_b,
      operator: operator_a,
      operator_b: operator_b
    ]
  end

  defp to_assignment(asset_id, device_id, timestamp \\ Helper.naive_timestamp()) do
    # this sleep is to help make sure subsequent elmenets dont have the same time
    :timer.sleep(2)

    %{
      asset_id: asset_id,
      device_id: device_id,
      operator_id: nil,
      timestamp: timestamp
    }
  end

  describe "new -" do
    test "valid", %{device: device, asset: asset} do
      assignment = to_assignment(asset.id, device.id)

      {:ok, assignment} = DeviceAssignmentAgent.new(assignment)

      # return
      assert assignment.asset_id == asset.id
      assert assignment.device_id == device.id
      assert assignment.operator_id == nil

      # store
      assert DeviceAssignmentAgent.current() == [assignment]
      assert DeviceAssignmentAgent.historic() == [assignment]

      # database
      assert_db_contains(DeviceAssignment, assignment)
    end

    test "invalid (empty assignment)" do
      assignment = to_assignment(nil, nil)

      actual = DeviceAssignmentAgent.new(assignment)

      assert_ecto_error(actual)
    end

    test "invalid (device id)", %{asset: asset} do
      assignment = to_assignment(asset.id, -1)

      actual = DeviceAssignmentAgent.new(assignment)
      assert_ecto_error(actual)
    end

    test "invalid (asset id)", %{device: device} do
      assignment = to_assignment(-1, device.id)

      actual = DeviceAssignmentAgent.new(assignment)
      assert_ecto_error(actual)
    end

    test "invalid (prevent future timestamp)", %{device: device, asset: asset} do
      future = NaiveDateTime.add(Helper.naive_timestamp(), 3600)
      assignment = to_assignment(asset.id, device.id, future)

      actual = DeviceAssignmentAgent.new(assignment)
      assert_ecto_error(actual)
    end
  end

  describe "change -" do
    test "valid (insert new when no existing)", %{device: device, asset: asset} do
      initial_assignment = DeviceAssignmentAgent.get(%{asset_id: asset.id})

      {:ok, assignment} = DeviceAssignmentAgent.change(asset.id, %{device_id: device.id})

      # return
      assert initial_assignment == nil
      assert assignment.device_id == device.id

      # store
      assert DeviceAssignmentAgent.current() == [assignment]
      assert DeviceAssignmentAgent.historic() == [assignment]

      # database
      assert_db_contains(DeviceAssignment, assignment)
    end

    test "valid (ignore asset id set in changes)", %{device: device, asset: asset} do
      # illustrates the change is ignored
      next_asset_id = asset.id + 1

      {:ok, assignment} =
        DeviceAssignmentAgent.change(asset.id, %{device_id: device.id, asset_id: next_asset_id})

      # returns
      next_asset = DeviceAssignmentAgent.get(%{asset_id: next_asset_id})

      assert next_asset == nil
      assert assignment.device_id == device.id
      assert assignment.asset_id == asset.id

      # store
      assert DeviceAssignmentAgent.current() == [assignment]
      assert DeviceAssignmentAgent.historic() == [assignment]

      # database
      assert_db_contains(DeviceAssignment, assignment)
    end

    test "valid (change to operator does not affect device)", %{
      asset: asset,
      device: device,
      operator: operator
    } do
      {:ok, initial} =
        DeviceAssignmentAgent.change(asset.id, %{device_id: device.id, operator_id: operator.id})

      # this helps with ordering
      :timer.sleep(1)

      {:ok, updated} = DeviceAssignmentAgent.change(asset.id, %{operator_id: nil})

      # returns
      assert initial.asset_id == asset.id
      assert initial.device_id == device.id
      assert initial.operator_id == operator.id

      assert updated.id != initial.id
      assert updated.asset_id == asset.id
      assert updated.device_id == device.id
      assert updated.operator_id == nil

      # store
      assert DeviceAssignmentAgent.current() == [updated]
      assert DeviceAssignmentAgent.historic() == [updated, initial]

      # database
      assert_db_contains(DeviceAssignment, [initial, updated])
    end

    test "valid (change to device does not affect operator)", %{
      asset: asset,
      device: device,
      operator: operator
    } do
      {:ok, initial} =
        DeviceAssignmentAgent.change(asset.id, %{device_id: device.id, operator_id: operator.id})

      # this helps with ordering
      :timer.sleep(1)

      {:ok, updated} = DeviceAssignmentAgent.change(asset.id, %{device_id: nil})

      # returns
      assert initial.asset_id == asset.id
      assert initial.device_id == device.id
      assert initial.operator_id == operator.id

      assert updated.id != initial.id
      assert updated.asset_id == asset.id
      assert updated.device_id == nil
      assert updated.operator_id == operator.id

      # store
      assert DeviceAssignmentAgent.current() == [updated]
      assert DeviceAssignmentAgent.historic() == [updated, initial]

      # database
      assert_db_contains(DeviceAssignment, [initial, updated])
    end

    test "invalid (asset id)", %{device: device} do
      actual = DeviceAssignmentAgent.change(-1, %{device_id: device.id})
      assert_ecto_error(actual)
    end

    test "invalid (asset with invalid change)", %{asset: asset} do
      actual = DeviceAssignmentAgent.change(asset.id, %{device_id: -1})
      assert_ecto_error(actual)
    end
  end

  describe "clear_operators -" do
    test "valid", %{device: device, asset: asset, operator: operator} do
      assignment = %{
        asset_id: asset.id,
        device_id: device.id,
        operator_id: operator.id,
        timestamp: NaiveDateTime.utc_now()
      }

      {:ok, initial} = DeviceAssignmentAgent.new(assignment)

      {:ok, [actual]} = DeviceAssignmentAgent.clear_operators([asset.id])

      # return
      assert initial.device_id == device.id
      assert initial.asset_id == asset.id
      assert initial.operator_id == operator.id

      assert actual.id != initial.id
      assert actual.device_id == device.id
      assert actual.asset_id == asset.id
      assert actual.operator_id == nil

      # store
      assert DeviceAssignmentAgent.current() == [actual]
      assert DeviceAssignmentAgent.historic() == [actual, initial]

      # database
      assert_db_contains(DeviceAssignment, [actual, initial])
    end

    test "valid (already has no operator)", %{device: device, asset: asset} do
      assignment = to_assignment(asset.id, device.id)

      {:ok, initial} = DeviceAssignmentAgent.new(assignment)

      {:ok, [actual]} = DeviceAssignmentAgent.clear_operators([asset.id])

      # return
      assert initial.device_id == device.id
      assert initial.asset_id == asset.id
      assert initial.operator_id == nil

      assert actual.id != initial.id
      assert actual.device_id == device.id
      assert actual.asset_id == asset.id
      assert actual.operator_id == nil

      # store
      assert DeviceAssignmentAgent.current() == [actual]
      assert DeviceAssignmentAgent.historic() == [actual, initial]

      # database
      assert_db_contains(DeviceAssignment, [actual, initial])
    end

    test "valid (clear multiple assets)", context do
      # these timestamp just help order the results
      a_timestamp = NaiveDateTime.utc_now()
      b_timestamp = NaiveDateTime.add(a_timestamp, -1)

      assignment_a = %{
        asset_id: context.asset.id,
        device_id: context.device.id,
        operator_id: context.operator.id,
        timestamp: a_timestamp
      }

      assignment_b = %{
        asset_id: context.asset_b.id,
        device_id: context.device_b.id,
        operator_id: context.operator_b.id,
        timestamp: b_timestamp
      }

      {:ok, initial_a} = DeviceAssignmentAgent.new(assignment_a)
      {:ok, initial_b} = DeviceAssignmentAgent.new(assignment_b)

      {:ok, [actual_b, actual_a]} =
        DeviceAssignmentAgent.clear_operators([context.asset.id, context.asset_b.id])

      # return
      # assignment A
      assert initial_a.device_id == context.device.id
      assert initial_a.asset_id == context.asset.id
      assert initial_a.operator_id == context.operator.id

      assert actual_a.id != initial_a.id
      assert actual_a.device_id == context.device.id
      assert actual_a.asset_id == context.asset.id
      assert actual_a.operator_id == nil

      # assignment B
      assert initial_b.device_id == context.device_b.id
      assert initial_b.asset_id == context.asset_b.id
      assert initial_b.operator_id == context.operator_b.id

      assert actual_b.id != initial_b.id
      assert actual_b.device_id == context.device_b.id
      assert actual_b.asset_id == context.asset_b.id
      assert actual_b.operator_id == nil

      # store
      assert DeviceAssignmentAgent.current() == [actual_a, actual_b]
      assert DeviceAssignmentAgent.historic() == [actual_b, actual_a, initial_a, initial_b]

      # database
      assert_db_contains(DeviceAssignment, [actual_a, actual_b, initial_a, initial_b])
    end

    test "valid (no asset ids)" do
      {:ok, assignments} = DeviceAssignmentAgent.clear_operators([])

      # return
      assert assignments == []

      # store
      assert DeviceAssignmentAgent.current() == []
      assert DeviceAssignmentAgent.historic() == []

      # database
      assert_db_count(DeviceAssignment, 0)
    end

    test "valid (invalid asset ids)" do
      {:ok, assignments} = DeviceAssignmentAgent.clear_operators([-1])

      # return
      assert assignments == []

      # store
      assert DeviceAssignmentAgent.current() == []
      assert DeviceAssignmentAgent.historic() == []

      # database
      assert_db_count(DeviceAssignment, 0)
    end
  end

  describe "clear -" do
    test "valid", %{device: device, asset: asset} do
      assignment = to_assignment(asset.id, device.id)

      {:ok, initial} = DeviceAssignmentAgent.new(assignment)
      {:ok, assignment} = DeviceAssignmentAgent.clear(asset.id)

      # return
      assert assignment.asset_id == asset.id
      assert assignment.device_id == nil
      assert assignment.operator_id == nil

      # store
      assert DeviceAssignmentAgent.current() == [assignment]
      assert DeviceAssignmentAgent.historic() == [assignment, initial]

      # database
      assert_db_contains(DeviceAssignment, [initial, assignment])
    end

    test "invalid (asset id)" do
      actual = DeviceAssignmentAgent.clear(-1)
      assert_ecto_error(actual)
    end
  end

  describe "current assignments list -" do
    test "valid (insert after current)", %{device: device, asset: asset} do
      {:ok, _, new_device} = DeviceAgent.add("new device")
      {:ok, first} = DeviceAssignmentAgent.new(to_assignment(asset.id, device.id))
      {:ok, second} = DeviceAssignmentAgent.new(to_assignment(asset.id, new_device.id))

      # returns
      cur_assign = DeviceAssignmentAgent.get(%{asset_id: asset.id})
      assert cur_assign.asset_id == asset.id
      assert cur_assign.device_id == new_device.id

      # store
      assert DeviceAssignmentAgent.current() == [second]
      assert DeviceAssignmentAgent.historic() == [second, first]

      # database
      assert_db_contains(DeviceAssignment, [first, second])
    end

    test "valid (insert before current)", %{device: device, asset: asset} do
      old_time = ~N[2020-01-01 00:00:00]
      {:ok, _, new_device} = DeviceAgent.add("new device")
      {:ok, first} = DeviceAssignmentAgent.new(to_assignment(asset.id, device.id))
      {:ok, second} = DeviceAssignmentAgent.new(to_assignment(asset.id, new_device.id, old_time))

      # returns
      cur_assign = DeviceAssignmentAgent.get(%{asset_id: asset.id})
      assert cur_assign.asset_id == asset.id
      assert cur_assign.device_id == device.id
      assert NaiveDateTime.compare(cur_assign.timestamp, old_time) != :eq

      # store
      assert DeviceAssignmentAgent.current() == [first]
      assert DeviceAssignmentAgent.historic() == [first, second]

      # database
      assert_db_contains(DeviceAssignment, [first, second])
    end
  end

  describe "historic cull checks -" do
    test "valid (add a cullable assignment - 1 outside range always kept)", %{
      device: device,
      asset: asset
    } do
      old = ~N[2020-01-01 00:00:00]
      older = NaiveDateTime.add(old, -3600)

      {:ok, first} = DeviceAssignmentAgent.new(to_assignment(asset.id, device.id, old))
      {:ok, second} = DeviceAssignmentAgent.new(to_assignment(asset.id, device.id, older))

      # store
      assert DeviceAssignmentAgent.historic() == [first]

      # database
      assert_db_contains(DeviceAssignment, [first, second])
    end
  end

  describe "fetch by range! -" do
    test "valid (range with data)", %{device: device, asset: asset} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = ~N[2020-02-01 00:00:00]
      expected_inserts = 5

      inserts =
        Enum.map(1..expected_inserts, fn _ ->
          {:ok, assignment} =
            DeviceAssignmentAgent.new(to_assignment(asset.id, device.id, start_time))

          assignment
        end)

      actual =
        DeviceAssignmentAgent.fetch_by_range!(%{start_time: start_time, end_time: end_time})

      # return
      assert length(actual) == expected_inserts

      # database
      assert_db_contains(DeviceAssignment, inserts)
    end

    test "valid (range completely without data)" do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = ~N[2020-02-01 00:00:00]

      actual =
        DeviceAssignmentAgent.fetch_by_range!(%{start_time: start_time, end_time: end_time})

      assert actual == []
    end

    test "valid (includes 1 before, within and after range)", %{asset: asset, device: device} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = ~N[2020-02-01 00:00:00]

      before_start = NaiveDateTime.add(start_time, -3600)
      within_range = NaiveDateTime.add(start_time, 3600)
      after_end = NaiveDateTime.add(end_time, 3600)

      {:ok, a} = DeviceAssignmentAgent.new(to_assignment(asset.id, device.id, before_start))
      {:ok, b} = DeviceAssignmentAgent.new(to_assignment(asset.id, device.id, within_range))
      {:ok, c} = DeviceAssignmentAgent.new(to_assignment(asset.id, device.id, after_end))

      actual =
        DeviceAssignmentAgent.fetch_by_range!(%{start_time: start_time, end_time: end_time})

      # returns
      assert actual == [a, b, c]

      # database
      assert_db_contains(DeviceAssignment, [a, b, c])
    end
  end
end
