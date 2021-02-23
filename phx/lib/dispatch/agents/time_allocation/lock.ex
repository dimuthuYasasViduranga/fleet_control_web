defmodule Dispatch.TimeAllocationAgent.Lock do
  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi

  alias Dispatch.TimeAllocationAgent.Data
  alias HpsData.Dim.Calendar
  alias HpsData.Schemas.Dispatch.{Dispatcher, TimeAllocation, TimeAllocationLock}
  alias HpsData.Repo
  alias Dispatch.Helper

  @type locked_alloc :: map
  @type unlocked_alloc :: map
  @type new_alloc :: map
  @type deleted_alloc :: map
  @type unchanged_alloc :: map
  @type alloc_within_range :: map
  @type alloc_outside_range :: map
  @type lock :: map
  @type range :: %{start_time: NaiveDateTime.t(), end_time: NaiveDateTime.t()}

  @spec lock(list[integer], integer, integer) ::
          {:ok, list(locked_alloc), list(new_alloc), list(deleted_alloc), lock}
          | {:error,
             :invalid_ids
             | :invalid_calendar
             | :invalid_dispatcher
             | :deleted_locked_or_active
             | :outside_calendar
             | :multiple_assets
             | term}
  def lock([], _, _), do: {:ok, [], [], [], nil}

  def lock(ids, calendar_id, dispatcher_id) do
    ids =
      ids
      |> Enum.uniq()
      |> Enum.reject(&is_nil/1)

    calendar = Helper.get_by_or_nil(Repo, Calendar, %{id: calendar_id})
    dispatcher = Helper.get_by_or_nil(Repo, Dispatcher, %{id: dispatcher_id})

    allocations = get_allocations(ids)

    cond do
      length(allocations) != length(ids) -> {:error, :invalid_ids}
      calendar == nil -> {:error, :invalid_calendar}
      dispatcher == nil -> {:error, :invalid_dispatcher}
      !all_allocations_lockable?(allocations) -> {:error, :deleted_locked_or_active}
      !single_asset(allocations) -> {:error, :multiple_assets}
      !all_allocations_within_calendar?(allocations, calendar) -> {:error, :outside_calendar}
      true -> lock_allocations(allocations, calendar, dispatcher_id)
    end
  end

  defp get_allocations(ids) do
    from(ta in TimeAllocation,
      where: ta.id in ^ids
    )
    |> Repo.all()
    |> Enum.map(&TimeAllocation.to_map/1)
  end

  defp all_allocations_lockable?(allocations) do
    Enum.all?(allocations, &(&1.deleted != true && &1.lock_id == nil && &1.end_time != nil))
  end

  defp single_asset([]), do: true

  defp single_asset([%{asset_id: asset_id} | _] = allocations) do
    Enum.all?(allocations, &(&1.asset_id == asset_id))
  end

  defp all_allocations_within_calendar?(allocations, calendar) do
    range = %{start_time: calendar.shift_start_utc, end_time: calendar.shift_end_utc}
    !Enum.any?(allocations, &no_overlap?(&1, range))
  end

  defp no_overlap?(a, b), do: Helper.coverage(a, b) in [:no_overlap, :unknown]

  defp lock_allocations(allocations, calendar, dispatcher_id) do
    now = Helper.naive_timestamp()
    range = %{start_time: calendar.shift_start_utc, end_time: calendar.shift_end_utc}

    ids_to_delete = Enum.map(allocations, & &1.id)

    {out_of_range, in_range} = split_allocations(allocations, range)

    out_of_range = Enum.map(out_of_range, &remove_id_and_inserted_at(&1, now))
    in_range = Enum.map(in_range, &remove_id_and_inserted_at(&1, now))

    delete_query = Data.delete_query(ids_to_delete)

    delete_updates = [deleted: true, deleted_at: Helper.naive_timestamp()]

    lock =
      TimeAllocationLock.new(%{
        calendar_id: calendar.id,
        dispatcher_id: dispatcher_id,
        timestamp: now
      })

    Multi.new()
    |> Multi.insert(:lock, lock, returning: true)
    |> Multi.update_all(:deleted, delete_query, [set: delete_updates], returning: true)
    |> Multi.insert_all(:out_of_range, TimeAllocation, out_of_range, returning: true)
    |> Multi.run(:in_range, fn repo, %{lock: lock} ->
      in_range = Enum.map(in_range, &Map.put(&1, :lock_id, lock.id))

      case repo.insert_all(TimeAllocation, in_range, returning: true) do
        {0, _} -> {:error, :failed_locking}
        {_, returned} -> {:ok, returned}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, commits} ->
        deleted = elem(commits.deleted, 1)

        in_range = Enum.map(commits.in_range, &TimeAllocation.to_map/1)

        out_of_range =
          commits.out_of_range
          |> elem(1)
          |> Enum.map(&TimeAllocation.to_map/1)

        lock = TimeAllocationLock.to_map(commits.lock)

        {:ok, in_range, out_of_range, deleted, lock}

      error ->
        error
    end
  end

  defp remove_id_and_inserted_at(allocation, timestamp) do
    allocation
    |> Map.drop([:id])
    |> Map.put(:inserted_at, timestamp)
  end

  @spec split_allocations(list(map), range) ::
          {list(alloc_outside_range), list(alloc_within_range)}
  def split_allocations(allocations, range) do
    Enum.reduce(allocations, {[], []}, fn alloc, {outside, inside} ->
      case split_allocation(alloc, range) do
        {:unchanged, _} -> {outside, [alloc | inside]}
        {:split, in_range, out_of_range} -> {outside ++ out_of_range, [in_range | inside]}
      end
    end)
  end

  @spec split_allocation(list(map), range) ::
          {:unchanged, map} | {:split, alloc_within_range(), list(map)}
  def split_allocation(allocation, range) do
    case Helper.coverage(allocation, range) do
      :covers ->
        left_alloc = Map.put(allocation, :end_time, range.start_time)

        middle_alloc =
          allocation
          |> Map.put(:start_time, range.start_time)
          |> Map.put(:end_time, range.end_time)

        right_alloc = Map.put(allocation, :start_time, range.end_time)
        {:split, middle_alloc, [left_alloc, right_alloc]}

      :end_within ->
        left_alloc = Map.put(allocation, :end_time, range.start_time)
        right_alloc = Map.put(allocation, :start_time, range.start_time)
        {:split, right_alloc, [left_alloc]}

      :start_within ->
        left_alloc = Map.put(allocation, :end_time, range.end_time)
        right_alloc = Map.put(allocation, :start_time, range.end_time)
        {:split, left_alloc, [right_alloc]}

      _ ->
        {:unchanged, allocation}
    end
  end

  @spec unlock(list(integer)) ::
          {:ok, list(unlocked_alloc), list(deleted_alloc)}
          | {:error, :invalid_ids | :multiple_assets | :not_unlockable | term}
  def unlock(ids) do
    ids =
      ids
      |> Enum.uniq()
      |> Enum.reject(&is_nil/1)

    allocations = get_allocations(ids)

    cond do
      length(allocations) != length(ids) -> {:error, :invalid_ids}
      !all_allocations_unlockable?(allocations) -> {:error, :not_unlockable}
      true -> unlock_allocations(allocations)
    end
  end

  def all_allocations_unlockable?(allocations) do
    Enum.all?(allocations, &(&1.lock_id != nil && &1.deleted != true))
  end

  defp unlock_allocations(allocations) do
    now = Helper.naive_timestamp()

    delete_query =
      allocations
      |> Enum.map(& &1.id)
      |> Data.delete_query()

    delete_updates = [deleted: true, deleted_at: now]

    unlocked_allocs =
      Enum.map(allocations, fn alloc ->
        alloc
        |> Map.drop([:id])
        |> Map.put(:inserted_at, now)
        |> Map.put(:lock_id, nil)
      end)

    Multi.new()
    |> Multi.update_all(:deleted, delete_query, [set: delete_updates], returning: true)
    |> Multi.insert_all(:unlocked, TimeAllocation, unlocked_allocs, returning: true)
    |> Repo.transaction()
    |> case do
      {:ok, %{deleted: {_, deleted}, unlocked: {_, unlocked}}} ->
        unlocked = Enum.map(unlocked, &TimeAllocation.to_map/1)

        {:ok, unlocked, deleted}

      error ->
        error
    end
  end
end
