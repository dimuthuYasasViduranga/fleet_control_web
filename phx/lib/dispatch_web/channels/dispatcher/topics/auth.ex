defmodule DispatchWeb.DispatcherChannel.AuthTopics do
  @moduledoc """
  Holds the auth specific topics to make the dispatcher channel cleaner
  """

  alias Dispatch.{Helper, DeviceAuthServer, DeviceAssignmentAgent, DeviceAgent}
  alias DispatchWeb.Broadcast

  def handle_in("auth:open device window", _, socket) do
    accept_until = DeviceAuthServer.open_auth_window()
    Broadcast.Authentication.send_pending_devices()
    {:reply, {:ok, %{accept_until: accept_until}}, socket}
  end

  def handle_in("auth:close device window", _, socket) do
    DeviceAuthServer.close_auth_window()
    Broadcast.Authentication.send_pending_devices()
    {:reply, :ok, socket}
  end

  def handle_in("auth:accept device", device_uuid, socket) do
    case DeviceAuthServer.accept_device(device_uuid) do
      {:error, _reason} ->
        Broadcast.send_activity(%{uuid: device_uuid}, "dispatcher", "failed to accept device")
        {:noreply, socket}

      {:ok, token} ->
        Broadcast.send_activity(%{uuid: device_uuid}, "dispatcher", "device accepted")
        Broadcast.Authentication.send_device_token(device_uuid, token)
        Broadcast.Authentication.send_pending_devices()
        Broadcast.send_devices_to_dispatcher()
        Broadcast.send_assignments_to_all()
        {:reply, :ok, socket}
    end
  end

  def handle_in("auth:reject device", device_uuid, socket) do
    Broadcast.send_activity(%{uuid: device_uuid}, "dispatcher", "device rejected")
    DeviceAuthServer.reject_device(device_uuid)
    Broadcast.Authentication.send_pending_devices()
    {:reply, :ok, socket}
  end

  def handle_in("auth:reject all", _, socket) do
    DeviceAuthServer.reject_all()
    Broadcast.Authentication.send_pending_devices()
    {:reply, :ok, socket}
  end

  def handle_in("auth:revoke device", device_id, socket) do
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
