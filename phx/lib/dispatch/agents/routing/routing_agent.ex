defmodule Dispatch.RoutingAgent do
  use Agent

  require Logger

  alias Dispatch.AgentHelper

  alias __MODULE__.{Data, Validation}

  @type restriction_group :: %{
          id: integer,
          name: String.t(),
          asset_type_ids: list(integer)
        }

  @type route_node :: %{
          id: integer,
          lat: float,
          lon: float,
          alt: float | nil,
          deleted: boolean
        }

  @type edge :: %{
          id: integer,
          node_start_id: integer,
          node_end_id: integer,
          distance: float
        }

  @type route :: %{
          route_id: integer,
          restriction_group_id: integer | nil,
          start_time: NaiveDateTime.t(),
          end_time: NaiveDateTime.t() | nil,
          edge_ids: list[integer]
        }

  @type data :: %{
          restriction_groups: list(restriction_group),
          nodes: list(route_node),
          edges: list(edge),
          routes: list(route)
        }

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  def init(), do: Data.fetch_data() |> IO.inspect()

  @spec refresh!() :: :ok
  def refresh!(), do: AgentHelper.set(__MODULE__, &init/0)

  @spec get() :: data
  def get(), do: Agent.get(__MODULE__, & &1)

  @spec update(list(map), list(map), list(map)) :: {:ok, term} | {:error, term}
  def update(nodes, edges, restriction_groups) do
    IO.inspect("---- create route")

    {nodes, edges, restriction_groups} = parse(nodes, edges, restriction_groups)

    case Validation.validate(nodes, edges, restriction_groups) do
      :ok ->
        Agent.get_and_update(__MODULE__, &Data.update(&1, nodes, edges, restriction_groups))

      error ->
        error
    end
  end

  defp parse(nodes, edges, restriction_groups) do
    parsed_nodes =
      Enum.map(nodes, fn n ->
        %{
          ref_id: n["ref_id"],
          lat: n["lat"],
          lng: n["lng"]
        }
      end)

    parsed_edges =
      Enum.map(edges, fn e ->
        %{
          ref_id: e["ref_id"],
          node_start_ref_id: e["node_start_ref_id"],
          node_end_ref_id: e["node_end_ref_id"]
        }
      end)

    parsed_restriction_groups =
      Enum.map(restriction_groups, fn rg ->
        asset_type_ids =
          rg["asset_type_ids"]
          |> Enum.uniq()
          |> Enum.reject(&is_nil/1)

        edge_ref_ids =
          rg["edge_ref_ids"]
          |> Enum.uniq()
          |> Enum.reject(&is_nil/1)

        %{
          name: rg["name"],
          asset_type_ids: asset_type_ids,
          edge_ref_ids: edge_ref_ids
        }
      end)

    {parsed_nodes, parsed_edges, parsed_restriction_groups}
  end
end
