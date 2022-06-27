defmodule FleetControl.OperatorMessageAgent do
  use Agent

  require Logger

  alias FleetControl.{Helper, AgentHelper}
  alias HpsData.Schemas.Dispatch.{OperatorMessage, Acknowledge}

  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi

  @type type :: map
  @type message :: map

  @cull_opts %{
    time_key: :timestamp,
    max_age: 12 * 60 * 60,
    max_size: 500
  }

  @spec start_link(any()) :: {:ok, pid()}
  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    now = NaiveDateTime.utc_now()
    recent = NaiveDateTime.add(now, -@cull_opts.max_age, :second)

    %{
      messages: pull_messages(recent)
    }
  end

  defp pull_messages(recent) do
    from(om in OperatorMessage,
      where: om.server_timestamp > ^recent,
      select: %{
        id: om.id,
        device_id: om.device_id,
        asset_id: om.asset_id,
        operator_id: om.operator_id,
        type_id: om.type_id,
        timestamp: om.timestamp,
        server_timestamp: om.server_timestamp,
        acknowledge_id: om.acknowledge_id
      }
    )
    |> Repo.all()
  end

  @spec refresh!() :: :ok
  def refresh!(), do: AgentHelper.set(__MODULE__, &init/0)

  @spec all() :: list(message)
  def all(), do: Agent.get(__MODULE__, & &1.messages)

  @spec unread(integer) :: list(message)
  def unread(asset_id) do
    Enum.filter(all(), &(&1.asset_id == asset_id && is_nil(&1.acknowledge_id)))
  end

  @spec new(map) :: {:ok, message} | {:error, term}
  def new(message) do
    message =
      message
      |> Helper.to_atom_map!()
      |> OperatorMessage.new()

    Agent.get_and_update(__MODULE__, fn state ->
      message
      |> Repo.insert()
      |> update_agent(state)
    end)
  end

  @spec acknowledge(integer, NaiveDateTime.t()) ::
          {:ok, message} | {:error, :invalid_id | :already_acknowledged | term}
  def acknowledge(operator_msg_id, timestamp) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Helper.get_by_or_nil(Repo, OperatorMessage, %{id: operator_msg_id}) do
        nil ->
          {{:error, :invalid_id}, state}

        %{acknowledge_id: nil} = message ->
          acknowledgement = Acknowledge.new(%{timestamp: timestamp})

          transaction =
            Multi.new()
            |> Multi.insert(:acknowledgement, acknowledgement)
            |> Multi.run(:message, fn repo, %{acknowledgement: ack} ->
              message
              |> OperatorMessage.changeset(%{acknowledge_id: ack.id})
              |> repo.update()
            end)

          transaction
          |> Repo.transaction()
          |> case do
            {:ok, %{message: message}} -> update_agent({:ok, message}, state)
            error -> {error, state}
          end

        _ ->
          {{:error, :already_acknowledged}, state}
      end
    end)
  end

  defp update_agent({:ok, %OperatorMessage{} = message}, state) do
    message = OperatorMessage.to_map(message)
    update_agent({:ok, message}, state)
  end

  defp update_agent({:ok, message}, state) do
    state =
      AgentHelper.override_or_add(
        state,
        :messages,
        message,
        &(&1.id == message.id),
        @cull_opts
      )

    {{:ok, message}, state}
  end

  defp update_agent(error, state), do: {error, state}
end
