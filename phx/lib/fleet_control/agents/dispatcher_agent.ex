defmodule FleetControl.DispatcherAgent do
  @moduledoc """
  Store for all dispatcher user information
  """

  use Agent
  alias FleetControl.AgentHelper
  alias FleetControl.Culling
  require Logger

  alias HpsData.Schemas.Dispatch.Dispatcher
  alias HpsData.Repo

  @type dispatcher :: map()

  import Ecto.Query, only: [from: 2]

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  def init() do
    from(d in Dispatcher,
      select: %{
        id: d.id,
        user_id: d.user_id,
        name: d.name
      }
    )
    |> Repo.all()
  end

  @spec all() :: list(dispatcher)
  def all(), do: Agent.get(__MODULE__, & &1)

  @spec add(binary, String.t()) :: {:ok, dispatcher} | {:error, term}
  def add(user_id, name) do
    Agent.get_and_update(__MODULE__, fn dispatchers ->
      case Enum.find(dispatchers, &(&1.user_id == user_id)) do
        nil ->
          %{user_id: user_id, name: name}
          |> Dispatcher.new()
          |> Repo.insert()

        dispatcher ->
          %Dispatcher{}
          |> Map.merge(dispatcher)
          |> Dispatcher.changeset(%{name: name})
          |> Repo.update()
      end
      |> update_agent(dispatchers)
    end)
  end

  defp update_agent({:ok, %Dispatcher{} = dispatcher}, state) do
    dispatcher = Dispatcher.to_map(dispatcher)
    update_agent({:ok, dispatcher}, state)
  end

  defp update_agent({:ok, dispatcher}, state) do
    state = Culling.override_or_add(state, dispatcher, &(&1.user_id == dispatcher.user_id), nil)
    {{:ok, dispatcher}, state}
  end

  defp update_agent(error, state), do: {error, state}
end
