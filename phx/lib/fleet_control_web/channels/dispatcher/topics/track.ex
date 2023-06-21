defmodule FleetControlWeb.DispatcherChannel.Topics.Track do
  alias FleetControlWeb.{Settings, Broadcast}
  use HpsPhx.Authorization.Decorator

  require Logger

  @decorate authorized_channel("fleet_control_refresh_agents")
  def handle_in("set use device gps", %{"state" => bool}, socket)
      when is_boolean(bool) do
    Settings.set(:use_device_gps, bool)
    Broadcast.send_settings_to_all()
    {:reply, {:ok, bool}, socket}
  end
end
