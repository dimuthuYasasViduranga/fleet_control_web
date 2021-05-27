defmodule Dispatch.TimeAllocationAgent do
  @moduledoc """
  Holds historic allocations for the past 2 shifts
  Always holds the active allocation for each asset
  """

  alias Dispatch.Helper, as: DHelper
  alias Dispatch.{Culling, AgentHelper}
  alias __MODULE__.{Data, Update, Lock, Helper}

  alias HpsData.Schemas.Dispatch.TimeAllocation
  alias HpsData.Repo

  alias Ecto.Multi
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
  def add(%{"asset_id" => _asset_id} = alloc) do
    alloc
    |> DHelper.to_atom_map!()
    |> add()
  end

  def add(alloc) do
    case Helper.has_keys?(alloc, [:asset_id, :time_code_id, :start_time, :end_time]) do
      false ->
        {:error, :invalid_keys}

      _ ->
        alloc =
          %{
            asset_id: alloc.asset_id,
            time_code_id: alloc.time_code_id,
            start_time: DHelper.to_naive(alloc.start_time),
            end_time: DHelper.to_naive(alloc.end_time)
          }
          |> ensure_allocation_before_timestamp(NaiveDateTime.utc_now())

        Agent.get_and_update(__MODULE__, fn state ->
          case alloc do
            %{end_time: nil} = alloc -> add_active_allocation(alloc, state)
            alloc -> add_completed_allocation(alloc, state)
          end
        end)
    end
  end

  defp ensure_allocation_before_timestamp(allocation, timestamp) do
    allocation =
      case Helper.naive_compare?(allocation.start_time, [:gt], timestamp) do
        true -> Map.put(allocation, :start_time, timestamp)
        false -> allocation
      end

    cond do
      is_nil(allocation[:end_time]) ->
        allocation

      Helper.naive_compare?(allocation.end_time, [:lt], allocation.start_time) ->
        Map.put(allocation, :end_time, allocation.start_time)

      true ->
        allocation
    end
  end

  defp add_active_allocation(alloc, state) do
    case state.active[alloc.asset_id] do
      nil ->
        # no current element, just insert
        add_completed_allocation(alloc, state)

      current ->
        cond do
          Helper.naive_compare?(alloc.start_time, [:eq, :lt], current.start_time) ->
            {{:error, :start_before_active}, state}

          true ->
            deleted_current =
              TimeAllocation
              |> Repo.get_by!(%{id: current.id})
              |> TimeAllocation.changeset(%{deleted: true})

            completed =
              current
              |> Map.put(:end_time, alloc.start_time)
              |> Helper.create_new_allocation(state.no_task_id)

            new_current = Helper.create_new_allocation(alloc, state.no_task_id)

            {resp, state} =
              Multi.new()
              |> Multi.update(:deleted_current, deleted_current)
              |> Multi.insert(:completed, completed)
              |> Multi.insert(:new_current, new_current)
              |> Repo.transaction()
              |> Update.update_agent_from_commits(
                [:deleted_current, :completed, :new_current],
                state
              )

            {List.last(resp), state}
        end
    end
  end

  defp add_completed_allocation(alloc, state) do
    alloc
    |> Helper.create_new_allocation(state.no_task_id)
    |> Repo.insert()
    |> Update.update_agent(state)
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
          {:ok, list(unlocked_alloc), list(deleted_alloc)}
          | {:error, :invalid_ids | :not_unlockable | term}
  def unlock([]), do: {:ok, [], []}

  def unlock(ids) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Lock.unlock(ids) do
        {:ok, unlocked, deleted} ->
          deleted_ids = Enum.map(deleted, & &1.id)

          historic =
            state.historic
            |> Enum.reject(&(&1.id in deleted_ids))
            |> Enum.concat(unlocked)

          state = Map.put(state, :historic, historic)
          {{:ok, unlocked, deleted}, state}

        error ->
          {error, state}
      end
    end)
  end
end
