defmodule Dispatch.OperatorMessageTypeAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{AssetAgent, OperatorMessageTypeAgent}
  alias HpsData.Schemas.Dispatch.{OperatorMessageType, OperatorMessageTypeTree}

  setup_all _ do
    AssetAgent.start_link([])
    [asset | _] = AssetAgent.get_assets(%{type: "Haul Truck"})

    [asset_type: asset.type_id]
  end

  setup do
    OperatorMessageTypeAgent.start_link([])
    :ok
  end

  describe "update/1 - new" do
    test "valid" do
      name = "name"
      {:ok, created, deleted} = OperatorMessageTypeAgent.update(%{name: name})

      # return
      assert deleted == nil
      assert created.name == name
      assert created.deleted == false

      # store
      assert Enum.member?(OperatorMessageTypeAgent.types(), created)

      # database
      assert_db_contains(OperatorMessageType, created)
    end

    test "valid (duplicate name)" do
      name = "duplicate"

      {:ok, initial, _} = OperatorMessageTypeAgent.update(%{name: name})

      {:ok, actual, deleted} = OperatorMessageTypeAgent.update(%{name: name})

      # return
      assert initial.deleted == false
      assert actual.deleted == false
      assert actual.id == initial.id

      assert deleted == nil

      # store
      assert Enum.member?(OperatorMessageTypeAgent.types(), initial)
      assert Enum.member?(OperatorMessageTypeAgent.types(), actual)

      # database
      assert_db_contains(OperatorMessageType, [initial, actual])
    end

    test "valid (create deleted)" do
      {:ok, actual, deleted} = OperatorMessageTypeAgent.update(%{name: "name", deleted: true})

      # return
      assert actual.deleted == true
      assert deleted == nil

      # store
      assert Enum.member?(OperatorMessageTypeAgent.types(), actual)

      # database
      assert_db_contains(OperatorMessageType, actual)
    end

    test "invalid (empty map)" do
      error = OperatorMessageTypeAgent.update(%{})
      assert_ecto_error(error)
    end

    test "invalid (nil name)" do
      error = OperatorMessageTypeAgent.update(%{name: nil})
      assert_ecto_error(error)
    end
  end

  describe "update/1 - update" do
    test "valid" do
      initial_name = "initial"
      updated_name = "updated"
      {:ok, initial, _} = OperatorMessageTypeAgent.update(%{name: initial_name})

      {:ok, created, deleted} =
        OperatorMessageTypeAgent.update(%{id: initial.id, name: updated_name})

      # return
      assert deleted.id == initial.id
      assert deleted.deleted == true

      assert created.id != initial.id
      assert created.deleted == false
      assert created.name == updated_name

      # store
      assert Enum.member?(OperatorMessageTypeAgent.types(), created)
      assert Enum.member?(OperatorMessageTypeAgent.types(), deleted)

      # database
      assert_db_contains(OperatorMessageType, [created, deleted])
      refute_db_contains(OperatorMessageType, initial)
    end

    test "valid (undelete message with same name)" do
      name = "name"

      {:ok, initial, _} = OperatorMessageTypeAgent.update(%{name: name, deleted: true})
      {:ok, updated, _} = OperatorMessageTypeAgent.update(%{name: name})

      # return
      assert initial.deleted == true
      assert updated.deleted == false
      assert updated.id == initial.id

      # store
      assert Enum.member?(OperatorMessageTypeAgent.types(), updated)
      assert !Enum.member?(OperatorMessageTypeAgent.types(), initial)

      # database
      assert_db_contains(OperatorMessageType, updated)
      refute_db_contains(OperatorMessageType, initial)
    end

    test "valid (delete)" do
      {:ok, initial, _} = OperatorMessageTypeAgent.update(%{name: "name"})

      {:ok, created, deleted} =
        OperatorMessageTypeAgent.update(%{id: initial.id, name: "name", deleted: true})

      # return
      assert created == nil

      assert deleted.id == initial.id
      assert deleted.deleted == true

      # store
      assert !Enum.member?(OperatorMessageTypeAgent.types(), initial)
      assert Enum.member?(OperatorMessageTypeAgent.types(), deleted)

      # database
      assert_db_contains(OperatorMessageType, deleted)
      refute_db_contains(OperatorMessageType, initial)
    end

    test "invalid (invalid id)" do
      error = OperatorMessageTypeAgent.update(%{id: -1, name: "invalid"})
      assert error == {:error, :invalid_id}
    end
  end

  describe "override/1 -" do
    test "valid" do
      {:ok, initial, _} = OperatorMessageTypeAgent.update(%{name: "initial"})

      {:ok, actual, overriden} =
        OperatorMessageTypeAgent.override(%{id: initial.id, name: "override"})

      # return
      assert initial.deleted == false

      assert actual.id == initial.id
      assert actual.deleted == false

      assert overriden == initial

      # store
      assert Enum.member?(OperatorMessageTypeAgent.types(), actual)
      assert !Enum.member?(OperatorMessageTypeAgent.types(), initial)

      # database
      assert_db_contains(OperatorMessageType, actual)
      refute_db_contains(OperatorMessageType, [initial, overriden])
    end

    test "invalid (does not exist)" do
      error = OperatorMessageTypeAgent.override(%{id: -1, name: "Apples"})
      assert error == {:error, :invalid_id}
    end

    test "invalid (change name to nil)" do
    end
  end

  describe "update_tree/2 -" do
    setup do
      type_ids = OperatorMessageTypeAgent.types() |> Enum.map(& &1.id)
      [msg_type_ids: type_ids]
    end

    test "valid", %{asset_type: asset_type, msg_type_ids: msg_types} do
      [type_a, type_b | _] = msg_types

      {:ok, [tree_a, tree_b] = elements} =
        OperatorMessageTypeAgent.update_tree(asset_type, [type_a, type_b])

      # return
      assert tree_a.asset_type_id == asset_type
      assert tree_a.message_type_id == type_a
      assert tree_a.order == 0

      assert tree_b.asset_type_id == asset_type
      assert tree_b.message_type_id == type_b
      assert tree_b.order == 1

      # store
      assert OperatorMessageTypeAgent.tree_elements() == elements

      # database
      assert_db_contains(OperatorMessageTypeTree, elements)
    end

    test "valid (duplicate ids)", %{asset_type: asset_type, msg_type_ids: msg_types} do
      [type_a, type_b | _] = msg_types

      {:ok, [tree_a, tree_b] = elements} =
        OperatorMessageTypeAgent.update_tree(asset_type, [type_a, type_b, type_a, type_b])

      # return
      assert tree_a.asset_type_id == asset_type
      assert tree_a.message_type_id == type_a
      assert tree_a.order == 0

      assert tree_b.asset_type_id == asset_type
      assert tree_b.message_type_id == type_b
      assert tree_b.order == 1

      # store
      assert OperatorMessageTypeAgent.tree_elements() == elements

      # database
      assert_db_contains(OperatorMessageTypeTree, elements)
    end

    test "valid (no ids)", %{asset_type: asset_type} do
      {:ok, elements} = OperatorMessageTypeAgent.update_tree(asset_type, [])

      # return
      assert elements == []

      # store
      assert OperatorMessageTypeAgent.tree_elements() == []

      # database
      assert_db_count(OperatorMessageTypeTree, 0)
    end

    test "invalid (invalid asset type)" do
      error = OperatorMessageTypeAgent.update_tree(-1, [])
      assert error == {:error, :invalid_asset_type_id}
    end

    test "invalid (invalid message type id)", %{asset_type: asset_type} do
      error = OperatorMessageTypeAgent.update_tree(asset_type, [-1])
      assert error == {:error, :invalid_type_ids}
    end
  end

  describe "updating elements present in tree" do
    test "valid (update name)", %{asset_type: asset_type} do
      {:ok, initial, _} = OperatorMessageTypeAgent.update(%{name: "initial"})

      {:ok, [initial_tree_element]} =
        OperatorMessageTypeAgent.update_tree(asset_type, [initial.id])

      {:ok, updated, _} = OperatorMessageTypeAgent.update(%{id: initial.id, name: "updated"})

      [updated_tree_element] = OperatorMessageTypeAgent.tree_elements()

      # return
      assert initial.deleted == false
      assert initial_tree_element.message_type_id == initial.id

      # store
      assert !Enum.member?(OperatorMessageTypeAgent.types(), initial)
      assert Enum.member?(OperatorMessageTypeAgent.types(), updated)
      assert updated_tree_element.message_type_id == updated.id

      # database
      assert_db_count(OperatorMessageTypeTree, 1)
    end

    test "valid (delete name)", %{asset_type: asset_type} do
      {:ok, initial, _} = OperatorMessageTypeAgent.update(%{name: "initial"})

      {:ok, [initial_tree_element]} =
        OperatorMessageTypeAgent.update_tree(asset_type, [initial.id])

      {:ok, nil, deleted} = OperatorMessageTypeAgent.update(%{id: initial.id, deleted: true})

      # return
      assert initial.deleted == false
      assert initial_tree_element.message_type_id == initial.id

      # store
      assert !Enum.member?(OperatorMessageTypeAgent.types(), initial)
      assert Enum.member?(OperatorMessageTypeAgent.types(), deleted)
      assert OperatorMessageTypeAgent.tree_elements() == []

      # database
      assert_db_count(OperatorMessageTypeTree, 0)
    end
  end
end
