defmodule FleetControlWeb.DispatcherSocket do
  @moduledoc nil

  use Phoenix.Socket

  # 2 weeks in seconds
  @max_age 14 * 24 * 3600

  channel "dispatchers:all", FleetControlWeb.DispatcherChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: @max_age) do
      {:ok, user} -> {:ok, assign(socket, :current_user, user)}
      _ -> :error
    end
  end

  def id(socket), do: "dispatcher:#{socket.assigns.current_user.user_id}"
end
