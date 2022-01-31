defmodule DispatchWeb.DispatcherChannel.TrackTopics do
  alias Dispatch.{Helper, Tracks, TrackAgent}
  use DispatchWeb.Authorization.Decorator
  alias DispatchWeb.{Settings, Broadcast}

  import DispatchWeb.DispatcherChannel, only: [to_error: 1]

  require Logger

  def handle_in(topic, payload, socket) do
    case topic do
      "track:set mode" -> track_set_mode(topic, payload, socket)
      "track:set track" -> set_track(topic, payload, socket)
      "track:set use device gps" -> set_use_device_gps(topic, payload, socket)
    end
  end

  @decorate only_in(:dev)
  defp track_set_mode("track:set mode", mode, socket) when mode in ["mock", "normal"] do
    TrackAgent.set_mode(String.to_existing_atom(mode))
    {:reply, :ok, socket}
  end

  defp track_set_mode("track:set mode", mode, socket) do
    Logger.error("Track agent cannot be set to mode '#{mode}'")
    {:reply, to_error("invalid mode"), socket}
  end

  @decorate only_in(:dev)
  defp set_track("track:set track", track, socket) do
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

  @decorate authorized(:can_refresh_agents)
  def set_use_device_gps("track:set use device gps", %{"state" => bool}, socket)
      when is_boolean(bool) do
    Settings.set(:use_device_gps, bool)
    Broadcast.send_settings_to_all()
    {:reply, {:ok, bool}, socket}
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
