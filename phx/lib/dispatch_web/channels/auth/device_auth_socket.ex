defmodule DispatchWeb.DeviceAuthSocket do
  @moduledoc false

  use Phoenix.Socket
  @max_age 300

  channel "device_auth:*", DispatchWeb.DeviceAuthChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    Phoenix.Token.verify(socket, "device_auth", token, max_age: @max_age)
    |> case do
      {:ok, device_uuid} ->
        socket = assign(socket, :device_uuid, device_uuid)
        {:ok, socket}

      {:error, _reason} ->
        :error
    end
  end

  def id(socket), do: "device_auth:#{socket.assigns.device_uuid}"
end
