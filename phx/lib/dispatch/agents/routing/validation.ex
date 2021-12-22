defmodule Dispatch.RoutingAgent.Validation do
  # two ees to no override build in node
  @type nodee :: %{
          ref_id: integer,
          lat: number,
          lng: number
        }

  @type edge :: %{
          ref_id: integer,
          node_start_ref_id: integer,
          node_end_ref_id: integer
        }

  @type restriction_group :: %{
          name: String.t(),
          asset_type_ids: list(integer),
          edge_ref_ids: list(integer)
        }

  @spec(validate(list(nodee), list(edge), list(restriction_group)) :: :ok, {:error, term})
  def validate(nodes, edges, restriction_groups) do
    %{
      nodes: nodes,
      edges: edges,
      restriction_groups: restriction_groups
    }
    |> abortable_chain([
      &validate_nodes/1,
      &validate_edges/1,
      &validate_restriction_groups/1
    ])
    |> case do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp to_map(list) do
    list
    |> Enum.map(&{&1.ref_id, &1})
    |> Enum.into(%{})
  end

  defp abortable_chain(state, []), do: {:ok, state}

  defp abortable_chain(state, [check_fun | remaining_checks]) do
    case check_fun.(state) do
      {:ok, new_state} -> abortable_chain(new_state, remaining_checks)
      {:error, _} = error -> error
    end
  end

  defp first_error(list, callback) do
    Enum.reduce_while(list, nil, fn e, _acc ->
      case callback.(e) do
        :ok -> {:cont, nil}
        error -> {:halt, error}
      end
    end)

    nil
  end

  defp has_duplicates?(list), do: Enum.uniq(list) != list

  defp validate_nodes(state) do
    invalid_node_reason = first_error(state.nodes, &validate_node/1)

    cond do
      !is_nil(invalid_node_reason) ->
        invalid_node_reason

      has_duplicates?(Enum.map(state.nodes, & &1.ref_id)) ->
        {:error, :duplicate_ref_ids}

      true ->
        {:ok, state}
    end
  end

  defp validate_node(n) do
    cond do
      is_nil(n.ref_id) -> {:error, :nil_ref_id}
      is_nil(n.lat) -> {:error, :invalid_latitude}
      is_nil(n.lng) -> {:error, :invalid_longitude}
      true -> :ok
    end
  end

  defp validate_edges(state) do
    node_map = to_map(state.nodes)

    invalid_edge_reason = first_error(state.edges, &validate_edge(&1, node_map))

    cond do
      !is_nil(invalid_edge_reason) ->
        invalid_edge_reason

      has_duplicates?(Enum.map(state.edges, & &1.ref_id)) ->
        {:error, :duplicate_ref_ids}

      true ->
        {:ok, state}
    end
  end

  defp validate_edge(edge, node_map) do
    cond do
      is_nil(edge.ref_id) -> {:error, :nil_ref_id}
      is_nil(node_map[edge.node_start_ref_id]) -> {:error, :invalid_start_ref_id}
      is_nil(node_map[edge.node_end_ref_id]) -> {:error, :invalid_end_ref_id}
      true -> :ok
    end
  end

  defp validate_restriction_groups(state) do
    invalid_group_reason = first_error(state.restriction_groups, &validate_restriction_group/1)

    all_asset_type_ids = Enum.flat_map(state.restriction_groups, & &1.asset_type_ids)

    cond do
      !is_nil(invalid_group_reason) ->
        invalid_group_reason

      has_duplicates?(all_asset_type_ids) ->
        {:error, :duplicate_asset_types_between_groups}

      true ->
        {:ok, state}
    end
  end

  defp validate_restriction_group(group) do
    cond do
      (group.name || "") == "" -> {:error, :invalid_name}
      Enum.any?(group.asset_type_ids, &is_nil/1) -> {:error, :nil_asset_type_id}
      Enum.any?(group.edge_ref_ids, &is_nil/1) -> {:error, :nil_edge_ref_id}
      has_duplicates?(group.asset_type_ids) -> {:error, :duplicate_asset_type_ids}
      has_duplicates?(group.edge_ref_ids) -> {:error, :duplicate_edge_ref_ids}
      true -> :ok
    end
  end
end
