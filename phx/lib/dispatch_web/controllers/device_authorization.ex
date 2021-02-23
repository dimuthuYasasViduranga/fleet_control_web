defmodule DispatchWeb.DeviceAuthController do
  @moduledoc """
  Authorization for devices
  """

  use DispatchWeb, :controller

  require Logger

  alias AzureADOpenId

  alias Dispatch.DeviceAuthServer

  def request_device_auth(conn, %{"device_uuid" => device_uuid} = params) do
    case DeviceAuthServer.request_device_authorization(device_uuid, params["details"] || %{}) do
      :closed ->
        send_resp(conn, 401, "closed")

      :ok ->
        socket_token = Phoenix.Token.sign(conn, "device_auth", device_uuid)
        send_resp(conn, 200, socket_token)
    end
  end
end
