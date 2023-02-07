defmodule FleetControlWeb.PageController do
  @moduledoc nil

  use FleetControlWeb, :controller

  alias FleetControlWeb.Authorization
  alias FleetControlWeb.Guardian
  alias FleetControl.DispatcherAgent

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
    {conn, token} = get_token(conn)

    task =
      Task.async(fn ->
        user = get_session(conn, :current_user)
        whitelist = Authorization.Whitelist.get(user[:user_id])

        data = %{
          data: FleetControl.StaticData.fetch(),
          whitelist: whitelist,
          user_token: token,
          user: user,
          authorized: true
        }

        data |> Jason.encode!()
      end)

    payload = Task.await(task)

    conn
    |> assign(:user_token, token)
    |> send_resp(200, payload)
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
    case Application.get_env(:fleet_control_web, :bypass_auth, false) do
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
