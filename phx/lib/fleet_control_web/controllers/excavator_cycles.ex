defmodule FleetControlWeb.ExcavatorCyclesController do
  @moduledoc nil

  use FleetControlWeb, :controller

  import Ecto.Query, only: [from: 2]

  def fetch_cycles(
        conn,
        %{"asset_id" => asset_id, "start_time" => start_time, "end_time" => end_time}
      ) do
    query_excavator_events(asset_id, start_time, end_time, ["SpotAtLoad", "Loading"])
    |> combine_overlapping()
  end

  def fetch_queue(
        conn,
        %{"asset_id" => asset_id, "start_time" => start_time, "end_time" => end_time}
      ) do
    query_excavator_events(asset_id, start_time, end_time, ["QueueAtLoad"])
    |> combine_overlapping()
  end

  defp combine_overlapping([prev, next | tail], acc \\ []) do
    prev_end = prev.end_time
    next_start = next.start_time
    latest = Enum.max([prev_end, next_start], NaiveDateTime)

    prev_duration = NaiveDateTime.diff(prev_end, prev.start_time)

    cond do
      prev_duration <= 0 ->
        # skip invalid prev (negative duration)
        combine_overlapping([next | tail], acc)

      latest == next_start ->
        # no overlap, emit prev and continue
        combine_overlapping([next | tail], [prev | acc])

      # overlap, combine prev and next into one element, sort remaining elements
      latest == prev_end ->
        prev = Map.put(prev, :end_time, next_start)
        next = Map.put(next, :start_time, prev_end)

        overlap = %{
          haul_truck: prev.haul_truck <> " | " <> next.haul_truck,
          time_usage_type: "overlap",
          start_time: prev_end,
          end_time: next_start
        }

        combine_overlapping([prev | tail], acc)
    end
  end

  # queries
  defmacrop coalesce_loader_id(distance_loader, manual_loader) do
    quote do
      coalesce(unquote(distance_loader).id, unquote(manual_loader).id)
    end
  end

  defp query_excavator_events(asset_id, start_time, end_time, time_usage_types) do
    base_query =
      from(tu in Haul.TimeUsage,
        join: tut in Dim.TimeUsage,
        on: [id: tu.time_usage_type_id],
        join: c in Haul.Cycle,
        on: [id: tu.cycle_id],
        join: ll in Dim.LocationHistory,
        on: [id: c.location_history_load_id],
        join: ld in Dim.LocationHistory,
        on: [id: c.location_history_dump_id],
        join: l in Dim.Location,
        on: [id: ll.location_id],
        join: ht in Dim.HaulTruck,
        on: c.haul_truck_id == ht.id,
        where: tu.end_time >= ^start_time,
        where: tu.start_time <= ^end_time,
        where: tut.secondary in ^time_usage_types
      )

    from([tu, tut, c, ll, ld, _l, ht] in base_query,
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
      order_by: [tu.start_time],
      select: %{
        haul_truck: ht.asset_name,
        time_usage_type: tut.secondary,
        start_time: tu.start_time,
        end_time: tu.end_time
      }
    )
  end
end
