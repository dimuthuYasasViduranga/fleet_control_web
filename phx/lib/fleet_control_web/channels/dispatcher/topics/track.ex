defmodule FleetControlWeb.DispatcherChannel.Topics.Track do
  alias FleetControl.{Helper, Tracks, TrackAgent}
  alias FleetControlWeb.{Settings, Broadcast}
  use HpsPhx.Authorization.Decorator

  import FleetControlWeb.DispatcherChannel, only: [to_error: 1]

  require Logger

  def handle_in("set mode", mode, socket) do
    Logger.error("Track agent cannot be set to mode '#{mode}'")
    {:reply, to_error("invalid mode"), socket}
  end

  @decorate authorized_channel("fleet_control_refresh_agents")
  def handle_in("set use device gps", %{"state" => bool}, socket)
      when is_boolean(bool) do
    Settings.set(:use_device_gps, bool)
    Broadcast.send_settings_to_all()
    {:reply, {:ok, bool}, socket}
  end
end
