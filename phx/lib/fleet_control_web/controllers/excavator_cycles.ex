defmodule FleetControlWeb.ExcavatorCyclesController do
  @moduledoc nil

  require Logger
  use FleetControlWeb, :controller

  import Ecto.Query, only: [from: 2]

  alias HpsData.Dim
  alias HpsData.Haul
  alias HpsData.Asset
  alias HpsData.Schemas.Loader
  alias HpsData.Fleet.ManualLoader
  alias HpsData.Repo

  def fetch_cycles(
        conn,
        %{"asset_id" => asset_id, "start_time" => start_time, "end_time" => end_time}
      ) do
    data =
      query_excavator_events(asset_id, start_time, end_time, ["SpotAtLoad", "Loading"])
      |> combine_overlapping()

    json(conn, data)
  end

  def fetch_queue(
        conn,
        %{"asset_id" => asset_id, "start_time" => start_time, "end_time" => end_time}
      ) do
    data =
      query_excavator_events(asset_id, start_time, end_time, ["QueueAtLoad"])
      # running this twice combines some sqeuential TU elements
      # not really sure why they aren't combined the first time through
      |> combine_overlapping()
      |> Enum.reverse()
      |> combine_overlapping()

    json(conn, data)
  end

  defp duration(tu) do
    NaiveDateTime.diff(tu.end_time, tu.start_time, :microsecond)
  end

  defp format_output(prev) do
    locations =
      if is_list(prev.location) do
        prev.location
        |> Enum.sort()
        |> Stream.reject(&is_nil(&1))
        |> Stream.dedup()
        |> Enum.join(" | ")
      else
        prev.location
      end

    haul_trucks =
      if is_map(prev.haul_truck) do
        prev.haul_truck
        |> MapSet.to_list()
        |> Enum.join(" | ")
      else
        prev.haul_truck
      end

    %{prev | haul_truck: haul_trucks, location: locations}
  end

  # defp inspect_times(l) do
  #   Enum.map(l, fn i ->
  #     IO.inspect([start: i.start_time, end: i.end_time])
  #   end)
  # end

  defp combine_overlapping(input, acc \\ [], overlap_count \\ 0)
  defp combine_overlapping([], [], _), do: []
  defp combine_overlapping([next], acc, _), do: [format_output(next) | acc]

  defp combine_overlapping([prev, next | tail], acc, overlap_count) do
    prev_end = prev.end_time
    next_start = next.start_time
    latest = Enum.max([prev_end, next_start], NaiveDateTime)
    prev_duration = duration(prev)

    cond do
      overlap_count >= 40 ->
      # give up after too many overlaps
        Logger.error("Too many overlaps, ending early to prevent applcation crash")
        acc

      # skip zero duration
      prev_duration == 0 ->
        combine_overlapping([next | tail], acc, overlap_count)

      # skip invalid prev (negative duration)
      prev_duration < 0 ->
        Logger.error("Negative duration should not be possible: #{inspect(prev)}")
        combine_overlapping([next | tail], acc, overlap_count)

      # combine sequential time usage of the same cycle and type
      # uses next because it should be closer to the load
      prev.haul_truck == next.haul_truck and
        prev.time_usage_type == next.time_usage_type and
          prev_end == next_start ->
        combined = Map.put(next, :start_time, prev.start_time)

        [combined | tail]
        |> combine_overlapping(acc, overlap_count)

      # no overlap, emit prev and continue
      latest == next_start ->
        prev = format_output(prev)
        combine_overlapping([next | tail], [prev | acc], overlap_count)

      # handle overlap
      latest == prev_end ->
        overlap = build_overlap(prev, next)
        new_prev = Map.put(prev, :end_time, next_start)
        new_next = Map.put(next, :start_time, prev_end)

        new_next =
          if duration(new_next) < 0 do
            %{prev | start_time: next.end_time, end_time: prev.end_time}
          else
            new_next
          end

        if duration(new_prev) < 0 || duration(new_next) < 0 || duration(overlap) < 0 do
          throw("""
          negative duration in overlap calculation
          time usages: #{inspect([new_prev, overlap, new_next])})
          """)
        end

        if duration(new_next) == 0 do
          [new_prev, overlap | tail]
        else
          [new_prev, overlap, new_next | tail]
        end

        # needs to be sorted in case next's new start time is after the next next start time
        |> Enum.sort_by(& &1.start_time, NaiveDateTime)
        |> combine_overlapping(acc, overlap_count + 1)
    end
  end

  defp build_overlap(prev, next) do
    time_usage_type =
      if prev.time_usage_type == "QueueAtLoad" ||
           prev.time_usage_type == "Multiple QueueAtLoad" do
        "Multiple QueueAtLoad"
      else
        "Overlapping Cycles"
      end

    overlap_haul_truck =
      case {prev.haul_truck, next.haul_truck} do
        {%MapSet{}, %MapSet{}} -> MapSet.union(prev.haul_truck, next.haul_truck)
        {%MapSet{}, _} -> MapSet.put(prev.haul_truck, next.haul_truck)
        {_, %MapSet{}} -> MapSet.put(next.haul_truck, prev.haul_truck)
        _ -> MapSet.new([prev.haul_truck, next.haul_truck])
      end

    overlap_location = prev.location ++ next.location

    %{
      haul_truck: overlap_haul_truck,
      time_usage_type: time_usage_type,
      start_time: next.start_time,
      end_time: prev.end_time,
      location: overlap_location
    }
  end

  # queries
  defmacrop coalesce_loader_id(distance_loader, manual_loader) do
    quote do
      coalesce(unquote(distance_loader).id, unquote(manual_loader).id)
    end
  end

  defmacrop duration_seconds(start_time, end_time) do
    quote do
      fragment("COALESCE(EXTRACT(epoch FROM(? - ?)), 0)", unquote(end_time), unquote(start_time))
    end
  end

  defp query_excavator_events(asset_id, start_time, end_time, time_usage_types) do
    {asset_id, ""} = Integer.parse(asset_id)

    from(c in Haul.Cycle,
      join: ll in Dim.LocationHistory,
      on: [id: c.location_history_load_id],
      join: ld in Dim.LocationHistory,
      on: [id: c.location_history_dump_id],
      join: l in Dim.Location,
      on: [id: ll.location_id],
      join: ht in Dim.HaulTruck,
      on: c.haul_truck_id == ht.id,
      where: c.end_time >= ^start_time,
      where: c.start_time <= ^end_time,

      # join distance excavator
      left_join: lca in Loader.CycleAssoc,
      on: [cycle_id: c.id],
      left_join: distance_excavator in Asset,
      on: [id: lca.loader_id],
      # join manual excavator
      left_join: ml in ManualLoader,
      on: [
        shift_id: c.calendar_id,
        load_location_id: ll.location_id,
        dump_location_id: ld.location_id
      ],
      left_join: manual_excavator in Asset,
      on: [id: ml.loader_id],
      # where has loader id
      where: ^asset_id == coalesce_loader_id(distance_excavator, manual_excavator),

      # tu
      join: tu in Haul.TimeUsage,
      on: [cycle_id: c.id],
      join: tut in Dim.TimeUsage,
      on: [id: tu.time_usage_type_id],
      left_join: lh in Dim.LocationHistory,
      on: [id: tu.location_history_id],
      where: tut.secondary in ^time_usage_types,
      where: duration_seconds(c.start_time, c.end_time) < 1200,

      # aggregation
      order_by: [min(tu.start_time)],
      group_by: [ht.asset_name, tut.secondary, tu.cycle_id],
      select: %{
        haul_truck: ht.asset_name,
        time_usage_type: tut.secondary,
        cycle_id: tu.cycle_id,
        location: fragment("ARRAY_AGG(?)", lh.name),
        start_time: min(tu.start_time),
        end_time: max(tu.end_time)
      }
    )
    |> Repo.all()
  end
end
