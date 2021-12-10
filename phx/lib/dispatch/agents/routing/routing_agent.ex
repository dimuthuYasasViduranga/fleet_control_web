defmodule Dispatch.RoutingAgent do
  use Agent
  alias Dispatch.AgentHelper
  require Logger

  alias __MODULE__.Data

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

  def create_route(nodes, unrestricted_edges, restriction_groups) do
    # nodes
    #   - negative ids represent new nodes
    # fallback_edges
    #   - the unrestricted edges that all restriction groups use as a subset
    # restriction groups (these will need to be handle separately to reference them later)
    #   - each have
    #     { name, asset_types, edges}
    #     - the edges must be a subset of the fallback_edges (just for sanity reasons)

    IO.inspect("--- this is going to need a lot of stuff")
  end
end
