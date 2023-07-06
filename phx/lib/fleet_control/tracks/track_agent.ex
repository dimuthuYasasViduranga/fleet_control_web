defmodule FleetControl.TrackAgent do
  @moduledoc """
  Stores the most recent track data for each asset as it come in
  """
  use Agent
  alias FleetControl.Helper

  require Logger

  @type track :: map

  def start_link(_opts) do
    state = %{}
    Agent.start_link(fn -> state end, name: __MODULE__)
  end

  @spec as_map :: map()
  def as_map(), do: Agent.get(__MODULE__, & &1)

  @spec all() :: list(track)
  def all() do
    __MODULE__
    |> Agent.get(& &1)
    |> Map.values()
  end

  @spec get(%{asset_id: integer}) :: track | nil
  def get(%{asset_id: asset_id}), do: Agent.get(__MODULE__, & &1[asset_id])

  @spec add(track) :: {:ok, track} | {:error, :ignored}
  def add(track)
  def add(nil), do: {:error, :ignored}

  def add(track) do
    track = Map.put(track, :timestamp, Helper.to_naive(track.timestamp))

    Agent.get_and_update(__MODULE__, fn tracks ->
      existing = tracks[track.asset_id]

      if is_nil(track[:asset_id]) || is_nil(track[:timestamp]) do
        {{:error, :ignored}, tracks}
      else
        # only update if at least 15 seconds in the future
        if is_nil(existing) || NaiveDateTime.diff(track.timestamp, existing.timestamp) > 15 do
          existing = existing || %{}
          track = Map.merge(existing, track)
          track_delta = Map.to_list(track) -- Map.to_list(existing)
          track_delta = [{:asset_id, track.asset_id} | track_delta]
          track_delta = Enum.into(track_delta, %{})

          tracks = Map.put(tracks, track.asset_id, track)
          {{:ok, track, track_delta}, tracks}
        else
          {{:error, :ignored}, tracks}
        end
      end
    end)
  end
end
