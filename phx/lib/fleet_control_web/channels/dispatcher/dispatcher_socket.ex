defmodule FleetControlWeb.DispatcherSocket do
  @moduledoc nil

  use Phoenix.Socket
  alias FleetControlWeb.Authorization.Permissions

  # 2 weeks in seconds
  @max_age 14 * 24 * 3600

  channel "dispatchers:all", FleetControlWeb.DispatcherChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: @max_age) do
      {:ok, user} ->
        permissions = get_permissions(user[:user_id])

        socket =
          socket
          |> assign(:permissions, permissions)
          |> assign(:current_user, user)

        {:ok, socket}

      _ ->
        :error
    end
  end

  def id(socket), do: "dispatcher:#{socket.assigns.current_user.user_id}"

  defp get_permissions(user_id) do
    case Application.get_env(:dispatch_web, :bypass_auth, false) do
      true -> Permissions.full_permissions()
      _ -> Permissions.fetch_permissions(user_id)
    end
  end
end
