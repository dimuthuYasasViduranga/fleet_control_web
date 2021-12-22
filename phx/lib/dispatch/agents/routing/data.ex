defmodule Dispatch.RoutingAgent.Data do
  alias HpsData.Schemas.Dispatch.Route
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]

  def fetch_data() do
    vertices = pull_vertices()
    edges = pull_edges()

    active_route = Route.Helper.fetch(Repo, NaiveDateTime.utc_now())

    %{
      vertices: vertices,
      edges: edges,
      active_route: active_route
    }
  end

  def pull_vertices() do
    Route.Vertex
    |> Repo.all()
    |> Enum.map(&Route.Vertex.to_map/1)
  end

  defp pull_edges() do
    Route.Edge
    |> Repo.all()
    |> Enum.map(&Route.Edge.to_map/1)
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

  def pull_route_elements() do
    elements =
      from(r in Route,
        join: re in Route.Element,
        on: [route_id: r.id],
        join: e in Route.Edge,
        on: [id: re.edge_id],
        join: v_start in Route.Vertex,
        on: [id: e.vertex_start_id],
        join: v_end in Route.Vertex,
        on: [id: e.vertex_end_id],
        select: %{
          route_id: r.id,
          restriction_group_id: r.restriction_group_id,
          start_time: r.start_time,
          end_time: r.end_time,
          edge: e,
          vertex_start: v_start,
          vertex_end: v_end
        }
      )
      |> Repo.all()
      |> Enum.map(&parse_route_element/1)

    vertices =
      elements
      |> Enum.map(&[&1.vertex_start, &1.vertex_end])
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

    {vertices, edges, routes}
  end

  defp parse_route_element(elem) do
    elem
    |> Map.put(:edge, Route.Edge.to_map(elem.edge))
    |> Map.put(:vertex_start, Route.Vertex.to_map(elem.vertex_start))
    |> Map.put(:vertex_end, Route.Vertex.to_map(elem.vertex_end))
  end

  @spec update(map, list(map), list(map), list(map)) :: {:ok, term} | {:error, term}
  def update(state, vertices, edges, restriction_groups) do
    IO.inspect("---- update")
    IO.inspect(Map.keys(state))
    IO.inspect(vertices)
    IO.inspect(edges)
    IO.inspect(restriction_groups)

    {:ok, state}
  end
end
