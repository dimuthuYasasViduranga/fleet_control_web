defmodule FleetControl.TrackAgent do
  @moduledoc """
  Stores the most recent track data for each asset as it come in
  """
  use Agent
  alias FleetControl.Helper

  require Logger

  @type track :: map
  @type source :: atom

  @allowed_sources [:normal, :mock]

  def start_link(_opts) do
    state = %{mode: :normal, tracks: %{}}
    Agent.start_link(fn -> state end, name: __MODULE__)
  end

  @spec as_map :: map()
  def as_map(), do: Agent.get(__MODULE__, & &1.tracks)

  @spec all() :: list(track)
  def all() do
    __MODULE__
    |> Agent.get(& &1.tracks)
    |> Map.values()
  end

  @spec get(%{asset_id: integer}) :: track | nil
  def get(%{asset_id: asset_id}), do: Agent.get(__MODULE__, & &1.tracks[asset_id])

  @spec add(track, source) :: {:ok, track} | {:error, :ignored}
  def add(track, source \\ :normal)
  def add(nil, _), do: {:error, :ignored}

  def add(track, source) do
    track = Map.put(track, :timestamp, Helper.to_naive(track.timestamp))

    Agent.get_and_update(__MODULE__, fn state ->
      existing = state.tracks[track.asset_id]

      with true <- state.mode == source,
           true <- track[:asset_id] !== nil,
           true <- !existing || NaiveDateTime.compare(track.timestamp, existing.timestamp) == :gt do
        state = put_in(state, [:tracks, track.asset_id], track)
        {{:ok, track}, state}
      else
        _ -> {{:error, :ignored}, state}
      end
    end)
  end

  @spec set_mode(source) :: no_return()
  def set_mode(mode) when mode in @allowed_sources do
    Logger.warn("[TrackAgent] Mode set to '#{mode}'")
    Agent.update(__MODULE__, &Map.put(&1, :mode, mode))
  end
end
