defmodule FleetControlWeb.OperatorChannel.HaulTruckTopics do
  @moduledoc """
  Holds the haul truck specific topics to make the operator channel cleaner
  """
  require Logger

  alias FleetControl.HaulTruckDispatchAgent
  alias FleetControlWeb.Broadcast

  def get_asset_type_state(%{id: asset_id, type: "Haul Truck"}, _operator_id) do
    %{
      dispatch: HaulTruckDispatchAgent.get(%{asset_id: asset_id})
    }
  end

  def handle_in("haul:acknowledge dispatches", dispatches, socket) when is_list(dispatches) do
    device_id = socket.assigns.device_id

    Enum.each(dispatches, fn %{"id" => id, "timestamp" => timestamp} ->
      case HaulTruckDispatchAgent.acknowledge(id, device_id, timestamp) do
        {:error, :invalid_id} ->
          Logger.warn("Cannot acknowledge dispatch `#{id}` as it does not exist")

        {:error, :already_acknowledged} ->
          Logger.warn("Dispatch `#{id}` already acknowledged")

        _ ->
          nil
      end

      Broadcast.send_activity(
        %{device_id: device_id},
        "operator",
        "dispatch acknowledged",
        timestamp
      )
    end)

    Broadcast.HaulTruck.send_dispatch(%{device_id: device_id})

    {:reply, :ok, socket}
  end
end
