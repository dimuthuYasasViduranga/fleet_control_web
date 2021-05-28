defmodule Dispatch.TimeAllocationAgent.Unlock do
  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi

  alias HpsData.Schemas.Dispatch.TimeAllocation
  alias HpsData.Repo

  @type alloc :: map

  @type success ::
          {
            :ok,
            %{
              new: list(alloc),
              deleted_id: list(integer),
              ignored_ids: list(integer)
            }
          }

  @spec unlock(list(integer)) :: success | {:error, term}
  def unlock(ids) when is_list(ids) do
    ids = Enum.uniq(ids)

    case ids do
      [] -> {:ok, %{new: [], deleted_ids: [], ignored_ids: []}}
      _ -> do_unlock(ids)
    end
  end

  defp do_unlock(ids) do
    now = NaiveDateTime.utc_now()

    Multi.new()
    |> Multi.run(:splits, fn repo, _ ->
      allocs = get_allocations(ids, repo)

      found_ids = Enum.map(allocs, & &1.id)
      missing_ids = ids -- found_ids

      to_unlock = Enum.reject(allocs, &is_nil(&1.lock_id))

      to_delete_ids = Enum.map(to_unlock, & &1.id)

      skipped_ids =
        allocs
        |> Enum.filter(&is_nil(&1.lock_id))
        |> Enum.map(& &1.id)

      {:ok,
       %{
         to_delete_ids: to_delete_ids,
         to_unlock: to_unlock,
         ignored_ids: missing_ids ++ skipped_ids
       }}
    end)
    |> Multi.run(:alloc_delete, fn repo, %{splits: splits} ->
      case splits.to_delete_ids do
        [] ->
          {:ok, []}

        delete_ids ->
          updates = [deleted: true, deleted_at: now]

          expected_count = length(delete_ids)

          from(a in TimeAllocation, where: a.id in ^delete_ids)
          |> repo.update_all(set: updates)
          |> case do
            {^expected_count, _} -> {:ok, delete_ids}
            _ -> {:error, :unable_to_update}
          end
      end
    end)
    |> Multi.run(:alloc_unlock, fn repo, %{splits: splits} ->
      to_unlock =
        Enum.map(splits.to_unlock, fn alloc ->
          alloc
          |> Map.put(:lock_id, nil)
          |> Map.drop([:id])
        end)

      expected_count = length(to_unlock)

      repo.insert_all(TimeAllocation, to_unlock, returning: true)
      |> case do
        {^expected_count, entries} -> {:ok, entries}
        _ -> {:error, :unable_to_insert}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, data} ->
        deleted_ids = data.alloc_delete
        ignored_ids = data.splits.ignored_ids
        unlocked = Enum.map(data.alloc_unlock, &TimeAllocation.to_map/1)

        response = %{
          new: unlocked,
          deleted_ids: deleted_ids,
          ignored_ids: ignored_ids
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
end
