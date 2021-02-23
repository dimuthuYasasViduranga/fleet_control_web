defmodule DispatchWeb.Authorization.Conn do
  alias DispatchWeb.Authorization.AzureGraph

  defp whitelist_config(), do: Application.get_env(:dispatch_web, :route_white_list, %{})

  defp default_whitelist(), do: whitelist_config()[:default] || []

  def get_whitelist(conn) do
    case Plug.Conn.get_session(conn, :current_user) do
      %{user_id: user_id} ->
        user_id
        |> AzureGraph.group_ids()
        |> get_first_whitelist()

      _ ->
        default_whitelist()
    end
  end

  defp get_first_whitelist(nil), do: default_whitelist()

  defp get_first_whitelist(group_ids) do
    config = whitelist_config()

    Enum.reduce_while(group_ids, default_whitelist(), fn group, acc ->
      case config[group] do
        nil -> {:cont, acc}
        whitelist -> {:halt, whitelist}
      end
    end)
  end
end
