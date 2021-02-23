defmodule Dispatch.TrackAgent do
  @moduledoc """
  Stores the most recent track data for each asset as it come in
  """
  use Agent

  require Logger

  @type track :: map
  @type source :: atom

  def start_link(_opts) do
    state = %{mode: :normal, tracks: %{}}
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
      case state.mode == source do
        true ->
          state = put_in(state, [:tracks, track.asset_id], track)
          {{:ok, track}, state}

        false ->
          {{:error, :ignored}, state}
      end
    end)
  end

  @spec set_mode(:normal | :mock) :: no_return()
  def set_mode(:normal) do
    Logger.warn("[TrackAgent] Mode set to 'normal'")
    Agent.update(__MODULE__, &Map.put(&1, :mode, :normal))
  end

  def set_mode(:mock) do
    Logger.warn("[TrackAgent] Mode set to 'mock'")
    Agent.update(__MODULE__, &Map.put(&1, :mode, :mock))
  end
end
