defmodule DispatchWeb.Broadcast.Authentication do
  @moduledoc """
  All broadcasts related to device authorization/manipulation
  """
  alias DispatchWeb.Endpoint

  alias Dispatch.DeviceAuthServer

  def disconnect(device_uuid) do
    Endpoint.broadcast("device_auth:#{device_uuid}", "disconnect", %{})
  end

  def send_pending_devices() do
    {devices, accept_until} = DeviceAuthServer.get()
    send_pending_devices(devices, accept_until)
  end

  def send_pending_devices(devices, accept_until) do
    msg = %{devices: devices, accept_until: accept_until}
    Endpoint.broadcast("dispatchers:all", "set pending devices", msg)
  end

  def send_device_token(device_uuid, token) do
    Endpoint.broadcast("device_auth:#{device_uuid}", "set device token", %{token: token})
  end
end
