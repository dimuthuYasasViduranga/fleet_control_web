defmodule TrackSub do
  @moduledoc """
  This module is TEMPORARY. Pending deployment into kubernetes to access track data broadcasts
  """
  alias FleetControl.AssetAgent
  alias HpsData.Repo

  defmacro __using__(_opts) do
    quote do
      require Logger
      use GenServer
      # 7 seconds (in miliseconds)
      @timeout 7_000

      def start_link(opts) do
        GenServer.start_link(__MODULE__, :ok, opts)
      end

      def init(:ok) do
        send(self(), :work)
        {:ok, %{}}
      end

      def handle_info(:work, state) do
        get_track_method()
        |> get_tracks()
        |> case do
          {:ok, tracks} ->
            tracks
            |> Enum.map(fn track ->
              Task.async(fn -> handle_track(track, state) end)
            end)
            |> Enum.each(&Task.await(&1, 20_000))

          {:error, response} ->
            info = safe_response(response)
            Logger.warn("[TrackSub] Failed to fetch latest tracks. #{inspect(info)}")
        end

        schedule_work()

        {:noreply, state}
      end

      defp safe_response(%HTTPoison.Response{} = response) do
        response
        |> Map.put(:headers, "--removed--")
        |> Map.put(:request, "--removed--")
      end

      defp safe_response(error), do: error

      defp get_track_method() do
        Application.get_env(:fleet_control_web, :track_method, :gps_gate)
      end

      defp get_tracks(:replicated), do: get_replicated_tracks()

      defp get_tracks(_), do: TrackSub.Rest.get_latest_tracks()

      defp get_replicated_tracks() do
        query = """
        SELECT
          track_data.asset_id,
          a.name,
          track_data.lat,
          track_data.lon,
          track_data.alt,
          track_data.speed_ms,
          track_data.heading,
          track_data.ignition,
          track_data.valid_gps,
          a.user_id,
          a.timestamp
        FROM (
          SELECT
            id as asset_id,
            name,
            dam_identifier as user_id,
            (
              SELECT
                MAX(timestamp)
              FROM track_data
              WHERE asset_id = asset.id
            ) as timestamp
          FROM asset
        ) as a
        INNER JOIN track_data ON
          track_data.asset_id = a.asset_id and track_data.timestamp = a.timestamp
        """

        tracks =
          Repo
          |> Ecto.Adapters.SQL.query!(query)
          |> Map.get(:rows, [])
          |> Enum.map(fn [
                           _,
                           name,
                           lat,
                           lon,
                           alt,
                           speed,
                           heading,
                           ignition,
                           valid,
                           user_id,
                           timestamp
                         ] ->
            %{
              heading: heading,
              name: name,
              user_id: user_id,
              speed_ms: speed,
              ignition: ignition,
              position: %{
                alt: alt,
                lat: lat,
                lng: lon
              },
              valid: valid,
              timestamp: timestamp
            }
          end)

        {:ok, tracks}
      end

      defp handle_track(track, state) do
        asset = AssetAgent.get_asset(%{name: track.name})
        handle_live(asset.id, track, state)
      end

      defp schedule_work() do
        Process.send_after(self(), :work, @timeout)
      end

      defp add_ignition(%{ignition: _} = track), do: track

      defp add_ignition(track) do
        case TrackSub.Rest.fetch_status(track) do
          {:ok, status} ->
            ignition_flag =
              status
              |> Map.get("variables")
              |> Enum.find(&(&1["name"] == "Ignition"))
              |> case do
                nil ->
                  Map.put(track, :ignition, nil)

                %{"value" => ignition} ->
                  Map.put(track, :ignition, ignition == "True")
              end

          _error ->
            Map.put(track, :ignition, nil)
        end
      end
    end
  end
end

defmodule FleetControl.TrackSub do
  use TrackSub
  alias FleetControlWeb.Broadcast

  alias FleetControl.Tracks
  alias FleetControl.TrackAgent

  def handle_live(_asset_id, track, _state) do
    track
    |> Tracks.add_info()
    |> TrackAgent.add()
    |> case do
      {:ok, track} -> Broadcast.send_track(track)
      _ -> nil
    end
  end
end
