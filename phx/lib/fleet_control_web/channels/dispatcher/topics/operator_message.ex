defmodule FleetControlWeb.DispatcherChannel.Topics.OperatorMessage do
  alias FleetControlWeb.Broadcast

  alias FleetControl.OperatorMessageTypeAgent
  alias FleetControl.OperatorMessageAgent

  import FleetControlWeb.DispatcherChannel, only: [to_error: 1]

  def handle_in("operator-message:acknowledge", nil, socket) do
    {:reply, to_error("No message id given"), socket}
  end

  def handle_in("operator-message:acknowledge", operator_msg_id, socket) do
    operator_msg_id
    |> OperatorMessageAgent.acknowledge(Helper.naive_timestamp())
    |> case do
      {:ok, %{asset_id: asset_id}} ->
        Broadcast.send_unread_operator_messages_to_operator(asset_id)

      _ ->
        nil
    end

    # broadcast messages to dispatchers
    Broadcast.send_operator_messages_to_dispatcher()
    Broadcast.send_activity(nil, "dispatcher", "operator message acknowledged")

    {:reply, :ok, socket}
  end

  @decorate authorized(:can_edit_messages)
  def handle_in("operator-message:update-message-type", payload, socket) do
    case payload["override"] do
      true -> OperatorMessageTypeAgent.override(payload)
      _ -> OperatorMessageTypeAgent.update(payload)
    end
    |> case do
      {:ok, _, _} ->
        Broadcast.send_operator_message_types()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  @decorate authorized(:can_edit_messages)
  def handle_in(
        "operator-message:set-type-tree",
        %{"asset_type_id" => asset_type_id, "ids" => ids},
        socket
      )
      when is_list(ids) do
    case OperatorMessageTypeAgent.update_tree(asset_type_id, ids) do
      {:ok, _} ->
        Broadcast.send_operator_message_type_tree_to_dispatcher()
        Broadcast.send_operator_message_type_tree_to(asset_type_id)
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end
end
