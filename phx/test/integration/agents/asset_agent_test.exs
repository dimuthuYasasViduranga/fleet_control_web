defmodule FleetControlWeb.AssetAgentTest do
  use FleetControlWeb.RepoCase
  @moduletag :agent

  alias FleetControl.AssetAgent
  alias HpsData.{Asset, AssetType}

  setup do
    AssetAgent.start_link([])
    :ok
  end

  test "get all assets" do
    asset_count = AssetAgent.get_assets() |> length()
    assert asset_count > 0
  end

  test "update!" do
    initial_count = AssetAgent.get_assets() |> length()

    haul_truck_id =
      AssetType
      |> Repo.all()
      |> Enum.find(&(&1.type == "Haul Truck"))
      |> Map.get(:id)

    %Asset{
      name: "New Asset",
      asset_type_id: haul_truck_id
    }
    |> Repo.insert!()

    AssetAgent.refresh!()

    actual_count = AssetAgent.get_assets() |> length()

    assert actual_count == initial_count + 1
  end
end
