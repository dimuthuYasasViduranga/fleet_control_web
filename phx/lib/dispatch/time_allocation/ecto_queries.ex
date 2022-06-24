defmodule Dispatch.TimeAllocation.EctoQueries do
  alias HpsData.Asset
  alias HpsData.Schemas.Dispatch.TimeAllocation
  alias HpsData.Schemas.Dispatch.TimeCode
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2, subquery: 1]

  @select_data_keys [
    :id,
    :asset_id,
    :time_code_id,
    :start_time,
    :end_time,
    :deleted,
    :inserted_at,
    :deleted_at,
    :lock_id,
    :created_by_dispatcher,
    :created_by_operator,
    :updated_by_dispatcher
  ]

  defmacrop select_data(q) do
    quote do
      map(unquote(q), @select_data_keys)
    end
  end

  def culling_opts() do
    %{
      time_key: :end_time,
      max_age: 24 * 60 * 60
    }
  end

  @doc """
  Fetch all elements that are covered by this time range
  This includes elements that completely cover the given range
  """
  def fetch_by_range!(%{asset_ids: asset_ids, start_time: start_time, end_time: end_time}) do
    from(ta in TimeAllocation,
      where: ta.asset_id in ^asset_ids,
      where:
        (ta.start_time < ^end_time and ta.end_time > ^start_time) or
          (is_nil(ta.end_time) and ta.start_time < ^end_time),
      where: ta.deleted == false,
      select: select_data(ta)
    )
    |> Repo.all()
  end

  def fetch_by_range!(%{start_time: start_time, end_time: end_time}) do
    from(ta in TimeAllocation,
      where:
        (ta.start_time < ^end_time and ta.end_time > ^start_time) or
          (is_nil(ta.end_time) and ta.start_time < ^end_time),
      where: ta.deleted == false,
      select: select_data(ta)
    )
    |> Repo.all()
  end

  def init(timestamp, max_age) do
    now = timestamp || NaiveDateTime.utc_now()

    recent = NaiveDateTime.add(now, -max_age, :second)

    %{
      historic: pull_historic(recent),
      active: pull_active(),
      no_task_id: pull_no_task_id()
    }
  end

  defp pull_historic(recent) do
    from(ta in TimeAllocation,
      where: not is_nil(ta.end_time),
      where: ta.end_time > ^recent,
      select: select_data(ta)
    )
    |> Repo.all()
  end

  defp pull_active() do
    max_query = get_latest_query()

    from(a in subquery(max_query),
      join: ta in TimeAllocation,
      on:
        ta.asset_id == a.asset_id and ta.start_time == a.start_time and ta.deleted == false and
          is_nil(ta.end_time),
      select: select_data(ta)
    )
    |> Repo.all()
    |> Enum.map(&{&1.asset_id, &1})
    |> Enum.into(%{})
  end

  defp pull_no_task_id() do
    from(tc in TimeCode,
      where: tc.name == "No Task",
      select: tc.id
    )
    |> Repo.one!()
  end

  defp get_latest_query() do
    from(a in Asset,
      select: %{
        asset_id: a.id,
        start_time:
          fragment(
            "SELECT
              MAX(start_time)
            FROM dis_time_allocation
            WHERE asset_id = ? AND end_time is NULL AND deleted = false",
            a.id
          )
      }
    )
  end

  def get_allocations_to_update([]), do: []

  def get_allocations_to_update(ids) do
    ids = Enum.reject(ids, &is_nil/1)

    from(
      ta in TimeAllocation,
      where: ta.id in ^ids,
      select: select_data(ta)
    )
    |> Repo.all()
  end

  def delete_query(ids_to_delete) do
    from(
      ta in TimeAllocation,
      where: ta.id in ^ids_to_delete,
      select: select_data(ta)
    )
  end
end
