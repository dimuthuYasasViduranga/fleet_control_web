defmodule FleetControlWeb.Presence do
  @moduledoc """
  See the documentation at:
  https://hexdocs.pm/phoenix/Phoenix.Presence.html
  """

  use Phoenix.Presence,
    otp_app: :fleet_control_web,
    pubsub_server: FleetControlWeb.PubSub
end
