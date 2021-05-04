defmodule DispatchWeb.AuthErrorHandler do
  @moduledoc nil

  import Plug.Conn
  require Logger

  def auth_error(conn, {type, reason}, _opts) do
    body = Poison.encode!(%{message: to_string(type)})
    Logger.warn("Auth Error: {type: #{type}, reason: #{reason}}")

    conn
    |> get_cookies()
    |> Enum.reduce(conn, &delete_cookie/2)
    |> clear_session
    |> print_cookies
    |> send_resp(401, body)
  end

  defp delete_cookie(cookie, conn) do
    delete_resp_cookie(conn, cookie)
  end

  defp get_cookies(conn) do
    conn
    |> Map.get(:cookies)
    |> Map.keys()
  end

  defp print_cookies(conn) do
    cookies = get_cookies(conn)

    if Enum.count(cookies) > 0 do
      Logger.error("Unauthorised user's cookies: #{cookies}")
    end

    conn
  end
end
