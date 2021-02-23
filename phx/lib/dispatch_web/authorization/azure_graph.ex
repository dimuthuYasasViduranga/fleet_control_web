defmodule DispatchWeb.Authorization.AzureGraph do
  alias OAuth2.Client
  alias OAuth2.Strategy.ClientCredentials

  @type user_id :: any()

  @spec group_ids(user_id) :: list(integer)
  def group_ids(nil), do: []

  def group_ids(user_id) do
    user_id
    |> groups()
    |> Enum.map(& &1["id"])
  end

  @spec groups(user_id) :: list(map)
  def groups(nil), do: []

  def groups(user_id) do
    "https://graph.microsoft.com/v1.0/users/#{user_id}/transitiveMemberOf"
    |> http_get()
    |> case do
      {:ok, body} ->
        body
        |> Map.get("value")
        |> Enum.map(&Map.take(&1, ["displayName", "description", "id"]))

      _ ->
        []
    end
  end

  defp http_get(url), do: http_get(url, get_token())

  defp http_get(url, {:ok, token}) do
    HTTPoison.get(url, Authorization: token)
    |> case do
      {:ok, %{status_code: 200, body: body}} -> Jason.decode(body)
      error -> error
    end
  end

  defp http_get(_, _), do: {:error, :invalid_token}

  defp get_token() do
    config = Application.get_env(:azure_ad_openid, AzureADOpenId)
    tenant = config[:tenant]
    client_id = config[:client_id]
    client_secret = config[:client_secret]

    client =
      Client.new(
        strategy: ClientCredentials,
        client_id: client_id,
        client_secret: client_secret,
        site: "https://login.microsoftonline.com/#{tenant}",
        token_url: "/oauth2/token",
        authorize_url: "/oauth2/authorize",
        params: %{
          resource: "https://graph.microsoft.com"
        }
      )

    case Client.get_token(client) do
      {:ok, %{token: %{access_token: token}}} -> {:ok, parse_token(token)}
      error -> error
    end
  end

  defp parse_token(token) do
    case Jason.decode(token) do
      {:ok, %{"access_token" => access_token}} -> access_token
      _ -> token
    end
  end
end
