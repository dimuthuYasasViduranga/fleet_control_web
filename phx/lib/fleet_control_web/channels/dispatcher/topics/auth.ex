defmodule FleetControlWeb.DispatcherChannel.Topics.Auth do
  @moduledoc """
  Holds the auth specific topics to make the dispatcher channel cleaner
  """

  alias FleetControl.{Helper, DeviceAuthServer, DeviceAssignmentAgent, DeviceAgent}
  alias FleetControlWeb.Broadcast

  def handle_in("open device window", _, socket) do
    accept_until = DeviceAuthServer.open_auth_window()
    Broadcast.Authentication.send_pending_devices()
    {:reply, {:ok, %{accept_until: accept_until}}, socket}
  end

  def handle_in("close device window", _, socket) do
    DeviceAuthServer.close_auth_window()
    Broadcast.Authentication.send_pending_devices()
    {:reply, :ok, socket}
  end

  def handle_in("accept device", device_uuid, socket) do
    case DeviceAuthServer.accept_device(device_uuid) do
      {:ok, token} ->
        Broadcast.send_activity(%{uuid: device_uuid}, "dispatcher", "device accepted")
        Broadcast.Authentication.send_device_token(device_uuid, token)
        Broadcast.Authentication.send_pending_devices()
        Broadcast.send_devices_to_dispatcher()
        Broadcast.send_assignments_to_all()
        {:reply, :ok, socket}

      {:error, _reason} ->
        Broadcast.send_activity(%{uuid: device_uuid}, "dispatcher", "failed to accept device")
        {:noreply, socket}
    end
  end

  def handle_in("reject device", device_uuid, socket) do
    Broadcast.send_activity(%{uuid: device_uuid}, "dispatcher", "device rejected")
    DeviceAuthServer.reject_device(device_uuid)
    Broadcast.Authentication.send_pending_devices()
    {:reply, :ok, socket}
  end

  def handle_in("reject all", _, socket) do
    DeviceAuthServer.reject_all()
    Broadcast.Authentication.send_pending_devices()
    {:reply, :ok, socket}
  end

  def handle_in("revoke device", device_id, socket) do
    case DeviceAssignmentAgent.get_asset_id(%{device_id: device_id}) do
      nil ->
        Broadcast.send_activity(%{device_id: device_id}, "dispatcher", "device revoked")
        DeviceAgent.revoke(device_id)

        # log the device out if not already, and revoke token
        Broadcast.force_logout(%{device_id: device_id}, %{
          revoke: true,
          clear_operator: true
        })

        Broadcast.send_devices_to_dispatcher()

      asset_id ->
        Broadcast.send_activity(
          %{device_id: device_id},
          "dispatcher",
          "device with assignment revoked"
        )

        DeviceAssignmentAgent.change(asset_id, %{
          device_id: nil,
          timestamp: Helper.naive_timestamp()
        })

        DeviceAgent.revoke(device_id)

        # log the device out if not already, and revoke token
        Broadcast.force_logout(%{device_id: device_id}, %{
          revoke: true,
          clear_operator: true
        })

        Broadcast.send_devices_to_dispatcher()
        Broadcast.send_assignments_to_all()
    end

    {:noreply, socket}
  end
end
