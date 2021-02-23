defmodule DispatchWeb.DeviceAuthChannel do
  @moduledoc false

  use DispatchWeb, :channel

  alias Phoenix.Socket

  @type topic :: String.t()

  @spec join(topic, any(), Socket.t()) :: {:ok, Socket.t()}
  def join("device_auth:" <> _device_uuid, _params, socket) do
    {:ok, socket}
  end
end
