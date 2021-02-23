defmodule DispatchWeb.AuthController do
  @moduledoc """
  Authentication endpoint functions.
  """

  use DispatchWeb, :controller

  require Logger

  alias AzureADOpenId
  alias Dispatch.{Token, OperatorAgent, DeviceAgent, DispatcherAgent}

  alias DispatchWeb.Broadcast
  alias DispatchWeb.Guardian

  @doc """
  Dispatcher login
  """
  @spec login(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def login(conn, _) do
    base_uri = Application.get_env(:dispatch_web, :url)
    redirect_uri = "#{base_uri}/auth/callback"
    redirect(conn, external: AzureADOpenId.authorize_url!(redirect_uri))
  end

  @doc """
  Dispatcher login callback
  """
  @spec callback(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def callback(conn, _) do
    case AzureADOpenId.handle_callback!(conn) do
      {:ok, jwt} ->
        name = AzureADOpenId.get_user_name(jwt)

        user =
          case DispatcherAgent.add(jwt[:oid], name) do
            {:ok, user} ->
              Broadcast.send_dispatchers()
              user

            _ ->
              %{id: nil, user_id: jwt[:oid], name: name}
          end

        conn
        |> put_session(:current_user, user)
        |> Guardian.Plug.sign_in(user)

      {:error, error_type, error} ->
        Logger.warn("[Auth] #{error_type}: #{error}")
        conn
    end
    |> redirect(to: "/")
  end

  @doc """
  Dispatcher logout
  """
  @spec logout(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def logout(conn, _) do
    logout_url =
      Application.get_env(:dispatch_web, :url)
      |> get_logout_redirect()

    conn
    |> put_session(:current_user, nil)
    |> assign(:user_token, nil)
    |> Guardian.Plug.sign_out()
    |> redirect(external: logout_url)
  end

  defp get_logout_redirect(base_uri) do
    AzureADOpenId.logout_url() <> "&post_logout_redirect_uri=#{base_uri}"
  end

  @doc """
  Operator login
  """
  @spec operator_login(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def operator_login(conn, %{
        "employee_id" => employee_id,
        "device_uuid" => device_uuid,
        "device_token" => token
      }) do
    with :ok <- Token.validate_token(device_uuid, token),
         %{id: operator_id, deleted: false} <- OperatorAgent.get(:employee_id, employee_id) do
      %{id: device_id} = DeviceAgent.get(%{uuid: device_uuid})

      token = Phoenix.Token.sign(conn, "operator socket", {device_id, device_uuid, operator_id})

      data = Jason.encode!(%{token: token})

      send_resp(conn, 200, data)
    else
      false ->
        error_reply(conn, 401, "Invalid Employee ID")

      %{deleted: true} ->
        error_reply(conn, 403, "Operator Unauthorized. Please Contact Controller")

      _error ->
        error_reply(conn, 403, "Unauthorized Device")
    end
  end

  def operator_login(conn, _payload) do
    error_reply(conn, 400, "Invalid parameters received")
  end

  defp error_reply(conn, code, reason) do
    data = Jason.encode!(%{error: reason})
    send_resp(conn, code, data)
  end
end