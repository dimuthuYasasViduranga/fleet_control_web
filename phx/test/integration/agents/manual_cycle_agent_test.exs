defmodule Dispatch.ManualCycleAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{AssetAgent, OperatorAgent, MaterialTypeAgent, ManualCycleAgent}
  alias HpsData.Dim
  alias HpsData.Schemas.Dispatch.ManualCycle

  setup_all _ do
    [location_a, location_b | _] =
      Dim.Location
      |> Repo.all()
      |> Enum.map(&Map.from_struct/1)

    AssetAgent.start_link([])
    [asset | _] = AssetAgent.get_assets(%{type: "Haul Truck"})
    [excavator | _] = AssetAgent.get_assets(%{type: "Excavator"})

    OperatorAgent.start_link([])
    [operator | _] = OperatorAgent.active()

    MaterialTypeAgent.start_link([])
    [material | _] = MaterialTypeAgent.get()

    [
      location_a: location_a,
      location_b: location_b,
      asset: asset,
      excavator: excavator,
      operator: operator,
      material: material
    ]
  end

  setup _ do
    ManualCycleAgent.start_link([])
    :ok
  end

  defp to_manual_cycle(
         asset_id,
         operator_id,
         start_time,
         end_time,
         load_unit_id,
         load_location_id,
         dump_location_id,
         material_type_id,
         relative_level,
         shot,
         timestamp
       ) do
    %{
      asset_id: asset_id,
      operator_id: operator_id,
      start_time: start_time,
      end_time: end_time,
      load_unit_id: load_unit_id,
      load_location_id: load_location_id,
      dump_location_id: dump_location_id,
      material_type_id: material_type_id,
      relative_level: relative_level,
      shot: shot,
      timestamp: timestamp
    }
  end

  defp get_cycle(context, start_time, end_time, rl, shot, timestamp \\ NaiveDateTime.utc_now()) do
    to_manual_cycle(
      context.asset.id,
      context.operator.id,
      start_time,
      end_time,
      context.excavator.id,
      context.location_a.id,
      context.location_b.id,
      context.material.id,
      rl,
      shot,
      timestamp
    )
  end

  defp merge_missing_keys(cycle, actual) do
    %{
      id: actual.id,
      asset_id: cycle.asset_id,
      operator_id: cycle.operator_id,
      start_time: cycle.start_time,
      end_time: cycle.end_time,
      load_unit_id: cycle.load_unit_id,
      load_location_id: cycle.load_location_id,
      dump_location_id: cycle.dump_location_id,
      material_type_id: cycle.material_type_id,
      relative_level: cycle.relative_level,
      shot: cycle.shot,
      timestamp: cycle.timestamp,
      deleted: actual.deleted,
      server_timestamp: actual.server_timestamp
    }
  end

  describe "add -" do
    test "valid", context do
      start_time = ~N[2020-01-01 00:00:00.000000]
      end_time = ~N[2020-01-01 01:00:00.000000]
      relative_level = "-600"
      shot = "RG-256"

      manual_cycle = get_cycle(context, start_time, end_time, relative_level, shot)

      {:ok, actual} = ManualCycleAgent.add(manual_cycle)

      expected = merge_missing_keys(manual_cycle, actual)

      # return
      assert actual == expected

      # store (old cycle)
      assert ManualCycleAgent.get() == []

      # database
      assert_db_contains(ManualCycle, actual)
    end

    test "invalid (invalid asset id)", context do
      manual_cycle =
        get_cycle(
          context,
          ~N[2020-01-01 00:00:00.000000],
          ~N[2020-01-01 01:00:00.000000],
          "600",
          "7"
        )
        |> Map.put(:asset_id, -1)

      actual = ManualCycleAgent.add(manual_cycle)

      assert_ecto_error(actual)
    end

    test "invalid (missing values)", %{asset: asset} do
      manual_cycle = %{asset_id: asset.id}

      actual = ManualCycleAgent.add(manual_cycle)
      assert_ecto_error(actual)
    end
  end

  describe "edit -" do
    test "valid", context do
      timestamp = ~N[2020-05-01 00:00:00.000000]
      new_end_time = ~N[2020-01-01 02:00:00.000000]

      {:ok, initial_cycle} =
        get_cycle(
          context,
          ~N[2020-01-01 00:00:00],
          ~N[2020-01-01 01:00:00],
          "600",
          "Shot",
          timestamp
        )
        |> ManualCycleAgent.add()

      {:ok, edited_cycle} =
        initial_cycle
        |> Map.put(:end_time, new_end_time)
        |> ManualCycleAgent.edit()

      [db_deleted, db_edited] =
        ManualCycle
        |> Repo.all()
        |> Enum.map(&ManualCycle.to_map/1)

      # return
      assert initial_cycle.deleted == false

      # store (old cycles)
      assert ManualCycleAgent.get() == []

      # database
      assert initial_cycle != db_deleted
      assert Map.put(initial_cycle, :deleted, true) == db_deleted
      assert edited_cycle == db_edited
    end

    test "valid (through add with id)", context do
      timestamp = ~N[2020-05-01 00:00:00.000000]
      new_end_time = ~N[2020-01-01 02:00:00.000000]

      {:ok, initial_cycle} =
        get_cycle(
          context,
          ~N[2020-01-01 00:00:00],
          ~N[2020-01-01 01:00:00],
          "600",
          "Shot",
          timestamp
        )
        |> ManualCycleAgent.add()

      {:ok, edited_cycle} =
        initial_cycle
        |> Map.put(:end_time, new_end_time)
        |> ManualCycleAgent.add()

      [db_deleted, db_edited] =
        ManualCycle
        |> Repo.all()
        |> Enum.map(&ManualCycle.to_map/1)

      # return
      assert initial_cycle.deleted == false

      # store (old cycles)
      assert ManualCycleAgent.get() == []

      # database
      assert initial_cycle != db_deleted
      assert Map.put(initial_cycle, :deleted, true) == db_deleted
      assert edited_cycle == db_edited
    end

    test "invalid (asset id)", context do
      {:ok, initial_cycle} =
        get_cycle(
          context,
          ~N[2020-01-01 00:00:00],
          ~N[2020-01-01 01:00:00],
          "600",
          "Shot"
        )
        |> ManualCycleAgent.add()

      actual =
        initial_cycle
        |> Map.put(:asset_id, -1)
        |> ManualCycleAgent.edit()

      assert_ecto_error(actual)
    end

    test "invalid (id)", context do
      actual =
        get_cycle(
          context,
          ~N[2020-01-01 00:00:00],
          ~N[2020-01-01 01:00:00],
          "600",
          "Shot"
        )
        |> Map.put(:id, -1)
        |> ManualCycleAgent.edit()

      assert actual == {:error, :delete_old, :invalid_id, %{}}
    end

    test "invalid (nil id)", context do
      actual =
        get_cycle(
          context,
          ~N[2020-01-01 00:00:00],
          ~N[2020-01-01 01:00:00],
          "600",
          "Shot"
        )
        |> ManualCycleAgent.edit()

      assert actual == {:error, :invalid_id}
    end
  end

  describe "delete -" do
    test "valid", context do
      {:ok, initial} =
        get_cycle(
          context,
          ~N[2020-01-01 00:00:00],
          ~N[2020-01-01 01:00:00],
          "600",
          "Shot"
        )
        |> ManualCycleAgent.add()

      {:ok, deleted} = ManualCycleAgent.delete(initial.id, ~N[2020-01-01 00:00:00.000000])

      # return
      assert initial.deleted == false
      assert deleted.deleted == true
      assert initial.id == deleted.id

      # store (old cycles)
      assert ManualCycleAgent.get() == []

      # database
      assert_db_contains(ManualCycle, deleted)
      refute_db_contains(ManualCycle, initial)
    end

    test "invalid (id)" do
      actual = ManualCycleAgent.delete(-1, NaiveDateTime.utc_now())
      assert actual == {:error, :invalid_id}
    end

    test "invalid (already deleted)", context do
      now = NaiveDateTime.utc_now()
      end_time = NaiveDateTime.add(now, -60)
      start_time = NaiveDateTime.add(end_time, -60)

      {:ok, initial} =
        get_cycle(
          context,
          start_time,
          end_time,
          "600",
          "Shot"
        )
        |> ManualCycleAgent.add()

      {:ok, deleted} = ManualCycleAgent.delete(initial.id, now)

      error = ManualCycleAgent.delete(initial.id, now)

      # return
      assert error == {:error, :already_deleted}

      # store
      assert ManualCycleAgent.get() == [deleted]

      # database
      assert_db_contains(ManualCycle, deleted)
      assert_db_contains(ManualCycle, Map.put(initial, :deleted, true))
      refute_db_contains(ManualCycle, initial)
    end
  end

  describe "fetch by range! -" do
    test "no cycles within range" do
      range = %{start_time: ~N[2020-01-01 00:00:00], end_time: ~N[2020-01-01 01:00:00]}

      actual = ManualCycleAgent.fetch_by_range!(range)
      assert actual == []
    end

    test "cycle start within range", context do
      range = %{start_time: ~N[2020-01-01 00:30:00], end_time: ~N[2020-01-01 01:30:00]}

      {:ok, cycle} =
        get_cycle(
          context,
          ~N[2020-01-01 01:00:00],
          ~N[2020-01-01 02:00:00],
          "600",
          "Shot"
        )
        |> ManualCycleAgent.add()

      actual = ManualCycleAgent.fetch_by_range!(range)
      assert actual == [cycle]
    end

    test "cycle end within range", context do
      range = %{start_time: ~N[2020-01-01 01:30:00], end_time: ~N[2020-01-01 02:30:00]}

      {:ok, _} =
        get_cycle(
          context,
          ~N[2020-01-01 01:00:00],
          ~N[2020-01-01 02:00:00],
          "600",
          "Shot"
        )
        |> ManualCycleAgent.add()

      actual = ManualCycleAgent.fetch_by_range!(range)
      assert actual == []
    end

    test "cycle completely within range", context do
      range = %{start_time: ~N[2020-01-01 00:00:00], end_time: ~N[2020-01-01 03:00:00]}

      {:ok, cycle} =
        get_cycle(
          context,
          ~N[2020-01-01 01:00:00],
          ~N[2020-01-01 02:00:00],
          "600",
          "Shot"
        )
        |> ManualCycleAgent.add()

      actual = ManualCycleAgent.fetch_by_range!(range)
      assert actual == [cycle]
    end

    test "cycle covers range", context do
      range = %{start_time: ~N[2020-01-01 01:15:00], end_time: ~N[2020-01-01 01:45:00]}

      {:ok, _} =
        get_cycle(
          context,
          ~N[2020-01-01 01:00:00],
          ~N[2020-01-01 02:00:00],
          "600",
          "Shot"
        )
        |> ManualCycleAgent.add()

      actual = ManualCycleAgent.fetch_by_range!(range)
      assert actual == []
    end
  end
end
