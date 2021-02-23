defmodule DispatchWeb.DispatcherSocket do
  @moduledoc nil

  use Phoenix.Socket
  alias DispatchWeb.Authorization

  # 2 weeks in seconds
  @max_age 14 * 24 * 3600

  channel "dispatchers:all", DispatchWeb.DispatcherChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: @max_age) do
      {:ok, user} ->
        permissions = get_permissions(user[:user_id])
        socket = assign(socket, :auth_permissions, permissions)
        {:ok, assign(socket, :current_user, user)}

      _ ->
        :error
    end
  end

  def id(_socket), do: nil

  defp get_permissions(user_id) do
    case Application.get_env(:dispatch_web, :bypass_auth, false) do
      true -> bypass_permissions()
      _ -> Authorization.Socket.get_permissions(user_id)
    end
  end

  defp bypass_permissions() do
    Authorization.Socket.default_permissions()
    |> Enum.map(fn {permission, _} -> {permission, true} end)
    |> Enum.into(%{})
  end
end
