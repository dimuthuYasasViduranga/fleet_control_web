defmodule Dispatch.RoutingAgent.Data do
  alias HpsData.Schemas.Dispatch.Route
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]

  def fetch_data() do
    {nodes, edges, routes} = pull_route_components()

    %{
      restriction_groups: pull_restriction_groups(),
      nodes: nodes,
      edges: edges,
      routes: routes
    }
  end

  def pull_restriction_groups() do
    from(rg in Route.RestrictionGroup,
      select: %{
        id: rg.id,
        name: rg.name,
        asset_type_ids: rg.asset_type_ids
      }
    )
    |> Repo.all()
  end

  def pull_route_components() do
    elements =
      from(r in Route,
        join: n in Route.Network,
        on: [route_id: r.id],
        join: e in Route.Edge,
        on: [id: n.edge_id],
        join: n_start in Route.Node,
        on: [id: e.node_start_id],
        join: n_end in Route.Node,
        on: [id: e.node_end_id],
        select: %{
          route_id: r.id,
          restriction_group_id: r.restriction_group_id,
          start_time: r.start_time,
          end_time: r.end_time,
          edge: e,
          node_start: n_start,
          node_end: n_end
        }
      )
      |> Repo.all()
      |> Enum.map(&parse_route_element/1)

    nodes =
      elements
      |> Enum.map(&[&1.node_start, &1.node_end])
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.sort_by(& &1.id)

    edges =
      elements
      |> Enum.map(& &1.edge)
      |> Enum.uniq()
      |> Enum.sort_by(& &1.id)

    shared_keys = [:route_id, :restriction_group_id, :start_time, :end_time]

    routes =
      elements
      |> Enum.group_by(&Map.take(&1, shared_keys), & &1.edge.id)
      |> Enum.map(fn {route, edge_ids} -> Map.put(route, :edge_ids, edge_ids) end)

    {nodes, edges, routes}
  end

  defp parse_route_element(elem) do
    elem
    |> Map.put(:edge, Route.Edge.to_map(elem.edge))
    |> Map.put(:node_start, Route.Node.to_map(elem.node_start))
    |> Map.put(:node_end, Route.Node.to_map(elem.node_end))
  end
end
