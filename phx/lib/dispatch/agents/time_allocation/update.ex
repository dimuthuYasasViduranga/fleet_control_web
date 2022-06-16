defmodule Dispatch.TimeAllocationAgent.Update do
  alias Dispatch.Helper, as: DHelper
  alias Dispatch.AgentHelper
  alias Dispatch.TimeAllocationAgent.{Data, Helper}
  alias Ecto.Multi

  alias HpsData.Schemas.Dispatch.TimeAllocation
  alias HpsData.Repo

  require Logger

  @type state :: map
  @type allocation :: map
  @type deleted_alloc :: allocation
  @type updated_alloc :: allocation
  @type new_active_alloc :: allocation

  @spec update_all(list(map), state) ::
          {{:ok, list(deleted_alloc), list(updated_alloc), new_active_alloc | nil}, state}
          | {{:error,
              :invalid_id
              | :end_before_start
              | :cannot_remove_end_time
              | :cannot_change_asset
              | :multiple_assets
              | :missing_keys
              | :cannot_change_locked
              | :cannot_set_locked
              | term}, state}
  def update_all(updates, state) when is_list(updates) do
    now = DHelper.naive_timestamp()
    max_future_timestamp = NaiveDateTime.add(now, TimeAllocation.max_future_insert())

    updates =
      updates
      |> Enum.map(&DHelper.to_atom_map!/1)
      |> Enum.map(fn update ->
        unless update[:created_by_operator] || update[:updated_by_dispatcher] do
          Logger.error("Time allocation updated without recording the source of the update")
        end

        update
        |> DHelper.to_atom_map!()
        |> Map.update(:start_time, nil, &DHelper.to_naive/1)
        |> Map.update(:end_time, nil, &DHelper.to_naive/1)
      end)
      |> Enum.reject(&(&1[:id] == nil && &1[:deleted] == true))

    ids =
      updates
      |> Enum.map(& &1[:id])
      |> Enum.reject(&is_nil/1)

    allocs_affected = Data.get_allocations_to_update(ids)

    asset_ids =
      (updates ++ allocs_affected)
      |> Enum.map(& &1[:asset_id])
      |> Enum.uniq()

    new_actives = Enum.filter(updates, &(&1.end_time == nil && &1[:deleted] != true))

    cond do
      updates == [] ->
        {{:ok, [], [], nil}, state}

      Enum.any?(updates, &is_invalid_allocation?(&1, allocs_affected, max_future_timestamp)) ->
        {{:error, :invalid}, state}

      length(asset_ids) != 1 || Enum.any?(asset_ids, &is_nil/1) ->
        {{:error, :multiple_assets}, state}

      Enum.any?(allocs_affected, &(&1[:lock_id] != nil)) ->
        {{:error, :cannot_change_locked}, state}

      Enum.any?(updates, &(&1[:lock_id] != nil)) ->
        {{:error, :cannot_set_locked}, state}

      Enum.any?(allocs_affected, &(&1.deleted == true)) ->
        {{:error, :stale}, state}

      length(allocs_affected) != length(ids) ->
        {{:error, :ids_not_found}, state}

      length(new_actives) > 1 ->
        {{:error, :multiple_actives}, state}

      true ->
        [asset_id] = asset_ids

        active_element = Map.get(state.active, asset_id)

        {new_allocs, ids_to_delete} =
          get_update_changes(updates, active_element, state.no_task_id)

        new_allocs = Enum.map(new_allocs, &Map.put(&1, :inserted_at, now))

        delete_query = Data.delete_query(ids_to_delete)

        delete_updates = [deleted: true, deleted_at: DHelper.naive_timestamp()]

        Multi.new()
        |> Multi.update_all(:deleted, delete_query, [set: delete_updates], returning: true)
        |> Multi.insert_all(:new, TimeAllocation, new_allocs, returning: true)
        |> Repo.transaction()
        |> case do
          {:ok, commits} ->
            {deleted, state} = add_commits_to_agent(commits.deleted, state)
            {allocs, state} = add_commits_to_agent(commits.new, state)
            completed_allocs = Enum.reject(allocs, &is_nil(&1.end_time))
            active_alloc = Enum.find(allocs, &is_nil(&1.end_time))

            resp = {:ok, deleted, completed_allocs, active_alloc}
            {resp, state}

          error ->
            {error, state}
        end
    end
  end

  defp is_invalid_allocation?(alloc, affected_allocs, max_timestamp) do
    affected_alloc = Enum.find(affected_allocs, &(&1.id == alloc[:id]))

    !Helper.has_keys?(alloc, [:asset_id, :time_code_id, :start_time, :end_time]) ||
      alloc.start_time == nil ||
      Helper.naive_compare?(alloc.start_time, [:gt], alloc.end_time) ||
      Helper.naive_compare?(alloc.start_time, [:eq, :gt], max_timestamp) ||
      Helper.naive_compare?(alloc.end_time, [:eq, :gt], max_timestamp) ||
      (affected_alloc[:end_time] != nil && alloc[:end_time] == nil)
  end

  defp get_update_changes(updates, active, no_task_id) do
    {changes_to_active, new_active, accepted_updates} =
      separate_updates(updates, active, no_task_id)

    all_updates =
      [changes_to_active, new_active | accepted_updates]
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    ids_to_delete =
      all_updates
      |> Enum.map(& &1[:id])
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    new_allocs =
      all_updates
      |> Enum.reject(&(&1[:deleted] == true))
      |> Enum.map(fn update ->
        %{
          asset_id: update.asset_id,
          time_code_id: update.time_code_id || no_task_id,
          start_time: update.start_time,
          end_time: update.end_time,
          deleted: false
        }
      end)

    {new_allocs, ids_to_delete}
  end

  defp separate_updates(updates, nil, _) do
    new_active = Enum.find(updates, &(&1[:id] == nil && &1.end_time == nil))
    updates = Enum.reject(updates, &(&1 == new_active))

    {nil, new_active, updates}
  end

  defp separate_updates(updates, active, no_task_id) do
    changes_to_active = Enum.find(updates, &(&1[:id] == active.id))

    active_deleted_or_ended =
      changes_to_active[:deleted] == true || changes_to_active[:end_time] != nil

    proposed_active = Enum.find(updates, &(&1[:id] == nil && &1.end_time == nil))

    {new_active_element, additional_updates} =
      cond do
        # if the active has been deleted or ended, accept proposed active
        active_deleted_or_ended ->
          fallback_active = %{
            asset_id: active.asset_id,
            time_code_id: no_task_id,
            start_time: changes_to_active.end_time || NaiveDateTime.utc_now(),
            end_time: nil
          }

          {proposed_active || fallback_active, []}

        # if has active and has proposed active
        proposed_active ->
          # only accept if later
          proposed_is_greater =
            Helper.naive_compare?(proposed_active.start_time, [:gt, :eq], active.start_time)

          case proposed_is_greater do
            true ->
              complete_active =
                case changes_to_active do
                  nil ->
                    Map.put(active, :end_time, proposed_active.start_time)

                  existing_changes ->
                    Map.put(existing_changes, :end_time, proposed_active.start_time)
                end

              {proposed_active, [complete_active]}

            _ ->
              {nil, []}
          end

        true ->
          {proposed_active, []}
      end

    accepted_updates =
      Enum.reject(
        updates,
        &Enum.member?([changes_to_active, proposed_active, new_active_element], &1)
      )

    {changes_to_active, new_active_element, accepted_updates ++ additional_updates}
  end

  defp add_commits_to_agent({_, commits}, state), do: add_commits_to_agent(commits, state)
  defp add_commits_to_agent([], state), do: {[], state}

  defp add_commits_to_agent([commit | commits], state) do
    {resp, state} = add_commits_to_agent(commits, state)
    {{:ok, commit}, state} = update_agent({:ok, commit}, state)
    {[commit | resp], state}
  end

  @spec update_agent({:ok, TimeAllocation | map} | term, map) ::
          {{:ok, allocation} | term, map}
  def update_agent({:ok, %TimeAllocation{} = alloc}, state) do
    alloc = TimeAllocation.to_map(alloc)
    update_agent({:ok, alloc}, state)
  end

  def update_agent({:ok, %{end_time: nil, deleted: true} = active}, state) do
    active_id = Map.get(state.active, active.asset_id)[:id]

    state =
      if active_id == active.id do
        active_map = Map.drop(state.active, [active.asset_id])
        Map.put(state, :active, active_map)
      else
        state
      end

    {{:ok, active}, state}
  end

  def update_agent({:ok, %{end_time: nil} = active}, state) do
    active_map = Map.put(state.active, active.asset_id, active)
    state = Map.put(state, :active, active_map)
    {{:ok, active}, state}
  end

  def update_agent({:ok, completed}, state) do
    state =
      case completed.deleted do
        false ->
          AgentHelper.override_or_add(
            state,
            :historic,
            completed,
            &(&1.id == completed.id),
            Data.culling_opts()
          )

        _ ->
          historic = Enum.reject(state.historic, &(&1.id == completed.id))
          Map.put(state, :historic, historic)
      end

    {{:ok, completed}, state}
  end

  def update_agent(error, state), do: {error, state}
end
