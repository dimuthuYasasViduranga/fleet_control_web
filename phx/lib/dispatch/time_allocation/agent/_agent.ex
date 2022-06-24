defmodule Dispatch.TimeAllocation.Agent do
  @moduledoc """
  Holds historic allocations for the past 2 shifts
  Always holds the active allocation for each asset
  """

  alias Dispatch.Culling
  alias Dispatch.AgentHelper
  alias Dispatch.TimeAllocation.Data
  alias Dispatch.TimeAllocation.Add
  alias Dispatch.TimeAllocation.MassAdd
  alias Dispatch.TimeAllocation.Update
  alias Dispatch.TimeAllocation.Lock
  alias Dispatch.TimeAllocation.Unlock

  use Agent

  @type allocation :: map
  @type new_active_alloc :: allocation()
  @type deleted_alloc :: allocation()
  @type completed_alloc :: allocation()
  @type new_alloc :: allocation()

  @type locked_alloc :: allocation()
  @type unlocked_alloc :: allocation()
  @type lock :: map

  def start_link(opts),
    do: AgentHelper.start_link(fn -> Data.init(opts[:timestamp], Data.culling_opts().max_age) end)

  @spec refresh!(NaiveDateTime.t()) :: :ok
  def refresh!(timestamp \\ NaiveDateTime.utc_now()),
    do: AgentHelper.set(__MODULE__, Data.init(timestamp, Data.culling_opts().max_age))

  @spec active() :: list(allocation)
  def active(), do: Map.values(Agent.get(__MODULE__, & &1.active))

  @spec historic() :: list(allocation)
  def historic() do
    Agent.get(__MODULE__, & &1.historic)
    |> Enum.filter(&(&1.deleted == false))
  end

  @spec get_active(map) :: allocation | nil
  def get_active(%{id: id}), do: Enum.find(active(), &(&1.id == id))

  def get_active(%{asset_id: asset_id}) do
    Agent.get(__MODULE__, & &1.active)
    |> Map.get(asset_id)
  end

  @spec update_all(list(map)) ::
          {:ok, list(deleted_alloc), list(completed_alloc), new_active_alloc | nil}
          | {:error,
             :invalid
             | :multiple_assets
             | :multiple_actives
             | :ids_not_found
             | :stale
             | term}
  def update_all(updates) do
    Agent.get_and_update(__MODULE__, fn state ->
      Update.update_all(updates, state)
    end)
  end

  @spec add(%{
          asset_id: integer,
          time_code_id: integer,
          start_time: NaiveDateTime.t() | integer,
          end_time: NaiveDateTime.t() | integer | nil
        }) :: {:ok, allocation} | {:error, :invalid_keys | term}
  def add(alloc) do
    Add.add(__MODULE__, alloc)
  end

  @spec mass_add(integer, list(integer), keyword()) ::
          {:ok, list(deleted_alloc), list(completed_alloc), list(new_active_alloc) | nil}
  def mass_add(time_code_id, asset_ids, params) do
    Agent.get_and_update(__MODULE__, fn state ->
      MassAdd.add(time_code_id, asset_ids, params, state)
    end)
  end

  @spec lock(list[integer], integer, integer) ::
          {:ok,
           %{
             deleted_ids: list(integer),
             ignored_ids: list(integer),
             new: list(allocation),
             lock: lock()
           }}
          | {:error, :invalid_calendar | :invalid_calendar}
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
            |> Culling.cull(Data.culling_opts())

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

  @spec unlock(list(integer)) ::
          {:ok, %{new: list(allocation), deleted_ids: list(integer), ignored_ids: list(integer)}}
          | {:error, term}
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
            |> Culling.cull(Data.culling_opts())

          state = Map.put(state, :historic, historic)
          {{:ok, data}, state}

        error ->
          {error, state}
      end
    end)
  end
end
