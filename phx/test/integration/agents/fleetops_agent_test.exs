defmodule Dispatch.FleetopsAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{CalendarAgent, FleetOpsAgent}
  alias HpsData.{Dim, Fleet}

  setup_all _ do
    [asset | _] = Repo.all(Dim.Asset)
    CalendarAgent.start_link([])
    calendars = CalendarAgent.shifts()

    locations = Repo.all(Dim.LocationHistory)

    tu_types =
      Dim.TimeUsage
      |> Repo.all()
      |> Enum.map(&{String.to_atom(&1.secondary), &1.id})
      |> Enum.into(%{})

    [asset: asset, locations: locations, calendars: calendars, tu_types: tu_types]
  end

  setup _ do
    FleetOpsAgent.start_link([])
    :ok
  end

  defp between(start_time, end_time, timestamp) do
    NaiveDateTime.compare(timestamp, start_time) != :lt and
      NaiveDateTime.compare(timestamp, end_time) == :lt
  end

  defp make_cycle(
         %{locations: locations, calendars: calendars, tu_types: tu_types},
         asset_id,
         start_time,
         load,
         dump,
         timeusage
       ) do
    total_duration = Enum.reduce(timeusage, 0, fn {_, duration}, acc -> acc + duration end)
    end_time = NaiveDateTime.add(start_time, total_duration)
    calendar = Enum.find(calendars, &between(&1.shift_start, &1.shift_end, end_time))

    load_id = Enum.find(locations, &(&1.name == load)).id
    dump_id = Enum.find(locations, &(&1.name == dump)).id

    Repo.transaction(fn ->
      cycle =
        Repo.insert!(%Fleet.Cycle{
          asset_id: asset_id,
          calendar_id: calendar.id,
          start_time: start_time,
          end_time: end_time,
          location_history_start_id: nil,
          location_history_load_id: load_id,
          location_history_dump_id: dump_id,
          distance_travelled: 1000.0,
          empty_haul_duration: timeusage[:EmptyHaul],
          queue_at_load_duration: timeusage[:QueueAtLoad],
          spot_at_load_duration: timeusage[:SpotAtLoad],
          loading_duration: timeusage[:Loading],
          full_haul_duration: timeusage[:FullHaul],
          queue_at_dump_duration: timeusage[:QueueAtDump],
          spot_at_dump_duration: timeusage[:SpotAtDump],
          dumping_duration: timeusage[:Dumping],
          crib_duration: 0,
          changeover_empty_duration: 0,
          changeover_full_duration: 0
        })

      tu_elements =
        Enum.reduce(timeusage, {[], start_time}, fn {type, duration},
                                                    {tu_elements, tu_start_time} ->
          calendar = Enum.find(calendars, &between(&1.shift_start, &1.shift_end, tu_start_time))
          tu_end_time = NaiveDateTime.add(tu_start_time, duration)

          tu_loc_id =
            case type do
              :spot_at_load -> load_id
              :loading -> load_id
              :spot_at_dumo -> dump_id
              :dumping -> dump_id
              _ -> nil
            end

          transmission =
            cond do
              Enum.member?([:empty_haul, :full_haul], type) -> 1
              Enum.member?([:spot_at_load, :spot_at_dump], type) -> -1
              true -> 0
            end

          tu_element = %{
            cycle_id: cycle.id,
            asset_id: asset_id,
            calendar_id: calendar.id,
            start_time: tu_start_time,
            end_time: tu_end_time,
            location_history_id: tu_loc_id,
            transmission: transmission,
            latitude: 0.0,
            longitude: 0.0,
            distance: 0.0,
            time_usage_type_id: tu_types[type],
            duration: NaiveDateTime.diff(tu_end_time, tu_start_time)
          }

          {[tu_element | tu_elements], tu_end_time}
        end)
        |> elem(0)

      Repo.insert_all(Fleet.TimeUsage, tu_elements)
    end)
  end

  test "insert cycles then update", %{asset: asset} = context do
    assert length(FleetOpsAgent.cycles()) == 0
    assert length(FleetOpsAgent.timeusage()) == 0

    tu_durations = [
      EmptyHaul: 300,
      QueueAtLoad: 0,
      SpotAtLoad: 20,
      Loading: 300,
      FullHaul: 300,
      QueueAtDump: 0,
      SpotAtDump: 20,
      Dumping: 30
    ]

    make_cycle(
      context,
      asset.id,
      ~N[2020-01-01 00:00:00.000000],
      "Stock 01",
      "Crusher",
      tu_durations
    )

    FleetOpsAgent.refresh!(~N[2020-01-01 01:00:00])

    assert length(FleetOpsAgent.cycles()) == 1
    assert length(FleetOpsAgent.timeusage()) != 0
  end

  describe "fetch by range! -" do
    test "cycle completely within range", %{asset: asset} = context do
      tu_durations = [
        EmptyHaul: 300,
        QueueAtLoad: 0,
        SpotAtLoad: 20,
        Loading: 300,
        FullHaul: 300,
        QueueAtDump: 0,
        SpotAtDump: 20,
        Dumping: 30
      ]

      make_cycle(
        context,
        asset.id,
        ~N[2020-01-01 01:00:00.000000],
        "Stock 01",
        "Crusher",
        tu_durations
      )

      %{cycles: cycles, timeusage: timeusage} =
        FleetOpsAgent.fetch_by_range!(%{
          start_time: ~N[2020-01-01 00:00:00],
          end_time: ~N[2020-01-01 02:00:00]
        })

      assert length(cycles) == 1
      assert length(timeusage) != 0
    end

    test "cycle ending in range", %{asset: asset} = context do
      tu_durations = [
        EmptyHaul: 300,
        QueueAtLoad: 0,
        SpotAtLoad: 20,
        Loading: 300,
        FullHaul: 300,
        QueueAtDump: 0,
        SpotAtDump: 20,
        Dumping: 30
      ]

      make_cycle(
        context,
        asset.id,
        ~N[2020-01-01 01:00:00.000000],
        "Stock 01",
        "Crusher",
        tu_durations
      )

      %{cycles: cycles, timeusage: timeusage} =
        FleetOpsAgent.fetch_by_range!(%{
          start_time: ~N[2020-01-01 01:05:00],
          end_time: ~N[2020-01-01 02:00:00]
        })

      assert length(cycles) == 1
      assert length(timeusage) != 0
    end

    test "cycle starting in range", %{asset: asset} = context do
      tu_durations = [
        EmptyHaul: 300,
        QueueAtLoad: 0,
        SpotAtLoad: 20,
        Loading: 300,
        FullHaul: 300,
        QueueAtDump: 0,
        SpotAtDump: 20,
        Dumping: 30
      ]

      make_cycle(
        context,
        asset.id,
        ~N[2020-01-01 01:00:00.000000],
        "Stock 01",
        "Crusher",
        tu_durations
      )

      %{cycles: cycles, timeusage: timeusage} =
        FleetOpsAgent.fetch_by_range!(%{
          start_time: ~N[2020-01-01 00:00:00],
          end_time: ~N[2020-01-01 01:05:00]
        })

      assert length(cycles) == 1
      assert length(timeusage) != 0
    end

    test "cycle covering range", %{asset: asset} = context do
      tu_durations = [
        EmptyHaul: 300,
        QueueAtLoad: 0,
        SpotAtLoad: 20,
        Loading: 300,
        FullHaul: 300,
        QueueAtDump: 0,
        SpotAtDump: 20,
        Dumping: 30
      ]

      make_cycle(
        context,
        asset.id,
        ~N[2020-01-01 01:00:00.000000],
        "Stock 01",
        "Crusher",
        tu_durations
      )

      %{cycles: cycles, timeusage: timeusage} =
        FleetOpsAgent.fetch_by_range!(%{
          start_time: ~N[2020-01-01 01:01:00],
          end_time: ~N[2020-01-01 01:02:00]
        })

      assert length(cycles) == 1
      assert length(timeusage) != 0
    end

    test "cycles outside of range", %{asset: asset} = context do
      tu_durations = [
        EmptyHaul: 300,
        QueueAtLoad: 0,
        SpotAtLoad: 20,
        Loading: 300,
        FullHaul: 300,
        QueueAtDump: 0,
        SpotAtDump: 20,
        Dumping: 30
      ]

      make_cycle(
        context,
        asset.id,
        ~N[2020-01-01 01:00:00.000000],
        "Stock 01",
        "Crusher",
        tu_durations
      )

      %{cycles: cycles, timeusage: timeusage} =
        FleetOpsAgent.fetch_by_range!(%{
          start_time: ~N[2020-01-02 00:00:00],
          end_time: ~N[2020-01-02 01:00:00]
        })

      assert length(cycles) == 0
      assert length(timeusage) == 0
    end
  end
end
