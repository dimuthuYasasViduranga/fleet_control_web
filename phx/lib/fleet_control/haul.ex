defmodule FleetControl.Haul do
  require Logger

  import Ecto.Query, only: [from: 2, subquery: 1]

  alias HpsData.Asset
  alias HpsData.Dim
  alias HpsData.Repo
  alias HpsData.Haul.Cycle
  alias HpsData.Haul.TimeUsage

  @recency 12 * 3600

  def recent() do
    now = NaiveDateTime.utc_now()
    recent = NaiveDateTime.add(now, -@recency)
    fetch_by_range!(%{start_time: recent, end_time: now})
  end

  @doc """
  Returns all cycles that have any period within the specified range
  This includes start and end, start_only, end_only and a cycle that goes over the entire range
  """
  def fetch_by_range!(range) do
    cycles = fetch_cycles_by_range!(range)
    timeusage = fetch_timeusage_by_range!(range)

    %{cycles: cycles, timeusage: timeusage}
  end

  def fetch_cycles_by_range!(%{calendar_id: cal_id}) do
    fn query ->
      from([c] in query,
        where: c.calendar_id == ^cal_id
      )
    end
    |> fetch_cycles()
  end

  def fetch_cycles_by_range!(%{start_time: start_time, end_time: end_time}) do
    fn query ->
      from([c] in query,
        where: c.end_time >= ^start_time,
        where: c.start_time < ^end_time
      )
    end
    |> fetch_cycles()
  end

  defp fetch_cycles(where) do
    query = where.(Cycle)

    from([c] in query,
      join: ht in Dim.HaulTruck,
      on: [id: c.haul_truck_id],
      join: a in Asset,
      on: [id: ht.asset_id],
      left_join: start_loc in ^location_subquery(),
      on: [history_id: c.location_history_start_id],
      left_join: load_loc in ^location_subquery(),
      on: [history_id: c.location_history_load_id],
      left_join: dump_loc in ^location_subquery(),
      on: [history_id: c.location_history_dump_id],
      order_by: [desc: c.start_time],
      select: %{
        # associations
        id: c.id,
        haul_truck_id: ht.id,
        asset_id: a.id,
        asset_name: a.name,
        # start
        location_history_start_id: c.location_history_start_id,
        start_location: start_loc.name,
        start_location_type: start_loc.type,
        # load
        location_history_load_id: c.location_history_load_id,
        load_location: load_loc.name,
        load_location_type: load_loc.type,
        # dump
        location_history_dump_id: c.location_history_dump_id,
        dump_location: dump_loc.name,
        dump_location_type: dump_loc.type,

        # metrics
        distance: c.distance_travelled,
        start_time: c.start_time,
        end_time: c.end_time,
        calendar_id: c.calendar_id,
        empty_haul_duration: c.empty_haul_duration,
        queue_at_load_duration: c.queue_at_load_duration,
        spot_at_load_duration: c.spot_at_load_duration,
        loading_duration: c.loading_duration,
        full_haul_duration: c.full_haul_duration,
        queue_at_dump_duration: c.queue_at_dump_duration,
        spot_at_dump_duration: c.spot_at_dump_duration,
        dumping_duration: c.dumping_duration,
        crib_duration: c.crib_duration
      }
    )
    |> Repo.all()
  end

  def fetch_timeusage_by_range!(%{calendar_id: cal_id}) do
    fn query ->
      from([tu] in query,
        where: tu.calendar_id == ^cal_id
      )
    end
    |> fetch_timeusage()
  end

  def fetch_timeusage_by_range!(%{start_time: start_time, end_time: end_time}) do
    cull_start = NaiveDateTime.add(start_time, -24 * 3600)

    fn query ->
      from([tu] in query,
        where: tu.start_time > ^cull_start,
        where: tu.end_time >= ^start_time,
        where: tu.start_time < ^end_time
      )
    end
    |> fetch_timeusage()
  end

  defp fetch_timeusage(where) do
    query = where.(TimeUsage)

    from([tu] in query,
      join: ht in Dim.HaulTruck,
      on: [id: tu.haul_truck_id],
      join: a in Asset,
      on: [id: ht.asset_id],
      left_join: loc in ^location_subquery(),
      on: [history_id: tu.location_history_id],
      join: tu_type in Dim.TimeUsage,
      on: [id: tu.time_usage_type_id],
      where: tu.duration != 0,
      order_by: [desc: tu.start_time],
      select: %{
        # associations
        id: tu.id,
        haul_truck_id: ht.id,
        asset_id: a.id,
        asset_name: a.name,

        # timeusage info
        cycle_id: tu.cycle_id,
        type_id: tu_type.id,
        type: tu_type.secondary,

        # location
        location_history_id: tu.location_history_id,
        location: loc.name,

        # time
        calendar_id: tu.calendar_id,
        start_time: tu.start_time,
        end_time: tu.end_time,

        # metrics
        transmission: tu.transmission,
        distance: tu.distance
      }
    )
    |> Repo.all()
    |> merge_timeusages()
  end

  defp location_subquery() do
    query =
      from(lh in Dim.LocationHistory,
        select: %{
          # location history
          history_id: lh.id,

          # location
          name: lh.name,
          id: lh.location_id,

          # location type
          type: lh.type,
          type_id: lh.location_type_id
        }
      )

    subquery(query)
  end

  defp merge_timeusages(timeusage) do
    timeusage
    |> Enum.group_by(& &1.asset_id)
    |> Enum.map(fn {_asset_id, tus} ->
      tus
      |> sort_asc(:start_time)
      |> Enum.reduce({[], nil}, &merge_timeusage/2)
      |> case do
        {completed, nil} -> completed
        {completed, partial} -> [partial | completed]
      end
    end)
    |> List.flatten()
  end

  defp update_partial(partial, tu) do
    partial
    |> Map.update!(:distance, &(&1 + tu.distance))
    |> Map.put(:end_time, tu.end_time)
  end

  defp merge_timeusage(tu, {completed, nil}), do: {completed, tu}

  defp merge_timeusage(tu, {completed, partial}) do
    case tu.type == partial.type do
      true ->
        updated_partial = update_partial(partial, tu)
        {completed, updated_partial}

      false ->
        updated_completed = [partial | completed]

        {updated_completed, tu}
    end
  end

  defp sort_asc(list, key) do
    Enum.sort(list, fn a, b -> NaiveDateTime.compare(a[key], b[key]) == :lt end)
  end
end
