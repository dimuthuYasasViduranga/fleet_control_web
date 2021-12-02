defmodule DispatchWeb.PageController do
  @moduledoc nil

  use DispatchWeb, :controller

  alias DispatchWeb.{Authorization, Guardian}
  alias Dispatch.DispatcherAgent

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def index(conn, _) do
    {conn, user} = get_user(conn)

    case user do
      nil -> redirect(conn, to: "/auth/login")
      _ -> redirect(conn, to: "/index.html")
    end
  end

  defp get_user(conn) do
    case Application.get_env(:dispatch_web, :bypass_auth, false) do
      true ->
        {:ok, user} = DispatcherAgent.add(nil, "dev")

        conn =
          conn
          |> put_session(:current_user, user)
          |> Guardian.Plug.sign_in(user)

        {conn, user}

      _ ->
        user = get_session(conn, :current_user)
        {conn, user}
    end
  end

  @spec user_info(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def user_info(conn, _) do
    name = get_session(conn, :current_user)[:name]

    case name do
      nil -> text(conn, "")
      _ -> text(conn, name)
    end
  end

  @spec get_whitelist(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def get_whitelist(conn, _) do
    whitelist =
      conn
      |> Authorization.Conn.get_whitelist()
      |> Jason.encode!()

    send_resp(conn, 200, whitelist)
  end

  @spec static_data(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def static_data(conn, _) do
    {conn, token} = get_token(conn)

    static_data =
      Dispatch.StaticData.fetch()
      |> Map.put(:user_token, token)
      |> Jason.encode!()

    conn
    |> assign(:user_token, token)
    |> text(static_data)
  end

  defp get_token(conn) do
    {conn, user} = get_user(conn)

    case user do
      nil ->
        {conn, nil}

      data ->
        user = Map.take(data, [:id, :user_id])
        token = Phoenix.Token.sign(conn, "user socket", user)
        {conn, token}
    end
  end
end
