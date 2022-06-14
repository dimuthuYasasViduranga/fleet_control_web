defmodule Dispatch.TimeAllocationAgent.MassAdd do
  alias Dispatch.TimeAllocationAgent.{Data, Update}

  alias Ecto.Multi
  alias HpsData.Repo
  alias HpsData.Schemas.Dispatch.TimeAllocation

  @type state :: map()
  @type allocation :: map()
  @type deleted_alloc :: allocation
  @type updated_alloc :: allocation
  @type active_alloc :: allocation

  @spec add(integer, list(integer), keyword(), state) ::
          {:ok, list(deleted_alloc), list(updated_alloc), list(active_alloc)} | {:error, term}
  def add(time_code_id, asset_ids, params, state) do
    timestamp = NaiveDateTime.utc_now()

    {to_delete_ids, new_allocs} = compose_data(state, asset_ids, time_code_id, params, timestamp)

    delete_query = Data.delete_query(to_delete_ids)

    delete_updates = [deleted: true, deleted_at: timestamp]

    Multi.new()
    |> Multi.update_all(:deleted, delete_query, [set: delete_updates], returning: true)
    |> Multi.insert_all(:new, TimeAllocation, new_allocs, returning: true)
    |> Repo.transaction()
    |> case do
      {:ok, commits} ->
        {deleted_allocs, state} = add_commits_to_agent(commits.deleted, state)
        {allocs, state} = add_commits_to_agent(commits.new, state)
        completed_allocs = Enum.reject(allocs, &is_nil(&1.end_time))
        active_allocs = Enum.filter(allocs, &is_nil(&1.end_time))

        resp = {:ok, deleted_allocs, completed_allocs, active_allocs}
        {resp, state}

      error ->
        {error, state}
    end
  end

  defp compose_data(state, asset_ids, time_code_id, params, timestamp) do
    base =
      Enum.into(
        params,
        %{
          asset_id: nil,
          time_code_id: time_code_id,
          start_time: timestamp,
          end_time: nil,
          inserted_at: timestamp,
          deleted: false
        }
      )

    unless base[:created_by_dispatcher] || base[:created_by_operator] do
      Logger.error("Time allocation created without recording it's source")
    end

    new_allocs = Enum.map(asset_ids, &Map.put(base, :asset_id, &1))

    deleted =
      asset_ids
      |> Enum.map(&state.active[&1])
      |> Enum.reject(&is_nil/1)

    completed = Enum.map(deleted, &create_completed(&1, timestamp))

    to_delete_ids = Enum.map(deleted, & &1.id)

    {to_delete_ids, new_allocs ++ completed}
  end

  defp create_completed(alloc, timestamp) do
    %{
      asset_id: alloc.asset_id,
      time_code_id: alloc.time_code_id,
      start_time: alloc.start_time,
      end_time: timestamp,
      inserted_at: timestamp,
      deleted: false
    }
  end

  defp add_commits_to_agent({_, commits}, state), do: add_commits_to_agent(commits, state)
  defp add_commits_to_agent([], state), do: {[], state}

  defp add_commits_to_agent([commit | commits], state) do
    {resp, state} = add_commits_to_agent(commits, state)
    {{:ok, commit}, state} = Update.update_agent({:ok, commit}, state)
    {[commit | resp], state}
  end
end
