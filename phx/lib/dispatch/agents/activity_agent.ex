defmodule Dispatch.ActivityAgent do
  use Agent
  alias Dispatch.Culling

  @cull_opts %{
    time_key: :server_timestamp,
    max_size: 1000,
    max_age: 12 * 60 * 60
  }

  def start_link(_opts), do: Agent.start_link(fn -> [] end, name: __MODULE__)

  def get(), do: Agent.get(__MODULE__, & &1)

  def append(activity) do
    Agent.update(__MODULE__, &Culling.cull([activity | &1], @cull_opts))
  end
end
