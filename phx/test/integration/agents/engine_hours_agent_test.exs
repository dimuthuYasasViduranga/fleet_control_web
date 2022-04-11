defmodule Dispatch.EngineHoursAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{AssetAgent, EngineHoursAgent}
  alias HpsData.Schemas.Dispatch.EngineHours

  defp to_engine_hours(asset_id, hours, timestamp \\ NaiveDateTime.utc_now()) do
    %{
      asset_id: asset_id,
      hours: hours,
      timestamp: timestamp,
      deleted: false
    }
  end

  setup_all _ do
    AssetAgent.start_link([])
    [asset | _] = AssetAgent.get_assets(%{type: "Haul Truck"})
    [asset: asset]
  end

  setup do
    EngineHoursAgent.start_link([])
    :ok
  end

  describe "new -" do
    test "valid", %{asset: asset} do
      now = NaiveDateTime.utc_now()
      hours = 100
      eh = to_engine_hours(asset.id, hours, now)

      {:ok, actual} = EngineHoursAgent.new(eh)

      # return
      assert actual.asset_id == asset.id
      assert actual.hours == hours
      assert NaiveDateTime.compare(actual.timestamp, now) == :eq
      assert actual.deleted == false

      # store
      assert EngineHoursAgent.current() == [actual]
      assert EngineHoursAgent.historic() == [actual]

      # database
      assert_db_contains(EngineHours, actual)
    end

    test "invalid (missing asset_id)" do
      actual = EngineHoursAgent.new(to_engine_hours(-1, 100))
      assert_ecto_error(actual)
    end

    test "invalid (missing hours)", %{asset: asset} do
      actual = EngineHoursAgent.new(to_engine_hours(asset.id, nil))
      assert_ecto_error(actual)
    end

    test "invalid (future hours)", %{asset: asset} do
      future = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600)
      actual = EngineHoursAgent.new(to_engine_hours(asset.id, 100, future))
      assert_ecto_error(actual)
    end
  end

  describe "fetch by range! -" do
    test "range with data", %{asset: asset} do
      end_time = NaiveDateTime.utc_now()
      steps = 5
      start_time = NaiveDateTime.add(end_time, -steps * 3600)

      inserts =
        Enum.map(0..(steps - 1), fn hours ->
          timestamp = NaiveDateTime.add(start_time, hours * 3600)
          {:ok, eh} = EngineHoursAgent.new(to_engine_hours(asset.id, hours, timestamp))
          eh
        end)
        |> Enum.reverse()

      actual = EngineHoursAgent.fetch_by_range!(%{start_time: start_time, end_time: end_time})

      # return
      assert length(actual) == steps

      # store
      assert EngineHoursAgent.current() == [List.first(inserts)]
      assert EngineHoursAgent.historic() == inserts

      # database
      assert_db_contains(EngineHours, inserts)
    end

    test "range completely without data" do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = ~N[2020-02-01 00:00:00]

      actual = EngineHoursAgent.fetch_by_range!(%{start_time: start_time, end_time: end_time})

      # return
      assert length(actual) == 0

      # store
      assert EngineHoursAgent.current() == []
      assert EngineHoursAgent.historic() == []

      # database
      assert length(Repo.all(EngineHours)) == 0
    end

    test "includes 1 before, within and after range ", %{asset: asset} do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = ~N[2020-02-01 00:00:00]

      before_start = NaiveDateTime.add(start_time, -3600)
      within_range = NaiveDateTime.add(start_time, 3600)
      after_end = NaiveDateTime.add(end_time, 3600)

      {:ok, a} = EngineHoursAgent.new(to_engine_hours(asset.id, 100, before_start))
      {:ok, b} = EngineHoursAgent.new(to_engine_hours(asset.id, 101, within_range))
      {:ok, c} = EngineHoursAgent.new(to_engine_hours(asset.id, 400, after_end))

      actual = EngineHoursAgent.fetch_by_range!(%{start_time: start_time, end_time: end_time})

      # return
      assert length(actual) == 3

      # store
      assert EngineHoursAgent.current() == [c]
      # no historic because data is very old
      assert EngineHoursAgent.historic() == []

      # database
      assert_db_contains(EngineHours, [c, b, a])
    end
  end
end
