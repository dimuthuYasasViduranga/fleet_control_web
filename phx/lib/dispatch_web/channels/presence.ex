defmodule DispatchWeb.Presence do
  @moduledoc """
  See the documentation at:
  https://hexdocs.pm/phoenix/Phoenix.Presence.html
  """

  use Phoenix.Presence,
    otp_app: :dispatch_web,
    pubsub_server: DispatchWeb.PubSub
end
