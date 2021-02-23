defmodule Dispatch.AssetRadioAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.AssetRadioAgent
  alias HpsData.Asset
  alias HpsData.Schemas.Dispatch.AssetRadio

  setup _ do
    AssetRadioAgent.start_link([])
    [asset | _] = Repo.all(Asset)
    [asset: asset]
  end

  test "create new radio number", %{asset: asset} do
    expected_radio_number = "1234"
    {:ok, record} = AssetRadioAgent.set(asset.id, expected_radio_number)

    %{radio_number: actual_radio_number} = AssetRadioAgent.get(asset.id)

    # return
    assert record.asset_id == asset.id
    assert record.radio_number == expected_radio_number

    # state
    assert actual_radio_number == expected_radio_number

    # database
    assert_db_contains(AssetRadio, record)
  end

  test "update radio number", %{asset: asset} do
    initial_number = "1234"
    expected_radio_number = "4321"
    {:ok, initial_record} = AssetRadioAgent.set(asset.id, initial_number)
    {:ok, record} = AssetRadioAgent.set(asset.id, expected_radio_number)

    %{radio_number: actual_radio_number} = AssetRadioAgent.get(asset.id)

    # return
    assert record.asset_id == asset.id
    assert record.radio_number == expected_radio_number

    # state
    assert actual_radio_number == expected_radio_number

    # database
    assert_db_contains(AssetRadio, record)
    refute_db_contains(AssetRadio, initial_record)
  end

  test "clear radio number", %{asset: asset} do
    initial_number = "1234"
    expected_radio_number = nil
    {:ok, initial_record} = AssetRadioAgent.set(asset.id, initial_number)
    {:ok, record} = AssetRadioAgent.set(asset.id, expected_radio_number)

    %{radio_number: actual_radio_number} = AssetRadioAgent.get(asset.id)

    # return
    assert record.asset_id == asset.id
    assert record.radio_number == expected_radio_number

    # state
    assert actual_radio_number == expected_radio_number

    # database
    assert_db_contains(AssetRadio, record)
    refute_db_contains(AssetRadio, initial_record)
  end

  test "invalid (missing asset)" do
    actual = AssetRadioAgent.set(-1, "100")
    assert_ecto_error(actual)
  end
end
