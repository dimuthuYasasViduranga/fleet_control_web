defmodule FleetControlWeb.DispatcherChannel.Report do
  @moduledoc """
  Return a report of exceptions entered, using FleetOps timeusage to determine
  if any exceptions have been missed
  """
  alias FleetControl.{Helper, AssetAgent, Haul, DeviceAssignmentAgent, EngineHoursAgent}

  alias HpsData.Schemas.Dispatch.{TimeAllocation, TimeCode, TimeCodeGroup}
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]

  @static_tu_elements [
    "Parkup",
    "Refuelling",
    "MEM"
  ]

  @min_tu_duration 60

  @spec generate_report(NaiveDateTime.t(), NaiveDateTime.t()) :: list(list)
  def generate_report(start_time, end_time, asset_ids \\ :all) do
    now = NaiveDateTime.utc_now()
    assets = filter_assets(AssetAgent.get_assets(), asset_ids)
    asset_ids = Enum.map(assets, & &1.id)

    allocations =
      get_time_allocations(asset_ids, start_time, end_time)
      |> Enum.group_by(& &1.asset_id)

    timeusage =
      get_timeusage(start_time, end_time)
      |> Enum.group_by(& &1.asset_id)

    cycles =
      get_cycles(start_time, end_time)
      |> Enum.group_by(& &1.asset_id)

    device_assignments =
      get_device_assignments(start_time, end_time)
      |> Enum.group_by(& &1.asset_id)

    engine_hours =
      get_engine_hours(start_time, end_time)
      |> Enum.group_by(& &1.asset_id)

    Enum.map(assets, fn asset ->
      allocs = Map.get(allocations, asset.id, [])
      tu = Map.get(timeusage, asset.id, [])
      cycles = Map.get(cycles, asset.id, [])

      assignments = Map.get(device_assignments, asset.id, [])

      asset_engine_hours = Map.get(engine_hours, asset.id, [])

      build_report(
        asset,
        start_time,
        end_time,
        allocs,
        tu,
        cycles,
        assignments,
        asset_engine_hours,
        now
      )
    end)
  end

  defp filter_assets(assets, :all), do: assets

  defp filter_assets(assets, asset_ids), do: Enum.filter(assets, &Enum.member?(asset_ids, &1.id))

  defp build_report(
         asset,
         report_start,
         report_end,
         allocations,
         timeusage,
         cycles,
         device_assignments,
         engine_hours,
         now
       ) do
    assignments = assignments_to_range(device_assignments, report_start, report_end)

    allocations =
      Enum.map(allocations, fn alloc ->
        alloc =
          alloc
          |> add_active_end(now)
          |> crop_span(report_start, report_end)

        operator_ids =
          get_operator_ids(assignments, %{
            start_time: alloc.start_time,
            end_time: alloc.end_time || alloc.active_end_time
          })

        Map.put(alloc, :operator_ids, operator_ids)
      end)

    merged_timeusage =
      timeusage
      |> merge_timeusages()
      |> Enum.map(&crop_span(&1, report_start, report_end))

    cycles = Enum.map(cycles, &crop_span(&1, report_start, report_end))

    total_engine_hours =
      engine_hours
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [current, next] ->
        %{
          start_hours: current.hours,
          end_hours: next.hours,
          start_time: current.timestamp,
          end_time: next.timestamp
        }
        |> crop_engine_hour(report_start, report_end)
      end)
      |> Enum.reduce(0, fn eh, sum ->
        sum + eh.end_hours - eh.start_hours
      end)

    events =
      [
        exceptions_at_static_geofences(allocations, merged_timeusage, assignments),
        cycles_with_valid_allocations(allocations, cycles, assignments)
      ]
      |> List.flatten()

    %{
      asset: asset,
      report_start: report_start,
      report_end: report_end,
      allocations: allocations,
      events: events,
      assignments: assignments,
      total_engine_hours: total_engine_hours
    }
  end

  defp crop_span(map, start_time, end_time) do
    start_time = Enum.max_by([map.start_time, start_time], & &1, NaiveDateTime)
    end_time = Enum.min_by([map.end_time || map.active_end_time, end_time], & &1, NaiveDateTime)

    map
    |> Map.put(:start_time, start_time)
    |> case do
      %{end_time: nil} = map -> Map.put(map, :active_end_time, end_time)
      map -> Map.put(map, :end_time, end_time)
    end
  end

  defp to_report_row(event, start_time, end_time, spans, compliance, assignments, details) do
    operator_ids = get_operator_ids(assignments, %{start_time: start_time, end_time: end_time})

    %{
      event: event,
      start_time: start_time,
      end_time: end_time,
      spans: spans,
      compliance: compliance,
      operator_ids: operator_ids,
      details: details
    }
  end

  defp get_operator_ids(assignments, time_range) do
    assignments
    |> Enum.filter(&has_overlap?(&1, time_range))
    |> Enum.map(& &1.operator_id)
    |> Enum.uniq()
  end

  defp exceptions_at_static_geofences(allocations, timeusages, assignments) do
    static_tu_elements =
      Enum.filter(timeusages, fn tu ->
        relevant = Enum.member?(@static_tu_elements, tu.type)
        too_short = NaiveDateTime.diff(tu.end_time, tu.start_time) < @min_tu_duration
        relevant && !too_short
      end)

    exceptions = Enum.filter(allocations, &(&1.time_code_group != "Ready"))

    Enum.map(static_tu_elements, fn tu ->
      overlapping = find_all_overlapping(tu, exceptions)

      {occupied, _vacant, total_duration} =
        duration_occupied(%{start_time: tu.start_time, end_time: tu.end_time}, overlapping)

      compliance = occupied / total_duration

      to_report_row(
        "Exception at static geofence",
        tu.start_time,
        tu.end_time,
        overlapping,
        compliance,
        assignments,
        %{
          timeusage_id: tu.id,
          cycle_id: tu.cycle_id,
          location: tu.location,
          type: tu.type
        }
      )
    end)
  end

  defp cycles_with_valid_allocations(allocations, cycles, assignments) do
    valid_task_allocs =
      Enum.reject(allocations, &Enum.member?(["No Task", "Unknown"], &1.time_code))

    Enum.map(cycles, fn cycle ->
      overlapping = find_all_overlapping(cycle, valid_task_allocs)

      {occupied, _vacant, total_duration} =
        duration_occupied(%{start_time: cycle.start_time, end_time: cycle.end_time}, overlapping)

      compliance =
        overlapping
        |> Enum.map(& &1.time_code_group)
        |> Enum.all?(&(&1 !== "Ready"))
        |> case do
          true -> 0
          _ -> safe_div(occupied, total_duration)
        end

      to_report_row(
        "Cycle with valid task",
        cycle.start_time,
        cycle.end_time,
        overlapping,
        compliance,
        assignments,
        cycle
      )
    end)
  end

  defp safe_div(_num, 0.0), do: 0
  defp safe_div(_num, 0), do: 0
  defp safe_div(num, denum), do: num / denum

  defp get_time_allocations(asset_ids, start_time, end_time) do
    from(ta in TimeAllocation,
      where:
        (ta.start_time < ^end_time and ta.end_time > ^start_time) or
          (is_nil(ta.end_time) and ta.start_time < ^end_time),
      where: ta.deleted == false,
      where: ta.asset_id in ^asset_ids,
      join: tc in TimeCode,
      on: [id: ta.time_code_id],
      join: tcg in TimeCodeGroup,
      on: [id: tc.group_id],
      select: %{
        id: ta.id,
        asset_id: ta.asset_id,
        time_code_id: ta.time_code_id,
        time_code: tc.name,
        time_code_group: tcg.name,
        start_time: ta.start_time,
        end_time: ta.end_time,
        deleted: ta.deleted
      }
    )
    |> Repo.all()
  end

  defp get_timeusage(start_time, end_time) do
    Haul.fetch_timeusage_by_range!(%{start_time: start_time, end_time: end_time})
  end

  defp get_cycles(start_time, end_time) do
    Haul.fetch_cycles_by_range!(%{start_time: start_time, end_time: end_time})
  end

  defp get_device_assignments(start_time, end_time) do
    DeviceAssignmentAgent.fetch_by_range!(%{start_time: start_time, end_time: end_time})
  end

  defp get_engine_hours(start_time, end_time) do
    EngineHoursAgent.fetch_by_range!(%{start_time: start_time, end_time: end_time})
  end

  defp assignments_to_range(assignments, min_start_time, max_end_time) do
    assignments
    |> sort_asc(:timestamp)
    |> Enum.dedup_by(&{&1.device_id, &1.operator_id})
    |> Enum.chunk_every(2, 1, [%{timestamp: max_end_time}])
    |> Enum.map(fn [assignment, %{timestamp: end_time}] ->
      start_time = Enum.max_by([assignment.timestamp, min_start_time], & &1, NaiveDateTime)
      end_time = Enum.min_by([end_time, max_end_time], & &1, NaiveDateTime)

      assignment
      |> Map.put(:start_time, start_time)
      |> Map.put(:end_time, end_time)
      |> Map.drop([:timestamp])
    end)
    |> Enum.reject(&(NaiveDateTime.compare(&1.start_time, max_end_time) == :gt))
  end

  defp crop_engine_hour(engine_hour, start_time, end_time) do
    range = %{start_time: start_time, end_time: end_time}
    equation = linear_equation(engine_hour)

    case Helper.coverage(engine_hour, range) do
      :end_within ->
        start_hours = equation.(start_time)

        engine_hour
        |> Map.put(:start_time, start_time)
        |> Map.put(:start_hours, start_hours)

      :start_within ->
        end_hours = equation.(end_time)

        engine_hour
        |> Map.put(:end_time, end_time)
        |> Map.put(:end_hours, end_hours)

      :covers ->
        start_hours = equation.(start_time)
        end_hours = equation.(end_time)

        engine_hour
        |> Map.put(:start_time, start_time)
        |> Map.put(:start_hours, start_hours)
        |> Map.put(:end_time, end_time)
        |> Map.put(:end_hours, end_hours)

      _ ->
        engine_hour
    end
  end

  defp linear_equation(engine_hour) do
    rise = engine_hour.end_hours - engine_hour.start_hours
    run = NaiveDateTime.diff(engine_hour.end_time, engine_hour.start_time)

    gradient =
      case run == 0 do
        true -> 0
        false -> rise / run
      end

    c = engine_hour.start_hours - gradient * Helper.to_unix(engine_hour.start_time, :second)
    fn timestamp -> gradient * Helper.to_unix(timestamp, :second) + c end
  end

  defp find_all_overlapping(reference, targets) do
    Enum.filter(targets, &has_overlap?(&1, reference))
  end

  defp has_overlap?(a, b), do: !Enum.member?([:unknown, :no_overlap], Helper.coverage(a, b))

  defp duration_occupied(%{start_time: start_time, end_time: end_time}, spans) do
    steps =
      spans
      |> Enum.map(fn span ->
        span_start =
          case NaiveDateTime.compare(span.start_time, start_time) do
            :lt -> start_time
            _ -> span.start_time
          end

        span_end =
          case NaiveDateTime.compare(span.end_time || span[:active_end_time], end_time) do
            :gt -> end_time
            _ -> span.end_time || span[:active_end_time]
          end

        [{span_start, 1}, {span_end, -1}]
      end)
      |> List.flatten()
      |> List.insert_at(0, {end_time, 0})
      |> Enum.sort(fn {a, _}, {b, _} -> NaiveDateTime.compare(a, b) == :lt end)

    default_acc = %{
      occupied: 0,
      vacant: 0,
      total_duration: 0,
      last_timestamp: start_time,
      step_value: 0
    }

    info =
      Enum.reduce(steps, default_acc, fn {timestamp, value}, acc ->
        duration = NaiveDateTime.diff(timestamp, acc.last_timestamp)

        cond do
          acc.step_value > 0 -> Map.update!(acc, :occupied, &(&1 + duration))
          true -> Map.update!(acc, :vacant, &(&1 + duration))
        end
        |> Map.update!(:total_duration, &(&1 + duration))
        |> Map.update!(:step_value, &(&1 + value))
        |> Map.put(:last_timestamp, timestamp)
      end)

    {info.occupied, info.vacant, info.total_duration}
  end

  defp merge_timeusages(timeusage) do
    timeusage
    |> sort_asc(:start_time)
    |> Enum.reduce({[], nil}, &merge_timeusage/2)
    |> case do
      {completed, nil} -> completed
      {completed, partial} -> [partial | completed]
    end
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

  defp add_active_end(element, naive) do
    case element.end_time do
      nil -> Map.put(element, :active_end_time, naive)
      _ -> element
    end
  end

  defp sort_asc(list, key) do
    Enum.sort(list, fn a, b -> NaiveDateTime.compare(a[key], b[key]) == :lt end)
  end
end
