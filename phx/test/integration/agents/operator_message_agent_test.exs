defmodule Dispatch.OperatorMessageAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{AssetAgent, DeviceAgent, OperatorAgent, OperatorMessageAgent}
  alias HpsData.Schemas.Dispatch.{OperatorMessageType, OperatorMessage}

  setup do
    [type | _] =
      OperatorMessageType
      |> Repo.all()
      |> Enum.map(&OperatorMessageType.to_map/1)

    AssetAgent.start_link([])
    [asset | _] = AssetAgent.get_assets(%{type: "Haul Truck"})

    OperatorAgent.start_link([])
    OperatorAgent.add("message-operator", "Test", nil)
    [operator] = OperatorAgent.active()

    DeviceAgent.start_link([])
    OperatorMessageAgent.start_link([])
    {:ok, _, device} = DeviceAgent.add("123456")
    [device: device, type: type.id, asset: asset, operator: operator]
  end

  defp to_message(
         asset_id,
         device_id,
         operator_id,
         message_type_id,
         timestamp \\ NaiveDateTime.utc_now()
       ) do
    %{
      asset_id: asset_id,
      device_id: device_id,
      operator_id: operator_id,
      type_id: message_type_id,
      timestamp: timestamp
    }
  end

  defp merge_missing_keys(input, actual) do
    %{
      id: actual.id,
      asset_id: input.asset_id,
      device_id: input.device_id,
      operator_id: input.operator_id,
      type_id: input.type_id,
      timestamp: input.timestamp,
      server_timestamp: actual.server_timestamp,
      acknowledge_id: actual.acknowledge_id
    }
  end

  describe "new -" do
    test "valid", %{asset: asset, device: device, operator: operator, type: type} do
      message = to_message(asset.id, device.id, operator.id, type)
      {:ok, actual} = OperatorMessageAgent.new(message)

      expected = merge_missing_keys(message, actual)

      # return
      assert actual == expected

      # store
      assert OperatorMessageAgent.all() == [actual]

      # database
      assert_db_contains(OperatorMessage, actual)
    end

    test "invalid (missing asset)", %{device: device, operator: operator, type: type} do
      message = to_message(nil, device.id, operator.id, type)
      actual = OperatorMessageAgent.new(message)
      assert_ecto_error(actual)
    end

    test "invalid (invalid asset)", %{device: device, operator: operator, type: type} do
      message = to_message(-1, device.id, operator.id, type)

      actual = OperatorMessageAgent.new(message)
      assert_ecto_error(actual)
    end
  end

  describe "acknowledge" do
    test "valid", %{asset: asset, device: device, operator: operator, type: type} do
      acknowledge_at = NaiveDateTime.utc_now()
      created_at = NaiveDateTime.add(acknowledge_at, -60)

      message = to_message(asset.id, device.id, operator.id, type, created_at)
      {:ok, unacknowledged} = OperatorMessageAgent.new(message)
      {:ok, acknowledged} = OperatorMessageAgent.acknowledge(unacknowledged.id, acknowledge_at)

      expected_unacknowledged = merge_missing_keys(message, unacknowledged)
      expected_acknowledged = merge_missing_keys(message, acknowledged)

      # return
      assert unacknowledged == expected_unacknowledged
      assert acknowledged == expected_acknowledged

      # store
      assert OperatorMessageAgent.all() == [acknowledged]

      # database
      assert_db_contains(OperatorMessage, acknowledged)
      refute_db_contains(OperatorMessage, unacknowledged)
    end

    test "invalid (id)" do
      actual = OperatorMessageAgent.acknowledge(-1, NaiveDateTime.utc_now())
      assert actual == {:error, :invalid_id}
    end

    test "invalid (already acknowledged)", %{
      asset: asset,
      device: device,
      operator: operator,
      type: type
    } do
      acknowledged_at = NaiveDateTime.utc_now()
      created_at = NaiveDateTime.add(acknowledged_at, -60)

      message = to_message(asset.id, device.id, operator.id, type, created_at)

      {:ok, unacknowledged} = OperatorMessageAgent.new(message)
      {:ok, acknowledged} = OperatorMessageAgent.acknowledge(unacknowledged.id, acknowledged_at)
      error = OperatorMessageAgent.acknowledge(unacknowledged.id, acknowledged_at)

      expected_unacknowledged = merge_missing_keys(message, unacknowledged)
      expected_acknowledged = merge_missing_keys(message, acknowledged)

      # return
      assert unacknowledged == expected_unacknowledged
      assert acknowledged == expected_acknowledged
      assert error == {:error, :already_acknowledged}

      # store
      assert OperatorMessageAgent.all() == [acknowledged]

      # database

      # database
      assert_db_contains(OperatorMessage, acknowledged)
      refute_db_contains(OperatorMessage, unacknowledged)
    end
  end
end
