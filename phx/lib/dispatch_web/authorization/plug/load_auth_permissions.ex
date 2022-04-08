defmodule DispatchWeb.Authorization.Plug.LoadAuthPermissions do
  import Plug.Conn

  alias DispatchWeb.Authorization.Permissions

  def init(options), do: options

  def call(conn, opts) do
    permissions =
      case opts[:full_access] do
        true ->
          Permissions.full_permissions()

        _ ->
          conn
          |> get_session(:current_user)
          |> Map.get(:user_id)
          |> Permissions.fetch_permissions()
      end

    assign(conn, :permissions, permissions)
  end
end
