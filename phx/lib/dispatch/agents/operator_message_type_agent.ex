defmodule Dispatch.OperatorMessageTypeAgent do
  use Agent

  alias Dispatch.{Helper, AgentHelper, AssetAgent}

  alias HpsData.Schemas.Dispatch.{OperatorMessageType, OperatorMessageTypeTree}
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi

  @type type :: map
  @type tree_type :: map
  @type asset_type_id :: integer

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    %{
      types: pull_types(),
      tree: pull_tree()
    }
  end

  defp pull_types() do
    from(t in OperatorMessageType,
      select: %{
        id: t.id,
        name: t.name,
        deleted: t.deleted
      }
    )
    |> Repo.all()
  end

  defp pull_tree() do
    from(t in OperatorMessageTypeTree,
      select: %{
        id: t.id,
        asset_type_id: t.asset_type_id,
        message_type_id: t.message_type_id,
        order: t.order
      }
    )
    |> Repo.all()
  end

  @spec refresh!() :: :ok
  def refresh!(), do: AgentHelper.set(__MODULE__, &init/0)

  @spec types() :: list(type)
  def types(), do: Agent.get(__MODULE__, & &1.types)

  @spec tree_elements() :: list(tree_type)
  def tree_elements(), do: Agent.get(__MODULE__, & &1.tree)

  @spec tree_elements(asset_type_id) :: list(tree_type)
  def tree_elements(asset_type_id) do
    Agent.get(__MODULE__, fn state ->
      Enum.filter(state.tree, &(&1.asset_type_id == asset_type_id))
    end)
  end

  @spec override(%{id: integer, name: String.t(), deleted: boolean}) ::
          {:ok, inserted :: type, overriden :: type} | {:error, :invalid_id | term}
  def override(params) do
    params = Helper.to_atom_map!(params)
    override(params[:id], params[:name], params[:deleted] || false)
  end

  defp override(id, name, is_deleted) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Helper.get_by_or_nil(Repo, OperatorMessageType, %{id: id}) do
        nil ->
          {{:error, :invalid_id}, state}

        existing ->
          existing
          |> OperatorMessageType.changeset(%{name: name, deleted: is_deleted})
          |> Repo.update()
          |> case do
            {:ok, message_type} ->
              message_type = OperatorMessageType.to_map(message_type)

              state =
                AgentHelper.override_or_add(
                  state,
                  :types,
                  message_type,
                  &(&1.id == message_type.id),
                  nil
                )

              {{:ok, message_type, OperatorMessageType.to_map(existing)}, state}

            error ->
              {error, state}
          end
      end
    end)
  end

  @spec update(%{id: integer | nil, name: String.t(), deleted: boolean}) ::
          {:ok, inserted :: type, deleted :: type}
          | {:error, term}
  def update(params) do
    params = Helper.to_atom_map!(params)
    update(params[:id], params[:name], params[:deleted] || false)
  end

  defp update(nil, name, is_deleted) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Helper.get_by_or_nil(Repo, OperatorMessageType, %{name: name}) do
        nil ->
          %{name: name, deleted: is_deleted}
          |> OperatorMessageType.new()
          |> Repo.insert()

        existing ->
          existing
          |> OperatorMessageType.changeset(%{deleted: is_deleted})
          |> Repo.update()
      end
      |> case do
        {:ok, message_type} ->
          message_type = OperatorMessageType.to_map(message_type)

          state =
            AgentHelper.override_or_add(
              state,
              :types,
              message_type,
              &(&1.id == message_type.id),
              nil
            )

          {{:ok, message_type, nil}, state}

        error ->
          {error, state}
      end
    end)
  end

  defp update(id, _name, true) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Helper.get_by_or_nil(Repo, OperatorMessageType, %{id: id}) do
        nil ->
          {{:error, :invalid_id}, state}

        existing ->
          delete_old = OperatorMessageType.changeset(existing, %{deleted: true})

          delete_tree_query =
            from(tree in OperatorMessageTypeTree, where: tree.message_type_id == ^id)

          Multi.new()
          |> Multi.update(:delete_old, delete_old)
          |> Multi.delete_all(:delete_tree, delete_tree_query)
          |> Repo.transaction()
          |> case do
            {:ok, %{delete_old: deleted_type}} ->
              removed_type = OperatorMessageType.to_map(deleted_type)
              filtered_tree_elements = Enum.reject(state.tree, &(&1.message_type_id == id))

              state =
                state
                |> AgentHelper.override(:types, removed_type, &(&1.id == id), nil)
                |> Map.put(:tree, filtered_tree_elements)

              {{:ok, nil, removed_type}, state}

            error ->
              {error, state}
          end
      end
    end)
  end

  defp update(id, name, false) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Helper.get_by_or_nil(Repo, OperatorMessageType, %{id: id}) do
        nil ->
          {{:error, :invalid_id}, state}

        %{name: ^name} = existing ->
          existing
          |> OperatorMessageType.changeset(%{deleted: false})
          |> Repo.update()
          |> case do
            {:ok, message_type} ->
              message_type = OperatorMessageType.to_map(message_type)
              state = AgentHelper.override(state, :types, message_type, &(&1.id == id), nil)
              {{:ok, message_type, nil}, state}

            error ->
              {error, state}
          end

        existing ->
          delete_old = OperatorMessageType.changeset(existing, %{deleted: true})

          new_type = OperatorMessageType.new(%{name: name, deleted: false})

          update_tree_query =
            from(tree in OperatorMessageTypeTree, where: tree.message_type_id == ^id)

          Multi.new()
          |> Multi.update(:delete_old, delete_old)
          |> Multi.insert(:new_type, new_type)
          |> Multi.run(:update_tree, fn repo, %{new_type: inserted_new_type} ->
            repo.update_all(update_tree_query, set: [message_type_id: inserted_new_type.id])
            {:ok, nil}
          end)
          |> Repo.transaction()
          |> case do
            {:ok, %{new_type: type_new, delete_old: type_deleted}} ->
              type_new = OperatorMessageType.to_map(type_new)
              type_deleted = OperatorMessageType.to_map(type_deleted)

              updated_tree_elements =
                Enum.map(state.tree, fn tree_element ->
                  case tree_element.message_type_id == id do
                    true -> Map.put(tree_element, :message_type_id, type_new.id)
                    _ -> tree_element
                  end
                end)

              state =
                state
                |> AgentHelper.add(:types, type_new, nil)
                |> AgentHelper.override(:types, type_deleted, &(&1.id == id), nil)
                |> Map.put(:tree, updated_tree_elements)

              {{:ok, type_new, type_deleted}, state}

            error ->
              {error, state}
          end
      end
    end)
  end

  @spec update_tree(asset_type_id, list(integer)) ::
          {:ok, list(tree_type)} | {:error, :invalid_asset_type_id | :invalid_type_ids | term}
  def update_tree(asset_type_id, ids) do
    ids =
      ids
      |> Enum.uniq()
      |> Enum.reject(&is_nil/1)

    asset_type_ids = AssetAgent.get_types() |> Enum.map(& &1.id)

    Agent.get_and_update(__MODULE__, fn state ->
      message_type_ids = Enum.map(state.types, & &1.id)

      case validate_tree_elements(asset_type_id, ids, asset_type_ids, message_type_ids) do
        :ok ->
          tree_elements =
            Enum.with_index(ids)
            |> Enum.map(fn {id, index} ->
              %{
                asset_type_id: asset_type_id,
                message_type_id: id,
                order: index
              }
            end)

          delete_query =
            from(omtt in OperatorMessageTypeTree, where: omtt.asset_type_id == ^asset_type_id)

          Multi.new()
          |> Multi.delete_all(:delete_old, delete_query)
          |> Multi.insert_all(:new_elements, OperatorMessageTypeTree, tree_elements,
            returning: true
          )
          |> Repo.transaction()
          |> case do
            {:ok, %{new_elements: {_, new_elements}}} ->
              new_elements = Enum.map(new_elements, &OperatorMessageTypeTree.to_map/1)

              tree =
                state.tree
                |> Enum.reject(&(&1.asset_type_id == asset_type_id))
                |> Enum.concat(new_elements)

              state = Map.put(state, :tree, tree)

              {{:ok, new_elements}, state}

            error ->
              {error, state}
          end

        error ->
          {error, state}
      end
    end)
  end

  defp validate_tree_elements(asset_type_id, ids, asset_type_ids, message_type_ids) do
    cond do
      !Enum.member?(asset_type_ids, asset_type_id) -> {:error, :invalid_asset_type_id}
      !all_present?(message_type_ids, ids) -> {:error, :invalid_type_ids}
      true -> :ok
    end
  end

  # returns true if all subset within source
  defp all_present?(source, subset) do
    Enum.all?(subset, &Enum.member?(source, &1))
  end
end
