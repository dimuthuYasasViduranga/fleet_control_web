defmodule Dispatch.RoutingAgent do
  use Agent
  alias Dispatch.AgentHelper
  require Logger

  alias __MODULE__.Data

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  def init(), do: Data.fetch_data() |> IO.inspect()

  @spec refresh!() :: :ok
  def refresh!(), do: AgentHelper.set(__MODULE__, &init/0)


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
