defmodule DispatchWeb.Authorization.Plug.EnsureAuthorized do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> Map.get(:assigns, %{})
    |> Map.get(:permissions, %{})
    |> Map.get(:authorized, false)
    |> case do
      true ->
        conn

      _ ->
        body = Jason.encode!(%{message: "Unauthorized"})

        conn
        |> send_resp(401, body)
        |> halt()
    end
  end
end
