defmodule Dispatch.TimeCodeAgent do
  @moduledoc """
  Used to hold all time_code values and the structured trees for
  presentation
  """

  use Agent
  alias Dispatch.{Helper, AgentHelper}
  require Logger

  alias HpsData.Schemas.Dispatch.{TimeCode, TimeCodeGroup, TimeCodeTree}
  alias HpsData.Dim.TimeUsageCategory
  alias HpsData.Repo
  alias Dispatch.AssetAgent

  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi

  @required_keys [
    :id,
    :parent_id,
    :time_code_group_id,
    :time_code_id,
    :node_name
  ]

  @type time_code :: map
  @type time_code_group :: map
  @type time_code_tree_element :: map
  @type time_code_category :: map

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    time_codes = pull_time_codes()
    no_task_id = Enum.find(time_codes, &(&1.name === "No Task")).id

    %{
      time_codes: time_codes,
      time_code_groups: pull_time_code_groups(),
      time_code_tree_elements: pull_time_code_tree_elements(),
      time_code_categories: pull_time_code_categories(),
      no_task_id: no_task_id
    }
  end

  defp pull_time_codes() do
    from(tc in TimeCode,
      join: tcg in TimeCodeGroup,
      on: [id: tc.group_id],
      select: %{
        id: tc.id,
        code: tc.code,
        name: tc.name,
        group_id: tc.group_id,
        category_id: tc.category_id
      }
    )
    |> Repo.all()
  end

  defp pull_time_code_groups() do
    from(tcg in TimeCodeGroup,
      select: %{
        id: tcg.id,
        name: tcg.name,
        alias: tcg.alias
      }
    )
    |> Repo.all()
  end

  defp pull_time_code_tree_elements() do
    from(tct in TimeCodeTree,
      select: %{
        id: tct.id,
        asset_type_id: tct.asset_type_id,
        time_code_id: tct.time_code_id,
        parent_id: tct.parent_id,
        time_code_group_id: tct.time_code_group_id,
        node_name: tct.node_name
      }
    )
    |> Repo.all()
  end

  defp pull_time_code_categories() do
    from(tc in TimeUsageCategory,
      select: %{
        id: tc.id,
        name: tc.name
      }
    )
    |> Repo.all()
  end

  @spec refresh!() :: :ok
  def refresh!(), do: AgentHelper.set(__MODULE__, &init/0)

  @spec get() :: map()
  def get(), do: Agent.get(__MODULE__, & &1)

  @spec get(atom) :: any()
  def get(key), do: Agent.get(__MODULE__, & &1[key])

  @spec no_task_id() :: integer
  def no_task_id(), do: get(:no_task_id)

  @spec get_time_codes() :: list(time_code)
  def get_time_codes(), do: get(:time_codes)

  @spec get_time_codes(group_id :: integer) :: list(time_code)
  def get_time_codes(group_id) do
    Enum.filter(get_time_codes(), &(&1.group_id == group_id))
  end

  @spec get_time_code_groups() :: list(time_code_group)
  def get_time_code_groups(), do: get(:time_code_groups)

  @spec get_time_code_categories() :: list(time_code_category)
  def get_time_code_categories(), do: get(:time_code_categories)

  @spec add_or_update_time_code(map) ::
          {:ok, time_code} | {:error, :reserved_name | :invalid_id | :cannot_edit | term}
  def add_or_update_time_code(params) do
    case params[:id] || params["id"] do
      nil -> add_time_code(params)
      _ -> update_time_code(params)
    end
  end

  @spec add_time_code(map) :: {:ok, time_code} | {:error, :reserved_name | term}
  def add_time_code(params) do
    new_time_code =
      params
      |> Helper.to_atom_map!()
      |> Map.drop([:id])
      |> TimeCode.new()

    Agent.get_and_update(__MODULE__, fn state ->
      case params[:name] == "No Task" do
        true ->
          {{:error, :reserved_name}, state}

        _ ->
          new_time_code
          |> Repo.insert()
          |> case do
            {:ok, time_code} ->
              time_code = TimeCode.to_map(time_code)
              state = AgentHelper.add(state, :time_codes, time_code, nil)
              {{:ok, time_code}, state}

            error ->
              {error, state}
          end
      end
    end)
  end

  @spec update_time_code(map) ::
          {:ok, time_code} | {:error, :invalid_id | :reserved_name | :cannot_edit | term}
  def update_time_code(params) do
    params = params |> Helper.to_atom_map!()

    Agent.get_and_update(__MODULE__, fn state ->
      existing = Helper.get_by_or_nil(Repo, TimeCode, %{id: params[:id]})

      cond do
        existing == nil ->
          {{:error, :invalid_id}, state}

        existing.id == state.no_task_id ->
          {{:error, :cannot_edit}, state}

        params[:name] == "No Task" ->
          {{:error, :reserved_name}, state}

        true ->
          existing
          |> TimeCode.changeset(params)
          |> Repo.update()
          |> case do
            {:ok, time_code} ->
              time_code = TimeCode.to_map(time_code)

              state =
                AgentHelper.override_or_add(
                  state,
                  :time_codes,
                  time_code,
                  &(&1.id == time_code.id),
                  nil
                )

              {{:ok, time_code}, state}

            error ->
              {error, state}
          end
      end
    end)
  end

  @spec update_group(integer, String.t() | nil) ::
          {:ok, time_code_group()} | {:error, :invalid_id | term}
  def update_group(id, alias_name) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Helper.get_by_or_nil(Repo, TimeCodeGroup, %{id: id}) do
        nil ->
          {{:error, :invalid_id}, state}

        existing ->
          existing
          |> TimeCodeGroup.changeset(%{alias: alias_name})
          |> Repo.update()
          |> case do
            {:ok, group} ->
              group = TimeCodeGroup.to_map(group)
              state = AgentHelper.override(state, :time_code_groups, group, &(&1.id == id), nil)
              {{:ok, group}, state}

            error ->
              {error, state}
          end
      end
    end)
  end

  @spec get_time_code_tree_elements() :: list(time_code_tree_element)
  def get_time_code_tree_elements(), do: get(:time_code_tree_elements)

  @spec get_time_code_tree_elements(integer()) :: list(time_code_tree_element)
  def get_time_code_tree_elements(asset_type_id) do
    get_time_code_tree_elements()
    |> Enum.filter(&(&1.asset_type_id == asset_type_id))
  end

  @spec set_time_code_tree_elements(integer(), list(map)) ::
          {:ok, list(time_code_tree_element)}
          | {:error,
             :invalid_element
             | :parent_not_folder
             | :missing_parent
             | :duplicate_tree_ids
             | :invalid_asset_type
             | term}
  def set_time_code_tree_elements(asset_type_id, elements) do
    Agent.get_and_update(__MODULE__, fn state ->
      valid_asset_type_ids = Enum.map(AssetAgent.get_types(), & &1.id)

      case validate_elements(
             elements,
             asset_type_id,
             valid_asset_type_ids
           ) do
        {:ok, elements} ->
          min_provided_id =
            elements
            |> Enum.map(& &1.id)
            |> Enum.min(fn -> 0 end)

          delete_query = from(tct in TimeCodeTree, where: tct.asset_type_id == ^asset_type_id)

          Multi.new()
          |> Multi.delete_all(:delete_old, delete_query)
          |> Multi.run(:new_elements, fn repo, _ ->
            max_existing_id = repo.one(from(tct in TimeCodeTree, select: max(tct.id))) || 0

            elements_to_insert =
              elements
              |> Enum.map(&Map.put(&1, :asset_type_id, asset_type_id))
              |> apply_id_corrections(min_provided_id - 1, max_existing_id)

            {_, new_elements} = repo.insert_all(TimeCodeTree, elements_to_insert, returning: true)
            {:ok, new_elements}
          end)
          |> Repo.transaction()
          |> case do
            {:ok, %{new_elements: new_elements}} ->
              new_elements = Enum.map(new_elements, &TimeCodeTree.to_map/1)
              override_agent(asset_type_id, new_elements, state)

            error ->
              {error, state}
          end

        error ->
          {error, state}
      end
    end)
  end

  defp validate_elements(
         elements,
         asset_type_id,
         valid_asset_type_ids
       ) do
    elements =
      elements
      |> Enum.map(&Helper.to_atom_map!/1)
      |> Enum.map(&parse_element/1)
      |> Enum.sort_by(& &1.parent_id, &nil_first/2)

    tree_ids = Enum.map(elements, & &1.id)

    subfolders = Enum.filter(elements, &is_subfolder?/1)

    parent_ids =
      elements
      |> Enum.map(& &1.parent_id)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    cond do
      !Enum.member?(valid_asset_type_ids, asset_type_id) ->
        {:error, :invalid_asset_type}

      # no duplicate tree ids
      length(tree_ids) != length(Enum.uniq(tree_ids)) ->
        {:error, :duplicate_tree_ids}

      # ensure parent has element
      !has_subset?(tree_ids, parent_ids) ->
        {:error, :missing_parent}

      # ensure parent is a subfolder (and not a time code leaf)
      !has_subset?(Enum.map(subfolders, & &1.id), parent_ids) ->
        {:error, :parent_not_folder}

      !Enum.all?(elements, &is_valid_element?/1) ->
        {:error, :invalid_element}

      true ->
        {:ok, elements}
    end
  end

  defp is_valid_element?(element) do
    belongs_to_root_group = !!element.time_code_group_id

    # must have an id, and its id must be greater than the parent when given (ie parent comes before it)
    is_valid_element_id =
      element.id != nil && (element.parent_id == nil || element.id > element.parent_id)

    # time code && no node name OR no time code && a node name
    is_valid_time_code_node_name_combo =
      (element.time_code_id != nil && element.node_name == nil) ||
        (element.time_code_id == nil && element.node_name != nil)

    belongs_to_root_group && is_valid_element_id &&
      is_valid_time_code_node_name_combo
  end

  defp parse_element(element) do
    Enum.reduce(@required_keys, %{}, fn key, acc -> Map.put(acc, key, element[key]) end)
  end

  defp is_subfolder?(element), do: element.time_code_id == nil && element.node_name != nil

  defp has_subset?(source, subset), do: Enum.all?(subset, &Enum.member?(source, &1))

  defp nil_first(nil, _), do: true
  defp nil_first(_, nil), do: false
  defp nil_first(a, b), do: a <= b

  defp apply_id_corrections(elements, insert_offset, db_offset) do
    # correct the element ids and the parent ids
    elements
    |> Enum.map(fn element ->
      element
      |> Map.update!(:id, &(&1 - insert_offset + db_offset))
      |> Map.update!(:parent_id, fn id ->
        case id do
          nil -> nil
          _ -> id - insert_offset + db_offset
        end
      end)
    end)
  end

  defp override_agent(asset_type_id, elements, state) do
    remaining_elements =
      state.time_code_tree_elements
      |> Enum.filter(&(&1.asset_type_id !== asset_type_id))

    new_elements = remaining_elements ++ elements
    state = Map.put(state, :time_code_tree_elements, new_elements)

    {{:ok, elements}, state}
  end
end
