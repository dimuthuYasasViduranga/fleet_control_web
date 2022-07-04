defmodule FleetControlWeb.DispatcherChannel.Topics.DispatcherMessage do
  alias FleetControlWeb.Broadcast
  alias FleetControl.DispatcherMessageAgent

  def handle_in("dispatcher-message:add", payload, socket) do
    dispatcher_id = get_dispatcher_id(socket)

    payload
    |> Map.put("dispatcher_id", dispatcher_id)
    |> DispatcherMessageAgent.new()
    |> case do
      {:ok, _} ->
        Broadcast.send_dispatcher_messages_to(%{asset_id: payload["asset_id"]})
        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, to_error(reason), socket}
    end
  end

  def handle_in("dispatcher-message:mass-add", payload, socket) do
    %{
      "asset_ids" => asset_ids,
      "message" => message,
      "timestamp" => timestamp
    } = payload

    dispatcher_id = get_dispatcher_id(socket)

    asset_ids
    |> DispatcherMessageAgent.new_mass_message(
      message,
      dispatcher_id,
      payload["answers"],
      timestamp
    )
    |> case do
      {:ok, _} ->
        Broadcast.send_dispatcher_messages_to(asset_ids)
        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, to_error(reason), socket}
    end
  end
end
