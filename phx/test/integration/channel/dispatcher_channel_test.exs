defmodule FleetControlWeb.DispatcherChannel.Test do
  use FleetControlWeb.ChannelCase
  @moduletag :channel

  alias FleetControl.{Helper, AssetAgent, DeviceAgent, OperatorAgent, DeviceAssignmentAgent}
  alias FleetControlWeb.{DispatcherSocket, DispatcherChannel, OperatorSocket, OperatorChannel}
  alias FleetControlWeb.Authorization.Permissions

  import Phoenix.Socket, only: [assign: 3]

  @dispatcher "dispatchers:all"
  @uuid "abcdefg"
  @operator "operators:#{@uuid}"

  defp unix_now(), do: Helper.to_unix(NaiveDateTime.utc_now())

  setup do
    [asset, asset_b] = AssetAgent.get_assets(%{type: "Haul Truck"})
    {:ok, :new, device} = DeviceAgent.add(@uuid)
    {:ok, operator} = OperatorAgent.add("channel_operator", "Test", nil)

    {:ok, assignment} =
      DeviceAssignmentAgent.new(%{
        asset_id: asset.id,
        device_id: device.id,
        operator: operator.id,
        timestamp: NaiveDateTime.utc_now()
      })

    {:ok, _, d_socket} =
      DispatcherSocket
      |> socket("user_id", %{})
      |> assign(:permissions, Permissions.full_permissions())
      |> subscribe_and_join(DispatcherChannel, @dispatcher)

    {:ok, _, o_socket} =
      OperatorSocket
      |> socket("user_id", %{
        operator_id: operator.id,
        device_uuid: device.uuid,
        device_id: device.id
      })
      |> subscribe_and_join(OperatorChannel, @operator)

    [
      device: device,
      asset: asset,
      asset_b: asset_b,
      operator: operator,
      assignment: assignment,
      d_socket: d_socket,
      o_socket: o_socket
    ]
  end

  test "set radio number", %{d_socket: d_socket, asset: %{id: asset_id}} do
    topic = "set radio number"

    payload = %{
      "asset_id" => asset_id,
      "radio_number" => "1234"
    }

    ref = push(d_socket, topic, payload)
    assert_reply(ref, :ok)

    assert_broadcast_receive(d_socket, "set asset radios", %{asset_radios: [_]})
  end

  describe "add dispatcher message -" do
    test "valid", %{d_socket: d_socket, o_socket: o_socket, asset: %{id: asset_id}} do
      topic = "add dispatcher message"

      payload = %{
        "message" => "Test message",
        "asset_id" => asset_id,
        "answers" => [],
        "timestamp" => unix_now()
      }

      ref = push(d_socket, topic, payload)
      assert_reply(ref, :ok)

      assert_broadcast_receive(d_socket, "set dispatcher messages", %{
        messages: [_]
      })

      assert_broadcast_receive(o_socket, "set dispatcher messages", %{
        messages: [_]
      })
    end

    test "invalid (missing keys)", %{d_socket: d_socket, asset: %{id: asset_id}} do
      topic = "add dispatcher message"

      payload = %{
        "asset_id" => asset_id,
        "timestamp" => unix_now()
      }

      ref = push(d_socket, topic, payload)
      expected_error = %{error: "message - can't be blank"}
      assert_reply(ref, :error, ^expected_error)
    end
  end

  describe "add mass dispatcher message -" do
    test "valid", %{d_socket: d_socket, o_socket: o_socket, asset: %{id: asset_id}} do
      topic = "add mass dispatcher message"

      payload = %{
        "asset_ids" => [asset_id],
        "message" => "Test message",
        "timestamp" => unix_now()
      }

      ref = push(d_socket, topic, payload)
      assert_reply(ref, :ok)

      assert_broadcast_receive(d_socket, "set dispatcher messages", %{
        messages: [_]
      })

      assert_broadcast_receive(o_socket, "set dispatcher messages", %{
        messages: [_]
      })
    end

    test "invalid (missing keys)", %{d_socket: d_socket} do
      topic = "add mass dispatcher message"

      payload = %{
        "asset_ids" => [],
        "message" => "Test message",
        "timestamp" => unix_now()
      }

      ref = push(d_socket, topic, payload)
      assert_reply(ref, :error, %{error: :invalid_asset_ids})
    end
  end

  describe "set assigned asset -" do
    test "valid (change asset)", %{d_socket: d_socket, o_socket: o_socket} = context do
      topic = "set assigned asset"

      # changing assigned asset for the device on o_socket
      payload = %{
        "device_id" => context.device.id,
        "asset_id" => context.asset_b.id,
        "timestamp" => unix_now()
      }

      ref = push(d_socket, topic, payload)
      assert_reply(ref, :ok)

      assert_broadcast_receive(d_socket, "set device assignments", %{historic: _, current: [_, _]})

      assert_broadcast_receive(o_socket, "force logout")
    end

    test "valid (unassign device from asset)",
         %{d_socket: d_socket, o_socket: o_socket} = context do
      topic = "set assigned asset"

      payload = %{
        "device_id" => context.device.id,
        "asset_id" => nil,
        "timestamp" => unix_now()
      }

      ref = push(d_socket, topic, payload)
      assert_reply(ref, :ok)

      assert_broadcast_receive(d_socket, "set device assignments")

      assert_broadcast_receive(o_socket, "force logout")
    end

    test "invalid (invalid asset)", %{d_socket: d_socket, device: device} do
      topic = "set assigned asset"

      payload = %{
        "device_id" => device.id,
        "asset_id" => -1,
        "timestamp" => unix_now()
      }

      ref = push(d_socket, topic, payload)
      assert_reply(ref, :error, %{error: :invalid_asset_id})
    end

    test "invalid (invalid device)", %{d_socket: d_socket, asset: asset} do
      topic = "set assigned asset"

      payload = %{
        "device_id" => -1,
        "asset_id" => asset.id,
        "timestamp" => unix_now()
      }

      ref = push(d_socket, topic, payload)
      assert_reply(ref, :error, %{error: :invalid_device_id})
    end
  end
end
