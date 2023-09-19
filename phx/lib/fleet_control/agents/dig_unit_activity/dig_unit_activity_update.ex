defmodule FleetControl.DigUnitActivityAgent.Update do
  alias FleetControl.Helper, as: DHelper
  alias FleetControl.AgentHelper
  alias HpsData.Schemas.Dispatch.DigUnitActivity
  alias FleetControl.TimeAllocation.Helper
  alias Ecto.Multi

  alias HpsData.Schemas.Dispatch.TimeAllocation
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2, subquery: 1]

  require Logger

  def update_all(updates, state) when is_list(updates) do
    updates =
      updates
      |> Enum.map(&DHelper.to_atom_map!/1)
      |> Enum.map(fn update ->
        update
        |> Map.update(:start_time, nil, &DHelper.to_naive/1)
        |> Map.update(:end_time, nil, &DHelper.to_naive/1)
      end)
      |> Enum.reject(&(&1[:id] == nil && &1[:deleted] == true))

    case validate(updates) do
      {:ok, []} ->
        {{:ok, [], [], nil}, state}

      {:ok, [asset_id | _]} ->
        current =
          state.current
          |> Enum.map(&{&1.asset_id, &1})
          |> Enum.into(%{})

        active_element = Map.get(current, asset_id)

        {new_activities, ids_to_delete} = get_update_changes(updates, active_element)

        delete_query = delete_query(ids_to_delete)

        Multi.new()
        |> Multi.delete_all(:deleted, delete_query, returning: true)
        |> Multi.insert_all(:new, DigUnitActivity, new_activities, returning: true)
        |> Repo.transaction()

      error ->
        {error, state}
    end
  end

  defp validate(updates) do
    now = DHelper.naive_timestamp()
    max_future_timestamp = NaiveDateTime.add(now, TimeAllocation.max_future_insert())

    ids =
      updates
      |> Enum.map(& &1[:id])
      |> Enum.reject(&is_nil/1)

    activities_affected = get_activities_to_update(ids)

    asset_ids =
      (updates ++ activities_affected)
      |> Enum.map(& &1[:asset_id])
      |> Enum.uniq()

    new_activity = Enum.filter(updates, &(&1.end_time == nil && &1[:deleted] != true))

    cond do
      updates == [] ->
        {:ok, []}

      Enum.any?(updates, &is_invalid_activity?(&1, activities_affected, max_future_timestamp)) ->
        {:error, :invalid}

      length(asset_ids) != 1 || Enum.any?(asset_ids, &is_nil/1) ->
        {:error, :multiple_assets}

      length(activities_affected) != length(ids) ->
        {:error, :ids_not_found}

      length(new_activity) > 1 ->
        {:error, :multiple_actives}

      true ->
        {:ok, asset_ids}
    end
  end

  def has_keys?(map, keys), do: Enum.all?(keys, &Map.has_key?(map, &1))

  defp is_invalid_activity?(activity, activities_affected, max_timestamp) do
    affected_activity = Enum.find(activities_affected, &(&1.id == activity[:id]))

    !has_keys?(activity, [:asset_id, :material_type_id, :start_time, :end_time]) ||
      activity.start_time == nil ||
      Helper.naive_compare?(activity.start_time, [:gt], activity.end_time) ||
      Helper.naive_compare?(activity.start_time, [:eq, :gt], max_timestamp) ||
      Helper.naive_compare?(activity.end_time, [:eq, :gt], max_timestamp) ||
      (affected_activity[:timespan] != nil && activity[:end_time] == nil)
  end

  defp get_update_changes(updates, active) do
    {changes_to_active, new_active, accepted_updates} = separate_updates(updates, active)

    all_updates =
      [changes_to_active, new_active | accepted_updates]
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    ids_to_delete =
      all_updates
      |> Enum.map(& &1[:id])
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    new_activities =
      all_updates
      |> Enum.reject(&(&1[:deleted] == true))
      |> Enum.map(fn update ->
        %{
          asset_id: update.asset_id,
          material_type_id: update.material_type_id || nil,
          timestamp: update.start_time
        }
      end)

    {new_activities, ids_to_delete}
  end

  defp separate_updates(updates, nil, _) do
    new_active = Enum.find(updates, &(&1[:id] == nil && &1.end_time == nil))
    updates = Enum.reject(updates, &(&1 == new_active))

    {nil, new_active, updates}
  end

  defp separate_updates(updates, active) do
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
            material_type_id: nil,
            start_time: changes_to_active.end_time || NaiveDateTime.utc_now(),
            end_time: nil
          }

          {proposed_active || fallback_active, []}

        # if has active and has proposed active
        proposed_active ->
          # only accept if later
          proposed_is_greater =
            Helper.naive_compare?(proposed_active.start_time, [:gt, :eq], active.timestamp)

          case proposed_is_greater do
            true ->
              complete_active =
                case changes_to_active do
                  nil ->
                    Map.put(active, :timestamp, proposed_active.start_time)

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

  def get_activities_to_update([]), do: []

  def get_activities_to_update(ids) do
    ids = Enum.reject(ids, &is_nil/1)

    from(
      dua in DigUnitActivity,
      where: dua.id in ^ids,
      select: %{
        id: dua.id,
        asset_id: dua.asset_id,
        material_type_id: dua.material_type_id,
        timestamp: dua.timestamp,
        server_timestamp: dua.server_timestamp
      }
    )
    |> Repo.all()
  end

  def delete_query(ids_to_delete) do
    from(
      dua in DigUnitActivity,
      where: dua.id in ^ids_to_delete,
      select: %{
        id: dua.id,
        asset_id: dua.asset_id,
        material_type_id: dua.material_type_id,
        timestamp: dua.timestamp,
        server_timestamp: dua.server_timestamp
      }
    )
  end
end
