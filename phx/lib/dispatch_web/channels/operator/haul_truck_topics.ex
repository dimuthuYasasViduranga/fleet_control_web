defmodule DispatchWeb.OperatorChannel.HaulTruckTopics do
  @moduledoc """
  Holds the haul truck specific topics to make the operator channel cleaner
  """

  alias Dispatch.{Helper, HaulTruckDispatchAgent, ManualCycleAgent}
  alias DispatchWeb.Broadcast
  require Logger

  def get_asset_type_state(%{id: asset_id, type: "Haul Truck"}, operator) do
    %{
      dispatch: HaulTruckDispatchAgent.get(%{asset_id: asset_id}),
      manual_cycles:
        ManualCycleAgent.get_by(%{
          asset_id: asset_id,
          operator_id: operator.id,
          deleted: false
        })
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

  def handle_in("haul:submit manual cycles", cycles, socket) when is_list(cycles) do
    Enum.each(cycles, fn cycle ->
      ManualCycleAgent.add(cycle)

      Broadcast.send_activity(
        %{asset_id: cycle["asset_id"]},
        "operator",
        "Manual cycle submitted",
        cycle["timestamp"]
      )
    end)

    cycles
    |> Enum.map(&%{asset_id: &1["asset_id"]})
    |> Enum.uniq()
    |> Enum.each(&Broadcast.HaulTruck.send_manual_cycles_to_asset/1)

    Broadcast.HaulTruck.send_manual_cycles_to_dispatcher()

    {:reply, :ok, socket}
  end

  def handle_in("haul:delete manual cycle", cycle_id, socket) do
    now = Helper.naive_timestamp()

    case ManualCycleAgent.delete(cycle_id, now) do
      {:ok, cycle} ->
        Broadcast.send_activity(
          %{asset_id: cycle.asset_id},
          "operator",
          "Manual cycle delete",
          now
        )

        Broadcast.HaulTruck.send_manual_cycles_to_asset(%{asset_id: cycle.asset_id})
        Broadcast.HaulTruck.send_manual_cycles_to_dispatcher()

        {:reply, :ok, socket}

      _ ->
        {:reply, {:error, %{error: "cannot delete cycle"}}}
    end
  end
end
