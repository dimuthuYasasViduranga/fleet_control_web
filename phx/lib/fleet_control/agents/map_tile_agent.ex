defmodule FleetControl.MapTileAgent do
  @moduledoc """
  Holds the manifest document for google map custom tile image endpoints

  Updates periodically
  """

  # 24 hours
  @update_timer 24 * 3600 * 60

  # failure cooldown (30 sec)
  @cooldown_timer 30 * 1000

  @manifest_name "manifest.json"

  require Logger

  defp get_map_tile_endpoint(), do: Application.get_env(:dispatch_web, :map_tile_endpoint, nil)

  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def init(:ok) do
    state = %{
      endpoint: get_map_tile_endpoint()
    }

    send(self(), :update_manifest)

    {:ok, state}
  end

  defp get_manifest(nil), do: {:error, :no_endpoint}

  defp get_manifest(endpoint) do
    manifest_endpoint = "#{endpoint}/#{@manifest_name}"

    case HTTPoison.get(manifest_endpoint) do
      {:ok, %{status_code: 200, body: body}} ->
        manifest = Jason.decode!(body)
        {:ok, manifest}

      _ ->
        {:error, :http_error}
    end
  end

  defp update_manifest_data(state, manifest) do
    manifest
    |> Enum.map(fn {name, extension} -> {name, "#{name}.#{extension}"} end)
    |> Enum.into(%{endpoint: state.endpoint})
  end

  defp schedule_update(timer) do
    Process.send_after(self(), :update_manifest, timer)
  end

  def handle_info(:update_manifest, %{endpoint: nil} = state) do
    Logger.warn("[MapTile] No map manifest given. Custom tiles will not be used")
    {:noreply, state}
  end

  def handle_info(:update_manifest, %{endpoint: endpoint} = state) do
    state =
      endpoint
      |> get_manifest()
      |> case do
        {:ok, manifest} ->
          schedule_update(@update_timer)

          update_manifest_data(state, manifest)

        {:error, :no_manifest} ->
          state

        _ ->
          Logger.warn(
            "[MapTile] Failed to get manifest, trying again in #{@cooldown_timer} seconds"
          )

          schedule_update(@cooldown_timer)
          state
      end

    {:noreply, state}
  end

  def handle_call(:get, _from, state), do: {:reply, state, state}

  @spec get() :: map()
  def get(), do: GenServer.call(__MODULE__, :get)
end
