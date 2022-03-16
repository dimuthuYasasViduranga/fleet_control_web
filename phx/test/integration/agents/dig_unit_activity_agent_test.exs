defmodule Dispatch.DigUnitActivityAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{Helper, AssetAgent, DigUnitActivityAgent}
  alias HpsData.Dim.{Location, MaterialType}
  alias HpsData.Schemas.Dispatch.{DigUnitActivity, LoadStyle}

  setup_all _ do
    AssetAgent.start_link([])
    [asset, asset_b] = AssetAgent.get_assets(%{type: "Excavator"})

    locations =
      Location
      |> Repo.all()
      |> Enum.map(&{&1.name, &1.id})
      |> Enum.into(%{})

    [asset: asset, asset_b: asset_b, crusher: locations["Crusher"]]
  end

  setup tags do
    DigUnitActivityAgent.start_link([])

    load_style =
      Repo.insert!(%LoadStyle{asset_type_id: tags[:asset].type_id, style: "A style"},
        returning: true
      )
      |> Map.get(:id)

    material_type =
      Repo.insert!(%MaterialType{name: "HG", alias: "HG"}, returning: true)
      |> Map.get(:id)

    [load_style: load_style, material_type: material_type]
  end

  describe "add/1 -" do
    test "valid", %{asset: asset, crusher: crusher} do
      now = NaiveDateTime.utc_now()

      {:ok, actual} =
        DigUnitActivityAgent.add(%{
          asset_id: asset.id,
          location_id: crusher,
          material_type_id: nil,
          load_style_id: nil,
          timestamp: now
        })

      # return
      assert actual.id != nil
      assert actual.asset_id == asset.id
      assert actual.location_id == crusher
      assert actual.material_type_id == nil
      assert actual.load_style_id == nil
      assert NaiveDateTime.compare(actual.timestamp, now) == :eq

      # store
      assert DigUnitActivityAgent.current() == [actual]
      assert DigUnitActivityAgent.historic() == [actual]

      # database
      assert_db_contains(DigUnitActivity, actual)
      assert_db_count(DigUnitActivity, 1)
    end

    test "valid (timestamp as unix)", %{asset: asset} do
      now = NaiveDateTime.utc_now()
      unix = Helper.to_unix(now)

      {:ok, actual} =
        DigUnitActivityAgent.add(%{
          asset_id: asset.id,
          location_id: nil,
          material_type_id: nil,
          load_style_id: nil,
          timestamp: unix
        })

      # return
      assert actual.id != nil
      assert NaiveDateTime.compare(actual.timestamp, now) == :eq

      # store
      assert DigUnitActivityAgent.current() == [actual]
      assert DigUnitActivityAgent.historic() == [actual]

      # database
      assert_db_contains(DigUnitActivity, actual)
      assert_db_count(DigUnitActivity, 1)
    end

    test "valid (old activity -> store and forward case)", %{asset: asset} do
      now = NaiveDateTime.utc_now()
      past = NaiveDateTime.add(now, -3600)

      {:ok, current} =
        DigUnitActivityAgent.add(%{
          asset_id: asset.id,
          location_id: nil,
          material_type_id: nil,
          load_style_id: nil,
          timestamp: now
        })

      {:ok, old} =
        DigUnitActivityAgent.add(%{
          asset_id: asset.id,
          location_id: nil,
          material_type_id: nil,
          load_style_id: nil,
          timestamp: past
        })

      # store
      assert DigUnitActivityAgent.current() == [current]
      assert DigUnitActivityAgent.historic() == [current, old]

      # database
      assert_db_contains(DigUnitActivity, [current, old])
      assert_db_count(DigUnitActivity, 2)
    end

    test "invalid (invalid location id)", %{asset: asset} do
      error =
        DigUnitActivityAgent.add(%{
          asset_id: asset.id,
          location_id: -1,
          material_type_id: nil,
          load_style_id: nil,
          timestamp: NaiveDateTime.utc_now()
        })

      assert_ecto_error(error)
    end

    test "invalid (missing asset)" do
      error =
        DigUnitActivityAgent.add(%{
          asset_id: nil,
          location_id: nil,
          material_type_id: nil,
          load_style_id: nil,
          timestamp: NaiveDateTime.utc_now()
        })

      assert_ecto_error(error)
    end

    test "invalid (invalid asset)" do
      error =
        DigUnitActivityAgent.add(%{
          asset_id: -1,
          location_id: nil,
          material_type_id: nil,
          load_style_id: nil,
          timestamp: NaiveDateTime.utc_now()
        })

      assert_ecto_error(error)
    end

    test "invalid (future activity)", %{asset: asset} do
      future = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600)

      error =
        DigUnitActivityAgent.add(%{
          asset_id: asset.id,
          location_id: nil,
          material_type_id: nil,
          load_style_id: nil,
          timestamp: future
        })

      assert_ecto_error(error)
    end

    test "invalid (no timestamp)", %{asset: asset} do
      error =
        DigUnitActivityAgent.add(%{
          asset_id: asset.id,
          location_id: nil,
          material_type_id: nil,
          load_style_id: nil,
          timestamp: nil
        })

      assert_ecto_error(error)
    end
  end

  describe "mass_set/3 -" do
    test "valid", %{
      asset: asset_a,
      asset_b: asset_b,
      crusher: crusher,
      load_style: load_style,
      material_type: material_type
    } do
      timestamp = NaiveDateTime.utc_now()

      activity = %{
        location_id: crusher,
        material_type_id: material_type,
        load_style_id: load_style
      }

      {:ok, [actual_a, actual_b]} =
        DigUnitActivityAgent.mass_set([asset_a.id, asset_b.id], activity, timestamp)

      # return
      assert actual_a.group_id != nil
      assert actual_b.group_id != nil
      assert actual_a.group_id == actual_b.group_id

      assert actual_a.location_id == crusher
      assert actual_a.material_type_id == material_type
      assert actual_a.load_style_id == load_style

      assert actual_b.location_id == crusher
      assert actual_b.material_type_id == material_type
      assert actual_b.load_style_id == load_style

      # store
      assert DigUnitActivityAgent.current() == [actual_b, actual_a]
      assert DigUnitActivityAgent.historic() == [actual_b, actual_a]

      # database
      assert_db_contains(DigUnitActivity, [actual_a, actual_b])
      assert_db_count(DigUnitActivity, 2)
    end

    test "valid (no assets)" do
      activity = %{
        location_id: nil,
        material_type_id: nil,
        load_style_id: nil
      }

      {:ok, actual} = DigUnitActivityAgent.mass_set([], activity)

      # return
      assert actual == []

      # store
      assert DigUnitActivityAgent.current() == []
      assert DigUnitActivityAgent.historic() == []

      # database
      assert_db_count(DigUnitActivity, 0)
    end

    test "valid (duplicate assets)", %{asset: asset} do
      activity = %{
        location_id: nil,
        material_type_id: nil,
        load_style_id: nil
      }

      {:ok, [actual]} = DigUnitActivityAgent.mass_set([asset.id, asset.id], activity)

      # return
      assert actual.asset_id == asset.id

      # store
      assert DigUnitActivityAgent.current() == [actual]
      assert DigUnitActivityAgent.historic() == [actual]

      # database
      assert_db_count(DigUnitActivity, 1)
    end

    test "valid (one nil asset)", %{asset: asset} do
      activity = %{
        location_id: nil,
        material_type_id: nil,
        load_style_id: nil
      }

      {:ok, [actual]} = DigUnitActivityAgent.mass_set([asset.id, nil], activity)

      # return
      assert actual.asset_id == asset.id

      # store
      assert DigUnitActivityAgent.current() == [actual]
      assert DigUnitActivityAgent.historic() == [actual]

      # database
      assert_db_count(DigUnitActivity, 1)
    end

    @tag :capture_log
    test "invalid (1 invalid asset)" do
      Process.flag(:trap_exit, true)

      activity = %{
        location_id: nil,
        material_type_id: nil,
        load_style_id: nil
      }

      pid = Process.whereis(DigUnitActivityAgent)

      catch_exit do
        DigUnitActivityAgent.mass_set([-1], activity)
      end

      assert_receive {
        :EXIT,
        ^pid,
        {%Postgrex.Error{}, _stack}
      }
    end
  end
end
