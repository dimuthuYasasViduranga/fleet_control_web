defmodule FleetControlWeb.DispatcherChannel.Topics.Track do
  alias FleetControl.{Helper, Tracks, TrackAgent}
  alias FleetControlWeb.{Settings, Broadcast}
  use HpsPhx.Authorization.Decorator

  import FleetControlWeb.DispatcherChannel, only: [to_error: 1]

  require Logger

  quote do
    if Mix.env() == :dev do
      def handle_in("set mode", mode, socket) when mode in ["mock", "normal"] do
        TrackAgent.set_mode(String.to_existing_atom(mode))
        {:reply, :ok, socket}
      end

      def handle_in("set track", track, socket) do
        track
        |> parse_mock_track()
        |> Tracks.add_info()
        |> TrackAgent.add(:mock)
        |> case do
          {:ok, new_track} -> Broadcast.send_track(new_track)
          _ -> Logger.info("Mock track ignored")
        end

        {:noreply, socket}
      end

      defp parse_mock_track(track) do
        pos = track["position"]

        %{
          name: track["name"],
          user_id: track["user_id"],
          position: %{
            lat: pos["lat"],
            lng: pos["lng"],
            alt: pos["alt"]
          },
          speed_ms: track["speed_ms"],
          heading: track["heading"],
          ignition: true,
          valid: Map.get(track, "valid", true),
          timestamp: Helper.to_naive(track["timestamp"])
        }
      end
    end
  end

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
