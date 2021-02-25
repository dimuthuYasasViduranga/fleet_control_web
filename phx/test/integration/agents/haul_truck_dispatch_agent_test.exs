defmodule Dispatch.HaulTruckDispatchAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{Helper, AssetAgent, HaulTruckDispatchAgent}
  alias HpsData.Dim.Location
  alias HpsData.Schemas.Dispatch.HaulDispatch

  setup_all _ do
    AssetAgent.start_link([])
    [asset, asset_b] = AssetAgent.get_assets(%{type: "Haul Truck"})

    [dig_unit | _] = AssetAgent.get_assets(%{type: "Excavator"})

    locations =
      Location
      |> Repo.all()
      |> Enum.map(&{&1.name, &1.id})
      |> Enum.into(%{})

    [asset: asset, asset_b: asset_b, dig_unit: dig_unit.id, locations: locations]
  end

  setup _ do
    HaulTruckDispatchAgent.start_link([])
    :ok
  end

  defp to_dispatch(asset_id, dig_unit, dump, timestamp \\ NaiveDateTime.utc_now()) do
    # added so that multiple calls dont result in the same timestamp (would make ordering random)
    :timer.sleep(2)

    %{
      asset_id: asset_id,
      dig_unit_id: dig_unit,
      load_location_id: nil,
      dump_location_id: dump,
      next_location_id: nil,
      timestamp: timestamp
    }
  end

  defp merge_missing_keys(dispatch, actual) do
    %{
      id: actual.id,
      group_id: actual.group_id,
      asset_id: dispatch.asset_id,
      dig_unit_id: dispatch.dig_unit_id,
      load_location_id: dispatch.load_location_id,
      dump_location_id: dispatch.dump_location_id,
      next_location_id: dispatch.next_location_id,
      timestamp: Helper.to_naive(dispatch.timestamp),
      server_timestamp: actual.server_timestamp,
      activity_id: nil,
      acknowledge_id: actual.acknowledge_id
    }
  end

  test "initially empty" do
    assert length(HaulTruckDispatchAgent.current()) == 0
  end

  describe "set/1 -" do
    test "valid (new current)", %{asset: asset, dig_unit: dig_unit, locations: locations} do
      dispatch = to_dispatch(asset.id, dig_unit, locations["WD 01"])
      {:ok, actual} = HaulTruckDispatchAgent.set(dispatch)

      expected = merge_missing_keys(dispatch, actual)

      # return
      assert actual == expected

      # store
      assert HaulTruckDispatchAgent.current() == [actual]
      assert HaulTruckDispatchAgent.historic() == [actual]

      # database
      assert_db_contains(HaulDispatch, actual)
    end

    test "valid (timestamp as unix)", %{asset: asset, dig_unit: dig_unit, locations: locations} do
      now = Helper.to_unix(NaiveDateTime.utc_now())
      dispatch = to_dispatch(asset.id, dig_unit, locations["WD 01"], now)
      {:ok, actual} = HaulTruckDispatchAgent.set(dispatch)

      expected = merge_missing_keys(dispatch, actual)

      # return
      assert actual == expected

      # store
      assert HaulTruckDispatchAgent.current() == [actual]
      assert HaulTruckDispatchAgent.historic() == [actual]

      # database
      assert_db_contains(HaulDispatch, actual)
    end

    test "valid (old dispatch -> store and forward case)", %{
      asset: asset,
      dig_unit: dig_unit,
      locations: locations
    } do
      dispatch = to_dispatch(asset.id, dig_unit, locations["WD 01"])

      old_dispatch = to_dispatch(asset.id, dig_unit, nil, ~N[2020-01-01 00:00:00])

      {:ok, first} = HaulTruckDispatchAgent.set(dispatch)
      {:ok, second} = HaulTruckDispatchAgent.set(old_dispatch)

      first_expected = merge_missing_keys(dispatch, first)
      second_expected = merge_missing_keys(old_dispatch, second)

      # return
      assert first == first_expected
      assert second == second_expected

      # store
      assert HaulTruckDispatchAgent.current() == [first]
      # old not in historic because date > 24 hours ago
      assert HaulTruckDispatchAgent.historic() == [first]

      # database
      assert_db_contains(HaulDispatch, [first, second])
    end

    test "valid (ignore load and next locations)", %{asset: asset, locations: locations} do
      dispatch =
        to_dispatch(asset.id, nil, nil)
        |> Map.put(:load_location_id, locations["Crusher"])
        |> Map.put(:next_location_id, locations["WD 01"])

      {:ok, actual} = HaulTruckDispatchAgent.set(dispatch)

      # return
      assert actual.load_location_id == nil
      assert actual.next_location_id == nil

      # store
      assert HaulTruckDispatchAgent.current() == [actual]
      assert HaulTruckDispatchAgent.historic() == [actual]

      # database
      assert_db_contains(HaulDispatch, actual)
    end

    test "invalid (invalid dig unit id)", %{asset: asset} do
      dispatch = to_dispatch(asset.id, -1, nil)
      actual = HaulTruckDispatchAgent.set(dispatch)
      assert_ecto_error(actual)
    end

    test "invalid (invalid dump location id)", %{asset: asset} do
      dispatch = to_dispatch(asset.id, nil, -1)
      actual = HaulTruckDispatchAgent.set(dispatch)
      assert_ecto_error(actual)
    end

    test "invalid (missing asset)" do
      dispatch = to_dispatch(nil, nil, nil)
      actual = HaulTruckDispatchAgent.set(dispatch)
      assert_ecto_error(actual)
    end

    test "invalid (invalid asset)" do
      dispatch = to_dispatch(-1, nil, nil)
      actual = HaulTruckDispatchAgent.set(dispatch)
      assert_ecto_error(actual)
    end

    test "invalid (no change)", %{asset: asset, dig_unit: dig_unit, locations: locations} do
      dispatch_a = to_dispatch(asset.id, dig_unit, locations["WD 01"])
      dispatch_b = to_dispatch(asset.id, dig_unit, locations["WD 01"])

      {:ok, initial} = HaulTruckDispatchAgent.set(dispatch_a)
      actual = HaulTruckDispatchAgent.set(dispatch_b)

      # return
      assert actual == {:error, :no_change}

      # store
      assert HaulTruckDispatchAgent.current() == [initial]
      assert HaulTruckDispatchAgent.historic() == [initial]

      # database
      assert_db_contains(HaulDispatch, initial)
    end

    test "invalid (future dispatch)", %{asset: asset} do
      future = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600)
      future_dispatch = to_dispatch(asset.id, nil, nil, future)

      actual = HaulTruckDispatchAgent.set(future_dispatch)

      assert_ecto_error(actual)
    end

    test "invalid (no timestamp)", %{asset: asset} do
      error =
        to_dispatch(asset.id, nil, nil, nil)
        |> HaulTruckDispatchAgent.set()

      assert_ecto_error(error)
    end
  end

  describe "mass set/3 -" do
    test "valid", %{asset: asset_a, asset_b: asset_b} do
      timestamp = NaiveDateTime.utc_now()
      dispatch = to_dispatch(nil, nil, nil, timestamp)

      {:ok, [actual_a, actual_b]} =
        HaulTruckDispatchAgent.mass_set([asset_a.id, asset_b.id], dispatch, timestamp)

      expected_a =
        dispatch
        |> merge_missing_keys(actual_a)
        |> Map.put(:timestamp, timestamp)
        |> Map.put(:asset_id, asset_a.id)

      expected_b =
        dispatch
        |> merge_missing_keys(actual_b)
        |> Map.put(:timestamp, timestamp)
        |> Map.put(:asset_id, asset_b.id)

      # return
      assert actual_a == expected_a
      assert actual_b == expected_b

      # store
      assert HaulTruckDispatchAgent.current() == [actual_b, actual_a]
      assert HaulTruckDispatchAgent.historic() == [actual_b, actual_a]

      # database
      assert_db_contains(HaulDispatch, [actual_a, actual_b])
    end

    test "valid (no assets)" do
      dispatch = to_dispatch(nil, nil, nil)
      actual = HaulTruckDispatchAgent.mass_set([], dispatch)
      assert actual == {:ok, []}
    end

    test "valid (duplicate assets)", %{asset: asset} do
      timestamp = NaiveDateTime.utc_now()
      dispatch = to_dispatch(nil, nil, nil, timestamp)

      {:ok, [actual]} = HaulTruckDispatchAgent.mass_set([asset.id, asset.id], dispatch, timestamp)

      expected =
        dispatch
        |> merge_missing_keys(actual)
        |> Map.put(:timestamp, timestamp)
        |> Map.put(:asset_id, asset.id)

      # return
      assert actual == expected

      # store
      assert HaulTruckDispatchAgent.current() == [actual]
      assert HaulTruckDispatchAgent.historic() == [actual]

      # database
      assert_db_contains(HaulDispatch, [actual])
    end

    test "valid (one nil asset)", %{asset: asset} do
      timestamp = NaiveDateTime.utc_now()
      dispatch = to_dispatch(nil, nil, nil, timestamp)

      {:ok, [actual]} = HaulTruckDispatchAgent.mass_set([nil, asset.id], dispatch, timestamp)

      expected =
        dispatch
        |> merge_missing_keys(actual)
        |> Map.put(:timestamp, timestamp)
        |> Map.put(:asset_id, asset.id)

      # return
      assert actual == expected

      # store
      assert HaulTruckDispatchAgent.current() == [actual]
      assert HaulTruckDispatchAgent.historic() == [actual]

      # database
      assert_db_contains(HaulDispatch, actual)
    end

    @tag :capture_log
    test "invalid (1 invalid asset)", %{asset: asset} do
      Process.flag(:trap_exit, true)
      dispatch = to_dispatch(nil, nil, nil)

      pid = Process.whereis(HaulTruckDispatchAgent)

      catch_exit do
        HaulTruckDispatchAgent.mass_set([-1, asset.id], dispatch)
      end

      assert_receive {
        :EXIT,
        ^pid,
        {%Postgrex.Error{}, _stack}
      }
    end

    test "invalid (invalid timestamp)", %{asset: asset} do
      dispatch = to_dispatch(asset.id, nil, nil, nil)
      error = HaulTruckDispatchAgent.mass_set([asset.id], dispatch, nil)
      assert error == {:error, :invalid_timestamp}
    end
  end

  describe "clear/1 -" do
    test "valid", %{asset: asset, dig_unit: dig_unit, locations: %{"Crusher" => crusher}} do
      dispatch = to_dispatch(asset.id, dig_unit, crusher)
      {:ok, initial} = HaulTruckDispatchAgent.set(dispatch)

      {:ok, cleared} = HaulTruckDispatchAgent.clear(asset.id)

      expected_initial = merge_missing_keys(dispatch, initial)

      # return
      assert initial == expected_initial
      assert cleared.load_location_id == nil
      assert cleared.dump_location_id == nil
      assert cleared.next_location_id == nil

      # store
      assert HaulTruckDispatchAgent.current() == [cleared]
      assert HaulTruckDispatchAgent.historic() == [cleared, initial]

      # database
      assert_db_contains(HaulDispatch, [initial, cleared])
    end

    test "invalid (missing asset)" do
      actual = HaulTruckDispatchAgent.clear(nil)
      assert actual == {:error, :no_asset}
    end

    test "invalid (invalid asset)" do
      actual = HaulTruckDispatchAgent.clear(-1)
      assert actual == {:error, :no_asset}
    end

    test "invalid (already cleared)", %{asset: asset} do
      actual = HaulTruckDispatchAgent.clear(asset.id)
      assert actual == {:error, :no_asset}
    end
  end

  describe "clear_dig_unit/1 -" do
    test "valid (has dispatches to clear)", %{asset: asset, dig_unit: dig_unit, locations: locs} do
      dispatch = to_dispatch(asset.id, dig_unit, locs["Crusher"])
      {:ok, initial} = HaulTruckDispatchAgent.set(dispatch)

      {:ok, [cleared]} = HaulTruckDispatchAgent.clear_dig_unit(dig_unit)

      # return
      assert cleared.id !== initial.id
      assert cleared.dig_unit_id == nil
      assert cleared.dump_location_id == nil

      # store
      assert HaulTruckDispatchAgent.current() == [cleared]
      assert HaulTruckDispatchAgent.historic() == [cleared, initial]

      # database
      assert_db_contains(HaulDispatch, [initial, cleared])
    end

    test "valid (nil id)", %{asset: asset, dig_unit: dig_unit, locations: locs} do
      dispatch = to_dispatch(asset.id, dig_unit, locs["Crusher"])
      {:ok, initial} = HaulTruckDispatchAgent.set(dispatch)

      {:ok, cleared} = HaulTruckDispatchAgent.clear_dig_unit(nil)

      # return
      assert cleared == []

      # store
      assert HaulTruckDispatchAgent.current() == [initial]
      assert HaulTruckDispatchAgent.historic() == [initial]

      # database
      assert_db_contains(HaulDispatch, initial)
    end

    test "valid (invalid id)", %{asset: asset, dig_unit: dig_unit, locations: locs} do
      dispatch = to_dispatch(asset.id, dig_unit, locs["Crusher"])
      {:ok, initial} = HaulTruckDispatchAgent.set(dispatch)

      {:ok, cleared} = HaulTruckDispatchAgent.clear_dig_unit(-1)

      # return
      assert cleared == []

      # store
      assert HaulTruckDispatchAgent.current() == [initial]
      assert HaulTruckDispatchAgent.historic() == [initial]

      # database
      assert_db_contains(HaulDispatch, initial)
    end
  end

  describe "acknowledge/3 -" do
    test "valid", %{asset: asset} do
      now = NaiveDateTime.utc_now()
      dispatch = to_dispatch(asset.id, nil, nil, ~N[2020-01-01 00:00:00])
      {:ok, dispatch} = HaulTruckDispatchAgent.set(dispatch)

      {:ok, ack_dispatch} = HaulTruckDispatchAgent.acknowledge(dispatch.id, nil, now)

      expected_ack = merge_missing_keys(dispatch, ack_dispatch)

      # return
      assert ack_dispatch == expected_ack

      # store
      assert HaulTruckDispatchAgent.current() == [ack_dispatch]
      # too old for historic
      assert HaulTruckDispatchAgent.historic() == []

      # database
      assert_db_contains(HaulDispatch, ack_dispatch)
      refute_db_contains(HaulDispatch, dispatch)
    end

    test "invalid (already acknowledged)", %{asset: asset} do
      now = NaiveDateTime.utc_now()
      dispatch = to_dispatch(asset.id, nil, nil)
      {:ok, dispatch} = HaulTruckDispatchAgent.set(dispatch)

      {:ok, _dispatch} = HaulTruckDispatchAgent.acknowledge(dispatch.id, nil, now)
      actual = HaulTruckDispatchAgent.acknowledge(dispatch.id, nil, now)

      assert actual == {:error, :already_acknowledged}
    end

    test "invalid (no id)" do
      now = NaiveDateTime.utc_now()
      actual = HaulTruckDispatchAgent.acknowledge(nil, nil, now)
      assert actual == {:error, :invalid_id}
    end

    test "invalid (invalid id)" do
      now = NaiveDateTime.utc_now()
      actual = HaulTruckDispatchAgent.acknowledge(-1, nil, now)
      assert actual == {:error, :invalid_id}
    end

    test "invalid (no timestamp)", %{asset: asset} do
      dispatch = to_dispatch(asset.id, nil, nil)
      {:ok, dispatch} = HaulTruckDispatchAgent.set(dispatch)

      actual = HaulTruckDispatchAgent.acknowledge(dispatch.id, nil, nil)
      assert_ecto_error(actual)
    end
  end
end
