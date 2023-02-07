defmodule FleetControlWeb.Authorization.Plug.LoadAuthPermissions do
  import Plug.Conn

  alias FleetControlWeb.Authorization.Permissions

  def init(options), do: options

  def call(conn, opts) do
    permissions =
      conn
      |> get_session(:current_user)
      |> Map.get(:user_id)
      |> Permissions.fetch_permissions()

    assign(conn, :permissions, permissions)
  end
end
