defmodule FleetControl.DispatcherMessageAgent do
  use Agent

  alias FleetControl.{Helper, AgentHelper}
  alias HpsData.Schemas.Dispatch.{Message, Acknowledge}
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi

  @cull_opts %{
    time_key: :timestamp,
    max_age: 12 * 60 * 60
  }

  @type message :: map
  @type answer :: String.t()

  @spec start_link(any()) :: {:ok, pid()}
  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    now = Helper.naive_timestamp()
    recent = NaiveDateTime.add(now, -@cull_opts.max_age, :second)

    messages =
      from(dm in Message,
        where: dm.timestamp > ^recent,
        select: %{
          id: dm.id,
          asset_id: dm.asset_id,
          message: dm.message,
          timestamp: dm.timestamp,
          server_timestamp: dm.server_timestamp,
          acknowledge_id: dm.acknowledge_id,
          group_id: dm.group_id,
          answers: dm.answers,
          answer: dm.answer,
          dispatcher_id: dm.dispatcher_id
        }
      )
      |> Repo.all()

    %{messages: messages}
  end

  @spec all() :: list
  def all(), do: Agent.get(__MODULE__, & &1.messages)

  @spec all(list(integer)) :: list(message)
  def all(asset_id), do: Enum.filter(all(), &(&1.asset_id == asset_id))

  @spec new(message) :: {:ok, message} | {:error, term}
  def new(%{"asset_id" => _asset_id} = message) do
    message
    |> Helper.to_atom_map!()
    |> new()
  end

  def new(message) do
    message = Message.new(message)

    Agent.get_and_update(__MODULE__, fn state ->
      message
      |> Repo.insert()
      |> case do
        {:ok, message} ->
          {resp, state} = update_agent(message, state)
          {{:ok, resp}, state}

        error ->
          {error, state}
      end
    end)
  end

  @spec new_mass_message(list(integer), message, integer | nil, list(answer), NaiveDateTime.t()) ::
          {:ok, list(message)} | {:error, term}
  def new_mass_message(asset_ids, message, dispatcher_id, answers, timestamp) do
    cond do
      is_nil(asset_ids) or asset_ids == [] -> {:error, :invalid_asset_ids}
      !is_nil(answers) and length(answers) < 2 -> {:error, :invalid_answers}
      is_nil(message) -> {:error, :invalid_message}
      true -> insert_mass_message(asset_ids, message, dispatcher_id, answers, timestamp)
    end
  end

  defp insert_mass_message(asset_ids, message, dispatcher_id, answers, timestamp) do
    timestamp = Helper.to_naive(timestamp)
    server_timestamp = Helper.naive_timestamp()

    messages =
      asset_ids
      |> Enum.uniq()
      |> Enum.map(fn id ->
        %{
          asset_id: id,
          group_id: nil,
          message: message,
          answers: answers,
          timestamp: timestamp,
          server_timestamp: server_timestamp,
          dispatcher_id: dispatcher_id
        }
      end)

    transaction =
      Multi.new()
      |> Multi.insert_all(:messages, Message, messages, returning: true)
      |> Multi.run(:group_id, fn repo, %{messages: {_, msgs}} ->
        ids = Enum.map(msgs, & &1.id)
        min_id = Enum.min(ids)

        from(m in Message, where: m.id in ^ids)
        |> repo.update_all(set: [group_id: min_id])
        |> case do
          {0, _} -> {:error, :failed_group_id}
          _ -> {:ok, min_id}
        end
      end)

    Agent.get_and_update(__MODULE__, fn state ->
      transaction
      |> Repo.transaction()
      |> case do
        {:ok, %{messages: {_, inserted_msgs}, group_id: group_id}} ->
          inserted_msgs = Enum.map(inserted_msgs, &Map.put(&1, :group_id, group_id))
          {resp, state} = update_agent(inserted_msgs, state)
          {{:ok, resp}, state}

        error ->
          {error, state}
      end
    end)
  end

  @spec acknowledge(integer, answer | nil, integer, NaiveDateTime.t()) ::
          {:ok, message} | {:error, term}
  def acknowledge(dispatch_msg_id, answer, device_id, timestamp) do
    message = Helper.get_by_or_nil(Repo, Message, %{id: dispatch_msg_id})

    cond do
      is_nil(message) -> {:error, :invalid_id}
      !is_nil(message.acknowledge_id) -> {:error, :already_acknowledged}
      !valid_answer?(message.answers, answer) -> {:error, :invalid_answer}
      true -> insert_acknowledgement(message, answer, device_id, timestamp)
    end
  end

  defp valid_answer?(nil, nil), do: true
  defp valid_answer?(_, nil), do: true
  defp valid_answer?(possible, answer), do: Enum.member?(possible, answer)

  defp insert_acknowledgement(message, answer, device_id, timestamp) do
    acknowledgement = Acknowledge.new(%{device_id: device_id, timestamp: timestamp})

    transaction =
      Multi.new()
      |> Multi.insert(:ack, acknowledgement)
      |> Multi.run(:message, fn repo, %{ack: ack} ->
        message
        |> Message.changeset(%{answer: answer, acknowledge_id: ack.id})
        |> repo.update()
      end)

    Agent.get_and_update(__MODULE__, fn state ->
      transaction
      |> Repo.transaction()
      |> case do
        {:ok, %{message: message}} ->
          {resp, state} = update_agent(message, state)
          {{:ok, resp}, state}

        error ->
          {error, state}
      end
    end)
  end

  defp update_agent([%Message{} = message | messages], state) do
    {message, state} = update_agent(message, state)
    {messages, state} = update_agent(messages, state)
    {[message | messages], state}
  end

  defp update_agent([], state), do: {[], state}

  defp update_agent(%Message{} = message, state) do
    message
    |> Message.to_map()
    |> update_agent(state)
  end

  defp update_agent(message, state) do
    state =
      AgentHelper.override_or_add(
        state,
        :messages,
        message,
        &(&1.id == message.id),
        @cull_opts
      )

    {message, state}
  end
end
