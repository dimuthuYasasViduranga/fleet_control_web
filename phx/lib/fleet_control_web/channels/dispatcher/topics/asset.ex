defmodule FleetControlWeb.DispatcherChannel.Topics.Asset do
  alias FleetControl.AssetAgent
  alias FleetControl.TimeCodeAgent
  alias FleetControl.HaulTruckDispatchAgent
  alias FleetControl.DigUnitActivityAgent
  alias FleetControl.DeviceAssignmentAgent

  alias FleetControlWeb.Broadcast

  def handle_in("set-enabled", %{"asset_id" => asset_id, "state" => bool}, socket) do
    case set_asset_enabled(asset_id, bool) do
      :ok -> {:reply, :ok, socket}
      error -> {:reply, to_error(error), socket}
    end
  end

  defp set_asset_enabled(nil, _), do: {:error, :invalid_asset}

  defp set_asset_enabled(asset_id, true) do
    case AssetAgent.set_enabled(asset_id, true) do
      :ok ->
        no_task_id = TimeCodeAgent.no_task_id()
        add_default_time_allocation(asset_id, no_task_id)

        Broadcast.send_asset_data_to_all()
        Broadcast.send_active_allocation_to(%{asset_id: asset_id})
        Broadcast.send_allocations_to_dispatcher()
        Broadcast.send_assignments_to_all()

        :ok

      error ->
        error
    end
  end

  defp set_asset_enabled(asset_id, false) do
    case AssetAgent.set_enabled(asset_id, false) do
      :ok ->
        disabled_id = TimeCodeAgent.disabled_id()
        add_default_time_allocation(asset_id, disabled_id)

        Broadcast.force_logout(%{asset_id: asset_id})
        DeviceAssignmentAgent.clear(asset_id)
        HaulTruckDispatchAgent.clear(asset_id)
        DigUnitActivityAgent.clear(asset_id)

        case HaulTruckDispatchAgent.clear_dig_unit(asset_id) do
          {:ok, dispatches} ->
            identifiers = Enum.map(dispatches, &%{asset_id: &1.asset_id})
            Broadcast.HaulTruck.send_dispatches(identifiers)

          _ ->
            nil
        end

        Broadcast.send_asset_data_to_all()
        Broadcast.send_active_allocation_to(%{asset_id: asset_id})
        Broadcast.send_allocations_to_dispatcher()

        Broadcast.DigUnit.send_activities_to_all()

        Broadcast.send_assignments_to_all()

        :ok

      error ->
        error
    end
  end
end
