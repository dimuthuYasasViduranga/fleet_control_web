defmodule FleetControlWeb.OperatorSocket do
  @moduledoc nil

  use Phoenix.Socket
  # 2 weeks in seconds
  @max_age 14 * 24 * 3600

  channel "operators:*", FleetControlWeb.OperatorChannel

  def connect(%{"operator_token" => operator_token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "operator socket", operator_token, max_age: @max_age) do
      {:ok, {device_id, device_uuid, operator_id}} ->
        socket =
          socket
          |> assign(:operator_id, operator_id)
          |> assign(:device_uuid, device_uuid)
          |> assign(:device_id, device_id)

        {:ok, socket}

      _ ->
        :error
    end
  end

  def id(_socket), do: nil
end
