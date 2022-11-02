defmodule FleetControl.ActivityAgent do
  use Agent
  alias FleetControl.Culling

  @cull_opts %{
    time_key: :server_timestamp,
    max_size: 1000,
    max_age: 12 * 60 * 60
  }

  def start_link(_opts),
    do:
      Agent.start_link(
        fn -> %{activities: [], sequence_number: 0} end,
        name: __MODULE__
      )

  def get(), do: Agent.get(__MODULE__, & &1)

  def append(activity) do
    Agent.update(__MODULE__, &do_append(&1, activity))
  end

  defp do_append(%{activities: activities, sequence_number: sequence_number}, activity) do
    activities = Culling.cull(activities, @cull_opts)
    activities = [activity | activities]
    sequence_number = sequence_number + 1

    Endpoint.broadcast("dispatchers:all", "append activity log", %{
      activity: activity,
      sequence_number: sequence_number
    })

    %{activities: activities, sequence_number: sequence_number}
  end
end
