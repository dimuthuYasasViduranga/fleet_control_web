defmodule Dispatch.TimeAllocationAgent.Lock do
  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi

  alias HpsData.Dim.Calendar
  alias HpsData.Schemas.Dispatch.{Dispatcher, TimeAllocation, TimeAllocationLock}
  alias HpsData.Repo
  alias Dispatch.Helper

  @type alloc :: map
  @type lock :: map
  @type range :: %{start_time: NaiveDateTime.t(), end_time: NaiveDateTime.t()}

  @type success ::
          {:ok,
           %{
             deleted_ids: list(integer),
             ignored_ids: list(integer),
             new: list(alloc),
             lock: lock()
           }}

  @type failure :: {:error, :invalid_calendar | :invalid_calendar}

  @spec lock(list(integer), integer, integer) :: success | failure
  def lock(ids, calendar_id, dispatcher_id) do
    ids = Enum.uniq(ids)
    calendar = Helper.get_by_or_nil(Repo, Calendar, %{id: calendar_id})
    dispatcher = Helper.get_by_or_nil(Repo, Dispatcher, %{id: dispatcher_id})

    cond do
      calendar == nil -> {:error, :invalid_calendar}
      dispatcher == nil -> {:error, :invalid_dispatcher}
      true -> do_lock(ids, calendar, dispatcher)
    end
  end

  defp do_lock(ids, calendar, dispatcher) do
    now = NaiveDateTime.utc_now()

    lock =
      TimeAllocationLock.new(%{
        calendar_id: calendar.id,
        dispatcher_id: dispatcher.id,
        timestamp: now
      })

    Multi.new()
    |> Multi.run(:splits, fn repo, _ ->
      calendar_range = %{start_time: calendar.shift_start_utc, end_time: calendar.shift_end_utc}
      allocs = get_allocations(ids, repo)

      # all ignored allocations skip updates
      # all affected allocations are deleted (new versions will be inserted)
      # all before and after elements are inserted as new elements
      # all during elements are inserted with a lock id

      {affected, ignored} = split_on_shift_interaction(allocs, calendar_range, now)

      {before_shift, during_shift, after_shift} =
        split_all_by_shift(affected, calendar_range, now)

      {:ok,
       %{
         ignored: ignored,
         to_delete: affected,
         to_lock: during_shift,
         to_insert: before_shift ++ after_shift
       }}
    end)
    |> Multi.insert(:lock, lock, returning: true)
    |> Multi.run(:alloc_delete, fn repo, %{splits: splits} ->
      splits.to_delete
      |> Enum.map(& &1.id)
      |> case do
        [] ->
          {:ok, []}

        delete_ids ->
          updates = [deleted: true, deleted_at: NaiveDateTime.utc_now()]

          expected_count = length(delete_ids)

          from(a in TimeAllocation, where: a.id in ^delete_ids)
          |> repo.update_all(set: updates)
          |> case do
            {^expected_count, _} -> {:ok, delete_ids}
            _ -> {:error, :unable_to_update}
          end
      end
    end)
    |> Multi.run(:alloc_lock, fn repo, %{splits: splits, lock: lock} ->
      to_lock = Enum.map(splits.to_lock, &Map.put(&1, :lock_id, lock.id))
      expected_count = length(to_lock)

      repo.insert_all(TimeAllocation, to_lock, returning: true)
      |> case do
        {^expected_count, entries} -> {:ok, entries}
        _ -> {:error, :unable_to_insert}
      end
    end)
    |> Multi.run(:alloc_insert, fn repo, %{splits: splits} ->
      expected_count = length(splits.to_insert)

      repo.insert_all(TimeAllocation, splits.to_insert, returning: true)
      |> case do
        {^expected_count, entries} -> {:ok, entries}
        _ -> {:error, :unable_to_insert}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, data} ->
        deleted_ids = data.alloc_delete
        ignored_ids = Enum.map(data.splits.ignored, & &1.id)
        new_allocs = Enum.map(data.alloc_lock ++ data.alloc_insert, &TimeAllocation.to_map/1)
        lock = TimeAllocationLock.to_map(data.lock)

        response = %{
          deleted_ids: deleted_ids,
          ignored_ids: ignored_ids,
          new: new_allocs,
          lock: lock
        }

        {:ok, response}

      error ->
        error
    end
  end

  defp get_allocations(ids, repo) do
    from(ta in TimeAllocation,
      where: ta.id in ^ids
    )
    |> repo.all()
    |> Enum.map(&TimeAllocation.to_map/1)
  end

  defp split_on_shift_interaction(allocations, calendar, active_end_time) do
    Enum.reduce(allocations, {[], []}, fn alloc, {affected, unaffected} ->
      alloc_with_end = Map.put(alloc, :end_time, alloc[:end_time] || active_end_time)

      case no_overlap(alloc_with_end, calendar) do
        true -> {affected, [alloc | unaffected]}
        false -> {[alloc | affected], unaffected}
      end
    end)
  end

  defp no_overlap(a, b), do: Helper.coverage(a, b) in [:no_overlap, :unknown]

  defp split_all_by_shift(allocs, calendar, active_end_time) when is_list(allocs) do
    initial = %{before: [], during: [], after: []}

    splits =
      Enum.reduce(allocs, initial, fn alloc, acc ->
        alloc = Map.drop(alloc, [:id, :lock_id])
        results = split_by_shift(alloc, calendar, active_end_time)

        Map.merge(acc, results, fn _key, alloc_list, alloc_val -> [alloc_val | alloc_list] end)
      end)

    {splits.before, splits.during, splits.after}
  end

  @doc """
  Split the given allocation when it interacts with the calendar range.
  Results are split into 'before', 'during' and 'after'
  Elements that do not interact with the calendar return an empty map
  """
  @spec split_by_shift(alloc :: range, calendar :: range, NaiveDateTime.t()) :: %{
          optional(:before) => range,
          optional(:during) => range,
          optional(:after) => range
        }
  def split_by_shift(alloc, calendar, active_end_time) do
    alloc_with_end = Map.put(alloc, :end_time, alloc[:end_time] || active_end_time)

    case Helper.coverage(alloc_with_end, calendar) do
      :unknown ->
        %{}

      :equals ->
        %{during: alloc}

      :covers ->
        alloc_before = Map.merge(alloc, %{end_time: calendar.start_time})

        alloc_during =
          Map.merge(alloc, %{start_time: calendar.start_time, end_time: calendar.end_time})

        alloc_after = Map.merge(alloc, %{start_time: calendar.end_time})

        %{
          before: alloc_before,
          during: alloc_during,
          after: alloc_after
        }

      :within ->
        %{during: alloc}

      :end_within ->
        alloc_before = Map.merge(alloc, %{end_time: calendar.start_time})
        alloc_during = Map.merge(alloc, %{start_time: calendar.start_time})
        # create a new before and during
        %{
          before: alloc_before,
          during: alloc_during
        }

      :start_within ->
        alloc_during = Map.merge(alloc, %{end_time: calendar.end_time})
        alloc_after = Map.merge(alloc, %{start_time: calendar.end_time})

        %{
          during: alloc_during,
          after: alloc_after
        }

      :no_overlap ->
        %{}
    end
  end
end
