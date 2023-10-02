defmodule FleetControl.DigUnitActivity.AgentUpdateTest do
  use FleetControlWeb.RepoCase

  alias FleetControl.Helper
  alias FleetControl.CalendarAgent
  alias FleetControl.AssetAgent
  alias FleetControl.DigUnitActivityAgent

  alias HpsData.Schemas.Dispatch.DigUnitActivity
  alias HpsData.Schemas.Dispatch.MaterialType

  import ExUnit.CaptureLog

  setup do
    material_types =
      Repo.all(MaterialType)
      |> Enum.map(&{&1.id})

    CalendarAgent.start_link([])

    todays_calendar = CalendarAgent.get_current()

    yesterdays_calendar =
      CalendarAgent.get_at(NaiveDateTime.add(todays_calendar.shift_start, -60))

    AssetAgent.start_link([])
    [asset, asset_b | _] = AssetAgent.get_assets()

    dig_unit_activity = %{
      asset_id: asset.id,
      location_id: 10,
      material_type_id: 7,
      timestamp: ~N[2023-09-28 00:12:33.708323]
    }

    DigUnitActivityAgent.start_link([])
    DigUnitActivityAgent.add(dig_unit_activity)

    [
      asset: asset,
      asset_b: asset_b,
      material_types: material_types,
      calendar: yesterdays_calendar
    ]
  end

  defp update_all_with_logs(updates) do
    {result, log} = with_log(fn -> DigUnitActivityAgent.update_all(updates) end)
    assert log =~ ""
    result
  end

  describe "Update all -" do
    test "valid (create new active dig unit activity, no existing)", %{
      asset: asset,
      material_types: material_types
    } do
      start_time = NaiveDateTime.utc_now()

      new_activity = %{
        asset_id: asset.id,
        material_type_id: 3,
        start_time: start_time
      }

      {:ok, deleted, [activity]} = update_all_with_logs([new_activity])

      # return
      assert deleted == []
      assert activity.asset_id == new_activity.asset_id
      assert activity.material_type_id == new_activity.material_type_id
      assert activity.timestamp == new_activity.start_time

      # store
      [current] = DigUnitActivityAgent.current()
      [historic] = DigUnitActivityAgent.historic()
      assert current.material_type_id == new_activity.material_type_id
      assert current.asset_id == new_activity.asset_id
      assert current.timestamp == new_activity.start_time

      # database
      assert_db_count(DigUnitActivity, 1, 0)
      assert_db_contains(DigUnitActivity, current)
      assert_db_contains(DigUnitActivity, historic)
    end

    test "valid (create new completed dig unit activity, no existing)", %{
      asset: asset,
      material_types: material_types
    } do
      end_time = NaiveDateTime.add(NaiveDateTime.utc_now(), -600)
      start_time = NaiveDateTime.add(end_time, -3600)

      new_activity = %{
        asset_id: asset.id,
        material_type_id: 4,
        start_time: start_time,
        end_time: end_time
      }

      {:ok, deleted, [activity]} = update_all_with_logs([new_activity])

      # return
      assert deleted == []

      assert activity.asset_id == new_activity.asset_id
      assert activity.material_type_id == new_activity.material_type_id
      assert activity.timestamp == new_activity.start_time

      # store
      [current] = DigUnitActivityAgent.current()
      [historic] = DigUnitActivityAgent.historic()
      assert current.material_type_id == new_activity.material_type_id
      assert current.asset_id == new_activity.asset_id
      assert current.timestamp == new_activity.start_time

      # database
      assert_db_count(DigUnitActivity, 1, 0)
      assert_db_contains(DigUnitActivity, current)
      assert_db_contains(DigUnitActivity, historic)
    end

    test "valid (change existing dig unit activity)", %{
      asset: asset,
      material_types: material_types
    } do
      end_time = NaiveDateTime.add(NaiveDateTime.utc_now(), -600)
      start_time = NaiveDateTime.add(end_time, -3600)

      activity = %{
        asset_id: asset.id,
        material_type_id: 6,
        timestamp: start_time
      }

      {:ok, existing_activity} = DigUnitActivityAgent.add(activity)

      changed_existing_activity = %{
        id: existing_activity.id,
        asset_id: existing_activity.asset_id,
        material_type_id: 10,
        start_time: NaiveDateTime.add(NaiveDateTime.utc_now(), -1600)
      }

      {:ok, [deleted], [activity]} = update_all_with_logs([changed_existing_activity])

      # return
      assert deleted.id == existing_activity.id
      assert deleted.asset_id == existing_activity.asset_id
      assert deleted.material_type_id == existing_activity.material_type_id

      assert activity.asset_id == changed_existing_activity.asset_id
      assert activity.material_type_id == changed_existing_activity.material_type_id
      assert activity.timestamp == changed_existing_activity.start_time

      # store
      [current] = DigUnitActivityAgent.current()

      assert current.material_type_id == activity.material_type_id
      assert current.asset_id == activity.asset_id
      assert current.timestamp == activity.timestamp

      # database
      assert_db_count(DigUnitActivity, 1, 0)
      assert_db_contains(DigUnitActivity, current)
    end
  end
end
