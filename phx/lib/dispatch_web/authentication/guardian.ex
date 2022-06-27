defmodule FleetControlWeb.Guardian do
  @moduledoc nil

  use Guardian, otp_app: :dispatch_web

  require Logger

  def subject_for_token(%{id: id}, _claims) do
    sub = to_string(id)
    {:ok, sub}
  end

  def subject_for_token(_, _) do
    Logger.error("subject_for_token error")
    {:error, :reason_for_error}
  end

  def resource_from_claims(%{"sub" => sub}) do
    {:ok, %{id: sub}}
  end

  def resource_from_claims(claims) do
    Logger.error(inspect(claims))
    {:error, :not_implemented}
  end
end
