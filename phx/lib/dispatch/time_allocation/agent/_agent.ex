defmodule FleetControl.TimeAllocation.Agent do
  @moduledoc """
  Holds historic allocations for the past 2 shifts
  Always holds the active allocation for each asset
  """

  alias FleetControl.Culling
  alias FleetControl.AgentHelper
  alias FleetControl.TimeAllocation.EctoQueries
  alias FleetControl.TimeAllocation.Add
  alias FleetControl.TimeAllocation.MassAdd
  alias FleetControl.TimeAllocation.Update
  alias FleetControl.TimeAllocation.Lock
  alias FleetControl.TimeAllocation.Unlock

  @max_age 24 * 60 * 60

  use Agent

  def start_link(opts),
    do:
      AgentHelper.start_link(fn ->
        EctoQueries.init(opts[:timestamp], @max_age)
      end)

  def refresh!(timestamp \\ NaiveDateTime.utc_now()),
    do: AgentHelper.set(__MODULE__, EctoQueries.init(timestamp, @max_age))

  def active(), do: Map.values(Agent.get(__MODULE__, & &1.active))

  def historic() do
    Agent.get(__MODULE__, & &1.historic)
    |> Enum.filter(&(&1.deleted == false))
  end

  def get_active(%{id: id}), do: Enum.find(active(), &(&1.id == id))

  def get_active(%{asset_id: asset_id}) do
    Agent.get(__MODULE__, & &1.active)
    |> Map.get(asset_id)
  end

  def update_all(updates) do
    Agent.get_and_update(__MODULE__, fn state ->
      Update.update_all(updates, state)
    end)
  end

  def add(alloc) do
    Add.add(__MODULE__, alloc)
  end

  def mass_add(time_code_id, asset_ids, params) do
    Agent.get_and_update(__MODULE__, fn state ->
      MassAdd.add(time_code_id, asset_ids, params, state)
    end)
  end

  def lock(ids, calendar_id, dispatcher_id) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Lock.lock(ids, calendar_id, dispatcher_id) do
        {:ok, data} ->
          deleted_ids = data.deleted_ids
          new_allocs = data.new
          completed_allocs = Enum.reject(new_allocs, &is_nil(&1.end_time))
          active_allocs = Enum.filter(new_allocs, &is_nil(&1.end_time))

          historic =
            state.historic
            |> Enum.reject(&Enum.member?(deleted_ids, &1.id))
            |> Enum.concat(completed_allocs)
            |> cull()

          active_changes =
            active_allocs
            |> Enum.map(&{&1.asset_id, &1})
            |> Enum.into(%{})

          active_map = Map.merge(state.active, active_changes)

          state =
            state
            |> Map.put(:historic, historic)
            |> Map.put(:active, active_map)

          {{:ok, data}, state}

        error ->
          {error, state}
      end
    end)
  end

  def unlock([]), do: {:ok, %{new: [], deleted_ids: [], ignored_ids: []}}

  def unlock(ids) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Unlock.unlock(ids) do
        {:ok, data} ->
          deleted_ids = data.deleted_ids
          unlocked_allocs = data.new

          historic =
            state.historic
            |> Enum.reject(&Enum.member?(deleted_ids, &1.id))
            |> Enum.concat(unlocked_allocs)
            |> cull()

          state = Map.put(state, :historic, historic)
          {{:ok, data}, state}

        error ->
          {error, state}
      end
    end)
  end

  def cull(list) do
    now = NaiveDateTime.utc_now()
    min_timestamp = NaiveDateTime.add(now, -@max_age, :second)

    list
    |> Enum.filter(& &1.end_time)
    |> Enum.sort_by(& &1.end_time, {:desc, NaiveDateTime})
    |> Enum.take_while(&(NaiveDateTime.compare(&1.end_time, min_timestamp) != :lt))
  end
end
