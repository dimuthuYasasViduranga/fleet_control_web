defmodule Dispatch.TrackAgent do
  @moduledoc """
  Stores the most recent track data for each asset as it come in
  """
  use Agent

  require Logger

  @type track :: map
  @type source :: atom

  defp get_mode() do
    case Application.get_env(:dispatch_web, :track_method, :normal) do
      :device -> :device
      _ -> :normal
    end
  end

  def start_link(_opts) do
    state = %{mode: get_mode(), tracks: %{}}
    Agent.start_link(fn -> state end, name: __MODULE__)
  end

  @spec all() :: list(track)
  def all() do
    __MODULE__
    |> Agent.get(& &1.tracks)
    |> Map.values()
  end

  @spec get(%{asset_id: integer}) :: track | nil
  def get(%{asset_id: asset_id}) do
    Agent.get(__MODULE__, & &1.tracks[asset_id])
  end

  @spec add(track, source) :: {:ok, track} | {:error, :ignored}
  def add(track, source \\ :normal)
  def add(nil, _), do: {:error, :ignored}

  def add(track, source) do
    Agent.get_and_update(__MODULE__, fn state ->
      case state.mode == source && track[:asset_id] !== nil do
        true ->
          state = put_in(state, [:tracks, track.asset_id], track)
          {{:ok, track}, state}

        false ->
          {{:error, :ignored}, state}
      end
    end)
  end

  @spec set_mode(:normal | :mock | :device) :: no_return()
  def set_mode(mode) when mode in [:normal, :mock, :device] do
    Logger.warn("[TrackAgent] Mode set to '#{mode}'")
    Agent.update(__MODULE__, &Map.put(&1, :mode, mode))
  end
end
