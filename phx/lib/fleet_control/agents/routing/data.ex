defmodule FleetControl.RoutingAgent.Data do
  alias HpsData.Schemas.Dispatch.Route
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]

  alias Ecto.Multi

  @type state :: map()

  def fetch_data() do
    active_route = Route.Helper.fetch(Repo, NaiveDateTime.utc_now())

    %{
      active_route: active_route
    }
  end

  @spec update(state, list(map), list(map), list(map)) :: {:ok, state} | {{:error, term}, state}
  def update(state, vertices, edges, restriction_groups) do
    now = NaiveDateTime.utc_now()

    cur_route_id = state.active_route[:id]

    Multi.new()
    |> m_close_cur_route(cur_route_id, now)
    |> m_create_route(now)
    |> m_insert_new_vertices(vertices)
    |> m_insert_new_edges(edges)
    |> m_insert_elements()
    |> m_insert_restriction_groups(restriction_groups)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        new_state = fetch_data()
        {{:ok, new_state}, new_state}

      error ->
        {error, state}
    end
  end

  defp m_close_cur_route(multi, nil, _end_time), do: multi

  defp m_close_cur_route(multi, route_id, end_time) do
    clear_query =
      from(ts in Route,
        where: ts.id == ^route_id
      )

    Multi.update_all(multi, :close_active, clear_query, set: [end_time: end_time])
  end

  defp m_create_route(multi, start_time) do
    new_route = %Route{
      server_timestamp: NaiveDateTime.utc_now(),
      start_time: start_time,
      end_time: nil,
      deleted: false
    }

    Multi.insert(multi, :new_route, new_route, returning: true)
  end

  defp m_insert_new_vertices(multi, vertices) do
    new = Enum.filter(vertices, &(&1.id < 0))

    existing_lookup =
      vertices
      |> Enum.filter(&(&1.id >= 0))
      |> Enum.map(&{&1.id, &1.id})
      |> Enum.into(%{})

    new_vertices =
      Enum.map(new, fn v ->
        %{
          lat: v.lat,
          lng: v.lng,
          alt: v[:alt],
          deleted: false
        }
      end)

    Multi.run(multi, :vertices, fn repo, _ ->
      count = length(new)

      repo.insert_all(Route.Vertex, new_vertices, returning: true)
      |> case do
        {^count, ecto_vertices} ->
          lookup =
            Enum.zip(new, ecto_vertices)
            |> Enum.map(fn {a, b} -> {a.id, b.id} end)
            |> Enum.into(%{})
            |> Map.merge(existing_lookup)

          {:ok, lookup}

        _ ->
          {:error, :failed_vertices}
      end
    end)
  end

  defp m_insert_new_edges(multi, edges) do
    new = Enum.filter(edges, &(&1.id < 0))

    existing_lookup =
      edges
      |> Enum.filter(&(&1.id >= 0))
      |> Enum.map(&{&1.id, &1.id})
      |> Enum.into(%{})

    Multi.run(multi, :edges, fn repo, %{vertices: vertex_lookup} ->
      count = length(new)

      new_edges =
        Enum.map(new, fn e ->
          %{
            vertex_start_id: vertex_lookup[e.vertex_start_id],
            vertex_end_id: vertex_lookup[e.vertex_end_id],
            distance: e.distance,
            deleted: false
          }
        end)

      repo.insert_all(Route.Edge, new_edges, returning: true)
      |> case do
        {^count, ecto_edges} ->
          lookup =
            Enum.zip(new, ecto_edges)
            |> Enum.map(fn {a, b} -> {a.id, b.id} end)
            |> Enum.into(%{})
            |> Map.merge(existing_lookup)

          {:ok, lookup}

        _ ->
          {:error, :failed_edges}
      end
    end)
  end

  defp m_insert_elements(multi) do
    Multi.run(multi, :elements, fn repo, %{new_route: new_route, edges: edges} ->
      elements =
        edges
        |> Map.values()
        |> Enum.map(fn edge_id ->
          %{
            route_id: new_route.id,
            edge_id: edge_id
          }
        end)

      count = length(elements)

      case repo.insert_all(Route.Element, elements) do
        {^count, ret} -> {:ok, ret}
        _ -> {:error, :failed_elements}
      end
    end)
  end

  defp m_insert_restriction_groups(multi, groups) do
    ecto_groups =
      Enum.map(groups, fn g ->
        %{
          name: g.name,
          asset_type_ids: g.asset_type_ids
        }
      end)

    multi
    |> Multi.insert_all(:restriction_groups, Route.RestrictionGroup, ecto_groups, returning: true)
    |> Multi.run(:restriction_elements, fn repo, state ->
      {_count, restriction_groups} = state.restriction_groups

      elements =
        Enum.zip(groups, restriction_groups)
        |> Enum.map(fn {g, rg} ->
          Enum.map(g.edge_ids, fn edge_id ->
            %{
              restriction_group_id: rg.id,
              route_id: state.new_route.id,
              edge_id: state.edges[edge_id]
            }
          end)
        end)
        |> List.flatten()

      count = length(elements)

      case repo.insert_all(Route.RestrictionElement, elements) do
        {^count, ret} -> {:ok, ret}
        _ -> {:error, :failed_restriction_elements}
      end
    end)
  end
end
