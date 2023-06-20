defmodule FleetControlWeb.DispatcherChannel.Topics.Device do
  alias FleetControlWeb.Broadcast

  alias FleetControl.AssetAgent
  alias FleetControl.DeviceAgent
  alias FleetControlWeb.DispatcherChannel

  alias FleetControl.HaulTruckDispatchAgent
  alias FleetControl.DeviceAssignmentAgent
  alias FleetControl.DigUnitActivityAgent

  use HpsPhx.Authorization.Decorator
  import FleetControlWeb.DispatcherChannel, only: [to_error: 1]
  require Logger

  def handle_in("force-logout", %{"device_id" => device_id} = payload, socket) do
    time_code_id = payload["time_code_id"]

    case DeviceAssignmentAgent.get(%{device_id: device_id}) do
      %{asset_id: asset_id} ->
        DispatcherChannel.add_default_time_allocation(asset_id, time_code_id)
        |> case do
          {:ok, _} ->
            Broadcast.send_active_allocation_to(%{asset_id: asset_id})
            Broadcast.send_allocations_to_dispatcher()

          _ ->
            nil
        end

      _ ->
        nil
    end

    Broadcast.force_logout(%{device_id: device_id}, %{clear_operator: true})

    {:reply, :ok, socket}
  end

  def handle_in(
        "mass-force-logout",
        %{"asset_ids" => asset_ids, "time_code_id" => time_code_id},
        socket
      ) do
    Enum.each(asset_ids, fn asset_id ->
      DispatcherChannel.add_default_time_allocation(asset_id, time_code_id)
      |> case do
        {:ok, _} ->
          Broadcast.send_active_allocation_to(%{asset_id: asset_id})
          Broadcast.force_logout(%{asset_id: asset_id}, %{clear_operator: true})

        _ ->
          nil
      end
    end)

    Broadcast.send_allocations_to_dispatcher()

    {:reply, :ok, socket}
  end

  @decorate authorized_channel("fleet_control_edit_devices")
  def handle_in("set-assigned-asset", payload, socket) do
    %{"device_id" => device_id, "asset_id" => asset_id} = payload

    case set_assigned_asset(device_id, asset_id) do
      :ok -> {:reply, :ok, socket}
      error -> {:reply, to_error(error), socket}
    end
  end

  @decorate authorized_channel("fleet_control_edit_devices")
  def handle_in("set-details", %{"device_id" => device_id, "details" => details}, socket) do
    case DeviceAgent.update_details(device_id, details) do
      {:ok, _} ->
        Broadcast.send_devices_to_dispatcher()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  defp set_assigned_asset(device_id, new_asset_id) do
    case valid_device_and_asset(device_id, new_asset_id) do
      :ok ->
        nil

        # logout given device. Re-join if not removed from an asset
        Broadcast.force_logout(%{device_id: device_id}, %{rejoin: new_asset_id != nil})

        # remove existing asset assignment
        remove_device_from_asset(device_id)

        # set new assignment
        set_device_to_asset(device_id, new_asset_id)

        :ok

      error ->
        error
    end
  end

  defp valid_device_and_asset(device_id, asset_id) do
    device = DeviceAgent.get(%{id: device_id})
    asset = AssetAgent.get_asset(%{id: asset_id})

    cond do
      device == nil -> {:error, :invalid_device_id}
      asset_id != nil && asset == nil -> {:error, :invalid_asset_id}
      true -> :ok
    end
  end

  defp remove_device_from_asset(device_id) do
    case DeviceAssignmentAgent.get_asset_id(%{device_id: device_id}) do
      nil ->
        nil

      old_asset_id ->
        Logger.info(
          "[DeviceAssignment] device '#{device_id}' unassigned from asset '#{old_asset_id}'"
        )

        # clear any settings for the asset
        HaulTruckDispatchAgent.clear(old_asset_id)
        DigUnitActivityAgent.clear(old_asset_id)
        DeviceAssignmentAgent.clear(old_asset_id)

        Broadcast.send_activity(%{asset_id: old_asset_id}, "dispatcher", "device unassigned")
        Broadcast.HaulTruck.send_dispatches()
        Broadcast.DigUnit.send_activities_to_all()
        Broadcast.send_assignments_to_all()
    end
  end

  defp set_device_to_asset(_device_id, nil), do: nil

  defp set_device_to_asset(device_id, asset_id) do
    Logger.info("[DeviceAssignment] device '#{device_id}' assigned to asset '#{asset_id}'")

    DeviceAssignmentAgent.change(asset_id, %{
      device_id: device_id,
      operator_id: nil
    })

    Broadcast.send_activity(%{asset_id: asset_id}, "dispatcher", "device assigned")
    Broadcast.send_assignments_to_all()
  end
end
