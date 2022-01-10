defmodule Dispatch.RoutingAgent do
  use Agent

  require Logger

  alias Dispatch.AgentHelper

  alias __MODULE__.{Data, Validation}

  @type vertex :: %{
          id: integer,
          lat: float,
          lng: float,
          alt: float | nil,
          deleted: boolean
        }

  @type edge :: %{
          id: integer,
          vertex_start_id: integer,
          vertex_end_id: integer,
          distance: float
        }

  @type data :: %{
          vertices: list(vertex),
          edges: list(edge),
          active_route: map | nil
        }

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  def init(), do: Data.fetch_data() |> IO.inspect()

  @spec refresh!() :: :ok
  def refresh!(), do: AgentHelper.set(__MODULE__, &init/0)

  @spec get() :: data
  def get(), do: Agent.get(__MODULE__, & &1)

  @spec update(list(map), list(map), list(map)) :: {:ok, term} | {:error, term}
  def update(vertices, edges, restriction_groups) do
    {vertices, edges, restriction_groups} = parse(vertices, edges, restriction_groups)

    case Validation.validate(vertices, edges, restriction_groups) do
      :ok ->
        Agent.get_and_update(__MODULE__, &Data.update(&1, vertices, edges, restriction_groups))

      error ->
        error
    end
  end

  defp parse(vertices, edges, restriction_groups) do
    parsed_vertices =
      Enum.map(vertices, fn n ->
        %{
          id: n["id"],
          lat: n["lat"],
          lng: n["lng"],
          alt: n["alt"],
        }
      end)

    parsed_edges =
      Enum.map(edges, fn e ->
        %{
          id: e["id"],
          vertex_start_id: e["vertex_start_id"],
          vertex_end_id: e["vertex_end_id"]
        }
      end)

    parsed_restriction_groups =
      Enum.map(restriction_groups, fn rg ->
        asset_type_ids =
          rg["asset_type_ids"]
          |> Enum.uniq()
          |> Enum.reject(&is_nil/1)

        edge_ids =
          rg["edge_ids"]
          |> Enum.uniq()
          |> Enum.reject(&is_nil/1)

        %{
          name: rg["name"],
          asset_type_ids: asset_type_ids,
          edge_ids: edge_ids
        }
      end)

    {parsed_vertices, parsed_edges, parsed_restriction_groups}
  end
end
