defmodule Dispatch.TimeCodeAgentText do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{AssetAgent, TimeCodeAgent}
  alias HpsData.Schemas.Dispatch

  setup _ do
    group_map =
      Repo.all(Dispatch.TimeCodeGroup)
      |> Enum.map(&{&1.name, &1.id})
      |> Enum.into(%{})

    # insert example time codes
    Repo.insert!(%Dispatch.TimeCode{code: "1000", name: "Dig Ore", group_id: group_map["Ready"]})
    Repo.insert!(%Dispatch.TimeCode{code: "2000", name: "Damage", group_id: group_map["Down"]})

    AssetAgent.start_link([])

    [haul | _] = AssetAgent.get_assets(%{type: "Haul Truck"})
    [excavator | _] = AssetAgent.get_assets(%{type: "Excavator"})



    time_codes = Repo.all(Dispatch.TimeCode)
    dig_ore = Enum.find(time_codes, &(&1.name == "Dig Ore")).id
    damage = Enum.find(time_codes, &(&1.name == "Damage")).id
    no_task = Enum.find(time_codes, &(&1.name == "No Task")).id

    TimeCodeAgent.start_link([])

    # convert so that groups are accessible in context.
    groups =
      Enum.map(group_map, fn {name, id} ->
        {String.to_atom(String.downcase(name)), id}
      end)

    groups ++
      [
        haul: haul.type_id,
        excavator: excavator.type_id,
        dig_ore: dig_ore,
        damage: damage,
        no_task: no_task
      ]
  end

  defp to_element(id, parent_id, group_id, time_code_id, name) do
    %{
      id: id,
      parent_id: parent_id,
      time_code_group_id: group_id,
      time_code_id: time_code_id,
      node_name: name
    }
  end

  test "no task id correct", %{no_task: no_task} do
    assert TimeCodeAgent.no_task_id() == no_task
  end

  describe "add_time_code/1 -" do
    test "valid", %{ready: ready} do
      code = "1050"
      name = "A time code"

      {:ok, actual} =
        %{
          code: code,
          name: name,
          group_id: ready
        }
        |> TimeCodeAgent.add_time_code()

      # return
      assert actual.id != nil
      assert actual.code == code
      assert actual.name == name
      assert actual.group_id == ready
      assert actual.category_id == nil

      # store
      assert Enum.member?(TimeCodeAgent.get_time_codes(), actual)

      # database
      assert_db_contains(Dispatch.TimeCode, actual)
    end

    test "valid (duplicate name)", %{ready: ready} do
      name = "A time code"

      {:ok, initial} =
        %{
          code: "1050",
          name: name,
          group_id: ready
        }
        |> TimeCodeAgent.add_time_code()

      {:ok, actual} =
        %{
          code: "1051",
          name: name,
          group_id: ready
        }
        |> TimeCodeAgent.add_time_code()

      # return

      assert actual.id != initial.id
      assert actual.code != initial.code
      assert actual.name == actual.name
      assert actual.category_id == nil

      # store
      assert Enum.member?(TimeCodeAgent.get_time_codes(), initial)
      assert Enum.member?(TimeCodeAgent.get_time_codes(), actual)

      # database
      assert_db_contains(Dispatch.TimeCode, [initial, actual])
    end

    test "invalid ('no task' reserved)", %{ready: ready} do
      error =
        %{
          code: "1050",
          name: "No Task",
          group_id: ready
        }
        |> TimeCodeAgent.add_time_code()

      assert error == {:error, :reserved_name}
    end

    test "invalid (invalid group)" do
      error =
        %{
          code: "1050",
          name: "A name",
          group_id: -10
        }
        |> TimeCodeAgent.add_time_code()

      assert_ecto_error(error)
    end

    test "invalid (duplicate code)", %{ready: ready} do
      code = "1050"

      {:ok, _} =
        %{
          code: code,
          name: "Name A",
          group_id: ready
        }
        |> TimeCodeAgent.add_time_code()

      error =
        %{
          code: code,
          name: "Name B",
          group_id: ready
        }
        |> TimeCodeAgent.add_time_code()

      assert_ecto_error(error)
    end
  end

  describe "update_time_code/1 -" do
    test "valid (exists)", %{ready: ready} do
      {:ok, initial} =
        %{
          code: "1050",
          name: "Name A",
          group_id: ready
        }
        |> TimeCodeAgent.add_time_code()

      {:ok, actual} =
        %{
          id: initial.id,
          code: "1050",
          name: "Name B",
          group_id: ready
        }
        |> TimeCodeAgent.update_time_code()

      # return
      assert actual.id == initial.id
      assert actual.code == initial.code
      assert actual.name != initial.name
      assert actual.group_id == ready
      assert actual.category_id == nil

      # store
      assert Enum.member?(TimeCodeAgent.get_time_codes(), actual)

      # database
      assert_db_contains(Dispatch.TimeCode, actual)
      refute_db_contains(Dispatch.TimeCode, initial)
    end

    test "invalid (duplicate code)", %{ready: ready} do
      {:ok, _} =
        %{
          code: "1050",
          name: "Name A",
          group_id: ready
        }
        |> TimeCodeAgent.add_time_code()

      {:ok, initial} =
        %{
          code: "1051",
          name: "Name B",
          group_id: ready
        }
        |> TimeCodeAgent.add_time_code()

      error =
        %{
          id: initial.id,
          code: "1050",
          name: "Name B",
          group_id: ready
        }
        |> TimeCodeAgent.update_time_code()

      assert_ecto_error(error)
    end

    test "invalid ('no task' reserved)", %{ready: ready} do
      {:ok, initial} =
        %{
          code: "1051",
          name: "Name B",
          group_id: ready
        }
        |> TimeCodeAgent.add_time_code()

      error =
        %{
          id: initial.id,
          code: "1050",
          name: "No Task",
          group_id: ready
        }
        |> TimeCodeAgent.update_time_code()

      assert error == {:error, :reserved_name}
    end

    test "invalid (cannot edit 'no task')", %{ready: ready} do
      no_task_id = TimeCodeAgent.no_task_id()

      error =
        %{
          id: no_task_id,
          code: "1111",
          name: "Not no task",
          group_id: ready
        }
        |> TimeCodeAgent.update_time_code()

      assert error == {:error, :cannot_edit}
    end

    test "invalid (id does not exist)", %{ready: ready} do
      error =
        %{
          id: -9000,
          code: "1111",
          name: "invalid",
          group_id: ready
        }
        |> TimeCodeAgent.update_time_code()

      assert error == {:error, :invalid_id}
    end

    test "invalid (no name)", %{ready: ready} do
      {:ok, initial} =
        %{
          code: "1051",
          name: "Name B",
          group_id: ready
        }
        |> TimeCodeAgent.add_time_code()

      error =
        %{
          id: initial.id,
          code: initial.code,
          name: "",
          group_id: initial.group_id
        }
        |> TimeCodeAgent.update_time_code()

      assert_ecto_error(error)
    end
  end

  describe "update_group/2 -" do
    test "valid (exists)", %{ready: ready} do
      alias_name = "ready alias"
      initial = TimeCodeAgent.get_time_code_groups() |> Enum.find(&(&1.id == ready))
      {:ok, actual} = TimeCodeAgent.update_group(ready, alias_name)

      # return
      assert actual.id == ready
      assert actual.name == "Ready"
      assert actual.alias == alias_name

      # store
      assert Enum.member?(TimeCodeAgent.get_time_code_groups(), actual)

      # database
      assert_db_contains(Dispatch.TimeCodeGroup, actual)
      refute_db_contains(Dispatch.TimeCodeGroup, initial)
    end

    test "valid (can be set to nil)", %{ready: ready} do
      alias_name = nil
      {:ok, actual} = TimeCodeAgent.update_group(ready, alias_name)

      # return
      assert actual.id == ready
      assert actual.name == "Ready"
      assert actual.alias == alias_name

      # store
      assert Enum.member?(TimeCodeAgent.get_time_code_groups(), actual)

      # database
      assert_db_contains(Dispatch.TimeCodeGroup, actual)
    end

    test "invalid (invalid id)" do
      error = TimeCodeAgent.update_group(-2, "invalid")
      assert error == {:error, :invalid_id}
    end
  end

  describe "set time code tree elements -" do
    test "valid (simple)", %{excavator: excavator, dig_ore: dig_ore, ready: ready} do
      {:ok, [element]} =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          to_element(-1, nil, ready, dig_ore, nil)
        ])

      # return
      assert element.id == 1
      assert element.time_code_id == dig_ore
      assert element.time_code_group_id == ready
      assert element.parent_id == nil
      assert element.node_name == nil

      # store
      assert TimeCodeAgent.get_time_code_tree_elements(excavator) == [element]

      # database
      assert_db_contains(Dispatch.TimeCodeTree, element)
      assert_db_count(Dispatch.TimeCodeTree, 1)
    end

    test "valid (subfolder)", %{excavator: excavator, dig_ore: dig_ore, ready: ready} do
      folder = to_element(1, nil, ready, nil, "Folder")
      child = to_element(2, folder.id, ready, dig_ore, nil)

      {:ok, [subfolder, element]} =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          folder,
          child
        ])

      # return
      assert subfolder.id < element.id

      assert subfolder.time_code_group_id == ready
      assert subfolder.time_code_id == nil
      assert subfolder.node_name == folder.node_name
      assert subfolder.parent_id == nil

      assert child.time_code_group_id == ready
      assert child.time_code_id == dig_ore
      assert child.node_name == nil
      assert child.parent_id == subfolder.id

      # store
      assert TimeCodeAgent.get_time_code_tree_elements(excavator) == [subfolder, element]

      # database
      assert_db_contains(Dispatch.TimeCodeTree, [subfolder, element])
      assert_db_count(Dispatch.TimeCodeTree, 2)
    end

    test "valid (incorrect order)", %{excavator: excavator, dig_ore: dig_ore, ready: ready} do
      folder = to_element(1, nil, ready, nil, "Folder")
      child = to_element(2, folder.id, ready, dig_ore, nil)

      {:ok, [subfolder, element]} =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          child,
          folder
        ])

      # return
      assert subfolder.id < element.id

      assert subfolder.time_code_group_id == ready
      assert subfolder.time_code_id == nil
      assert subfolder.node_name == folder.node_name
      assert subfolder.parent_id == nil

      assert child.time_code_group_id == ready
      assert child.time_code_id == dig_ore
      assert child.node_name == nil
      assert child.parent_id == subfolder.id

      # store
      assert TimeCodeAgent.get_time_code_tree_elements(excavator) == [subfolder, element]

      # database
      assert_db_contains(Dispatch.TimeCodeTree, [subfolder, element])
      assert_db_count(Dispatch.TimeCodeTree, 2)
    end

    test "valid (other asset types are not affected)", %{
      excavator: excavator,
      haul: haul,
      dig_ore: dig_ore,
      ready: ready
    } do
      {:ok, [excavator_element]} =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          to_element(1, nil, ready, dig_ore, nil)
        ])

      {:ok, [haul_element]} =
        TimeCodeAgent.set_time_code_tree_elements(haul, [
          to_element(1, nil, ready, dig_ore, nil)
        ])

      # return
      assert haul_element.id != excavator_element.id

      # store
      assert TimeCodeAgent.get_time_code_tree_elements(haul) == [haul_element]
      assert TimeCodeAgent.get_time_code_tree_elements(excavator) == [excavator_element]

      # database
      assert_db_contains(Dispatch.TimeCodeTree, [haul_element, excavator_element])
      assert_db_count(Dispatch.TimeCodeTree, 2)
    end

    test "valid (ready under exception parent)", %{
      excavator: excavator,
      down: down,
      dig_ore: dig_ore,
      ready: ready_id
    } do
      {:ok, [element]} =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          to_element(1, nil, down, dig_ore, nil)
        ])

      # return
      assert element.time_code_group_id !== ready_id

      # store
      assert TimeCodeAgent.get_time_code_tree_elements(excavator) == [element]

      # database
      assert_db_contains(Dispatch.TimeCodeTree, element)
      assert_db_count(Dispatch.TimeCodeTree, 1)
    end

    test "valid (empty subfolder)", %{excavator: excavator, ready: ready} do
      name = "Folder"

      {:ok, [element]} =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          to_element(1, nil, ready, nil, name)
        ])

      # return
      assert element.time_code_id == nil
      assert element.time_code_group_id == ready
      assert element.node_name == name

      # store
      assert TimeCodeAgent.get_time_code_tree_elements(excavator) == [element]

      # database
      assert_db_contains(Dispatch.TimeCodeTree, element)
      assert_db_count(Dispatch.TimeCodeTree, 1)
    end

    test "invalid (missing keys)", %{excavator: excavator} do
      error = TimeCodeAgent.set_time_code_tree_elements(excavator, [%{}])
      assert error == {:error, :invalid_element}
    end

    test "invalid (parent is self)", %{excavator: excavator, ready: ready} do
      error =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          to_element(1, 1, ready, nil, "Folder")
        ])

      assert error == {:error, :invalid_element}
    end

    test "invalid (missing time code group)", %{excavator: excavator, dig_ore: dig_ore} do
      error =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          to_element(1, nil, nil, dig_ore, nil)
        ])

      assert error == {:error, :invalid_element}
    end

    test "invalid (no time code and no node name)", %{excavator: excavator, ready: ready} do
      error =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          to_element(1, nil, ready, nil, nil)
        ])

      assert error == {:error, :invalid_element}
    end

    test "invalid (invalid asset type)", %{ready: ready, dig_ore: dig_ore} do
      error =
        TimeCodeAgent.set_time_code_tree_elements(nil, [
          to_element(1, nil, ready, dig_ore, nil)
        ])

      assert error == {:error, :invalid_asset_type}
    end

    test "invalid (subfolder with time code)", %{
      excavator: excavator,
      ready: ready,
      dig_ore: dig_ore
    } do
      error =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          to_element(1, nil, ready, dig_ore, "Folder")
        ])

      assert error == {:error, :invalid_element}
    end

    test "invalid (missing parent ids)", %{excavator: excavator, ready: ready, dig_ore: dig_ore} do
      error =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          to_element(1, -1, ready, dig_ore, nil)
        ])

      assert error == {:error, :missing_parent}
    end

    test "invalid (parent is not a subfolder)", %{
      excavator: excavator,
      ready: ready,
      dig_ore: dig_ore
    } do
      error =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          to_element(1, nil, ready, dig_ore, nil),
          to_element(2, 1, ready, dig_ore, nil)
        ])

      assert error == {:error, :parent_not_folder}
    end

    test "invalid (duplicate tree ids)", %{excavator: excavator, ready: ready, dig_ore: dig_ore} do
      error =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          to_element(1, nil, ready, dig_ore, nil),
          to_element(1, nil, ready, dig_ore, nil)
        ])

      assert error == {:error, :duplicate_tree_ids}
    end

    test "invalid (circular reference)", %{excavator: excavator, ready: ready, dig_ore: dig_ore} do
      error =
        TimeCodeAgent.set_time_code_tree_elements(excavator, [
          to_element(1, 2, ready, nil, "A"),
          to_element(2, 1, ready, nil, "B"),
          to_element(3, 1, ready, dig_ore, nil),
          to_element(4, 2, ready, dig_ore, nil)
        ])

      assert error == {:error, :invalid_element}
    end
  end
end
