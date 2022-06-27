defmodule FleetControl.DeviceConnectionAgent do
  use Agent

  alias FleetControl.{AgentHelper, DeviceAgent}

  @type status :: :connected | :disconnected | :not_seen

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    data = %{status: :not_seen, timestamp: NaiveDateTime.utc_now()}

    DeviceAgent.all()
    |> Enum.map(&{&1.uuid, data})
    |> Enum.into(%{})
  end

  @spec get() :: map()
  def get(), do: Agent.get(__MODULE__, & &1)

  @spec set(String.t(), status, NaiveDateTime.t()) :: :ok
  def set(device_uuid, status, timestamp) when is_binary(device_uuid) do
    data = %{status: status, timestamp: timestamp}
    Agent.update(__MODULE__, &Map.put(&1, device_uuid, data))
  end
end
