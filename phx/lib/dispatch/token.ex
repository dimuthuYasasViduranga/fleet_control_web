defmodule Dispatch.Token do
  use Joken.Config

  require Logger
  alias Dispatch.DeviceAgent

  @type bearer_token :: binary
  @type error_reason :: atom | Keyword.t()
  @type claims :: %{binary => term}
  @type device_uuid :: String.t()

  @impl Joken.Config
  def token_config do
    default_claims(skip: [:aud, :exp, :jti])
  end

  @spec generate_token(device_uuid) :: {:ok, bearer_token(), claims()} | {:error, error_reason()}
  def generate_token(device_uuid) do
    extra_claims = %{"device_uuid" => device_uuid}
    generate_and_sign(extra_claims)
  end

  @spec generate_token!(device_uuid) :: bearer_token() | no_return()
  def generate_token!(device_uuid) do
    {:ok, token, _claims} = generate_token(device_uuid)
    token
  end

  @spec validate_token(device_uuid, bearer_token()) :: :ok | {:error, error_reason()}
  def validate_token(device_uuid, token) when is_binary(token) do
    with {:ok, claims} <- verify_and_validate(token),
         :ok <- verify_device_claim(claims, device_uuid),
         :ok <- verify_nbf(claims) do
      :ok
    else
      {:error, error} ->
        Logger.warn(inspect(error))
        {:error, error}
    end
  end

  def validate_token(_device_uuid, _invalid_token) do
    {:error, :token_not_string}
  end

  @spec validate_token(device_uuid, bearer_token()) :: no_return()
  def validate_token!(device_uuid, token) do
    :ok = validate_token(device_uuid, token)
    nil
  end

  defp verify_device_claim(claims, device_uuid) do
    case claims["device_uuid"] == device_uuid do
      true -> :ok
      false -> {:error, :invalid_device_uuid}
    end
  end

  defp verify_nbf(%{"iat" => iat, "nbf" => nbf, "device_uuid" => device_uuid}) do
    case DeviceAgent.valid_nbf?(device_uuid, nbf, iat) do
      true -> :ok
      false -> {:error, :invalid_nbf}
    end
  end

  defp verify_nbf(_), do: {:error, :missing_claims}
end
