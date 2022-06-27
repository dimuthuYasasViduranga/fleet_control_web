defmodule TrackSub.Rest do
  @doc """
  Returns a list of latest track points for all assets
  """
  @spec get_latest_tracks() :: {:ok, list()} | {:error, integer, GPSGateRest.Status}
  def get_latest_tracks() do
    case GPSGateRest.get_users() do
      {:ok, users} ->
        tracks =
          users
          |> Enum.filter(&(&1.track.valid == true))
          |> Enum.map(&extract_track_data/1)

        {:ok, tracks}

      error ->
        error
    end
  end

  @spec fetch_status(map) :: {:ok, any} | {:error, HTTPoison.Response}
  def fetch_status(track), do: GPSGateRest.http_get("users/#{track.user_id}/status")

  defp extract_track_data(raw) do
    track = raw.track
    pos = track.position
    vel = raw.track.velocity

    %{
      name: raw.name,
      user_id: raw.id,
      position: %{
        lat: pos.latitude,
        lng: pos.longitude,
        alt: pos.altitude
      },
      speed_ms: vel.speed,
      heading: vel.heading,
      timestamp: track.timestamp,
      valid: track.valid
    }
  end
end
