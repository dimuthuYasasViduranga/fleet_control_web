defmodule DispatchWeb.PageController do
  @moduledoc nil

  use DispatchWeb, :controller

  alias DispatchWeb.{Settings, Authorization, Guardian}
  alias Dispatch.DispatcherAgent

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def index(conn, _) do
    {conn, user} = get_user(conn)

    case user do
      nil -> redirect(conn, to: "/fleet-control/auth/login")
      _ -> redirect(conn, to: "/fleet-control/index.html")
    end
  end

  @spec static_data(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def static_data(conn, _) do
    user = get_session(conn, :current_user)

    authorized = Map.get(conn.assigns.permissions, :authorized, false)

    {conn, token} = get_token(conn)

    whitelist = get_whitelist(user[:user_id])

    data = %{
      data: Dispatch.StaticData.fetch(),
      whitelist: whitelist,
      user_token: token,
      user: user,
      authorized: authorized
    }

    conn
    |> assign(:user_token, token)
    |> json(data)
  end

  defp get_whitelist(user_id) do
    whitelist = Authorization.Whitelist.get(user_id)

    # TODO this is very counter intuitive and too much config
    if Settings.get(:use_pre_starts) == true do
      whitelist
    else
      Enum.reject(whitelist, &(&1 == "/pre_start_editor" || &1 == "/pre_start_submissions"))
    end
  end

  defp get_token(conn) do
    case get_user(conn) do
      {conn, nil} ->
        {conn, nil}

      {conn, user} ->
        data = Map.take(user, [:id, :user_id])
        token = Phoenix.Token.sign(conn, "user socket", data)
        {conn, token}
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
end
