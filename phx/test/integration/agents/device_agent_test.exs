defmodule Dispatch.DeviceAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.DeviceAgent
  alias HpsData.Schemas.Dispatch.Device

  setup _ do
    DeviceAgent.start_link([])
    :ok
  end

  describe "Add device -" do
    test "valid (add device)" do
      uuid = "abcdefg"
      {:ok, :new, device} = DeviceAgent.add(uuid)

      # return
      assert device.uuid == uuid
      assert is_nil(device.not_before)

      # state
      assert DeviceAgent.all() == [device]

      # database
      assert_db_contains(Device, device)
    end

    test "valid (add device that already exists)" do
      uuid = "abcdefg"
      DeviceAgent.add(uuid)
      {:ok, :exists, device} = DeviceAgent.add(uuid)

      # return
      assert device.uuid == uuid

      # state
      assert DeviceAgent.all() == [device]

      # database
      assert_db_contains(Device, device)
    end

    test "valid (update device details)" do
      uuid = "abcdefg"
      {:ok, :new, initial} = DeviceAgent.add(uuid)
      {:ok, :exists, actual} = DeviceAgent.add(uuid, %{"model" => 7})

      # return
      assert actual.uuid == initial.uuid
      assert actual.uuid == uuid
      assert actual.details == %{"model" => 7}

      # state
      assert DeviceAgent.all() == [actual]

      # database
      assert_db_contains(Device, actual)
      refute_db_contains(Device, initial)
    end

    test "valid (prevent details override to null)" do
      uuid = "abcdefg"
      serial = "123456"
      {:ok, :new, initial} = DeviceAgent.add(uuid, %{"serial" => serial})
      {:ok, :exists, actual} = DeviceAgent.add(uuid, %{"serial" => nil, "new_val" => 25})

      # return
      assert initial.details["serial"] == serial
      assert actual.details["serial"] == serial
      assert actual.details["new_val"] == 25

      # state
      assert DeviceAgent.all() == [actual]

      # database
      assert_db_contains(Device, actual)
      refute_db_contains(Device, initial)
    end

    test "invalid (no uuid)" do
      actual = DeviceAgent.add(nil)
      assert actual == {:error, :invalid_uuid}
    end
  end

  describe "update nbf -" do
    test "valid (valid device)" do
      uuid = "abcdefg"
      not_before = 1000

      {:ok, _, initial} = DeviceAgent.add(uuid)
      {:ok, actual} = DeviceAgent.update_nbf(initial.id, %{"nbf" => not_before})

      # return
      assert actual.uuid == uuid
      assert actual.not_before == not_before

      # state
      assert DeviceAgent.all() == [actual]

      # database
      assert_db_contains(Device, actual)
      refute_db_contains(Device, initial)
    end

    test "invalid (set nbf to nil)" do
      {:ok, _, device} = DeviceAgent.add("abcdefg")

      actual = DeviceAgent.update_nbf(device.id, %{"nbf" => nil})

      assert actual == {:error, :invalid_nbf}
    end

    test "invalid (invalid device)" do
      actual = DeviceAgent.update_nbf(-1, %{"nbf" => 100})
      assert actual == {:error, :invalid_device_id}
    end

    test "invalid (invalid claims)" do
      actual = DeviceAgent.update_nbf(-1, %{})
      assert actual == {:error, :missing_nbf}
    end
  end

  describe "revoke device -" do
    test "valid (device that exists)" do
      uuid = "abcdefg"
      {:ok, _, initial} = DeviceAgent.add(uuid)
      {:ok, initial} = DeviceAgent.update_nbf(initial.id, %{"nbf" => 100})

      {:ok, actual} = DeviceAgent.revoke(initial.id)

      # return
      assert initial.not_before != nil
      assert actual.uuid == uuid
      assert actual.not_before == nil

      # store
      assert DeviceAgent.all() == [actual]

      # database
      assert_db_contains(Device, actual)
      refute_db_contains(Device, initial)
    end

    test "invalid (device that does not exist)" do
      actual = DeviceAgent.revoke(-1)
      assert actual == {:error, :invalid_device_id}
    end
  end

  describe "update details -" do
    test "valid (new details)" do
      details = %{"model" => "a"}
      {:ok, _, initial} = DeviceAgent.add("abcdef")
      {:ok, actual} = DeviceAgent.update_details(initial.id, details)

      # return
      assert actual.details == details

      # store
      assert DeviceAgent.all() == [actual]

      # database
      assert_db_contains(Device, actual)
      refute_db_contains(Device, initial)
    end

    test "valid (override details)" do
      details = %{"model" => "a"}
      {:ok, _, initial} = DeviceAgent.add("abcdef", %{"model" => "b"})
      {:ok, actual} = DeviceAgent.update_details(initial.id, details)
      # return
      assert actual.details == details

      # store
      assert DeviceAgent.all() == [actual]

      # database
      assert_db_contains(Device, actual)
      refute_db_contains(Device, initial)
    end

    test "invalid (invalid details)" do
      {:ok, _, device} = DeviceAgent.add("abcdef")
      actual = DeviceAgent.update_details(device.id, [])
      assert actual == {:error, :invalid_details}
    end

    test "invalid (device id)" do
      actual = DeviceAgent.update_details(-1, %{})
      assert actual == {:error, :invalid_id}
    end
  end

  test "safe get all devices" do
    DeviceAgent.add("abcdefg")
    [device] = DeviceAgent.safe_all()

    assert device[:not_before] == nil
  end
end
