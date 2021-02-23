defmodule DispatchWeb.Broadcast.HaulTruck do
  @moduledoc """
  Broadcast extensions specific to "Haul Truck" class assets
  """

  @operators "operators"
  @dispatch "dispatchers:all"

  alias DispatchWeb.{Endpoint, Broadcast}

  alias Dispatch.{AssetAgent, HaulTruckDispatchAgent, ManualCycleAgent}

  def send_dispatches(identifiers \\ []) when is_list(identifiers) do
    Enum.each(identifiers, &send_dispatch_to_asset/1)
    send_dispatches_to_dispatcher()
    send_dispatches_to_dig_units()
    send_dispatches_to_water_carts()
  end

  def send_dispatch(identifier), do: send_dispatches([identifier])

  defp send_dispatch_to_asset(identifier) do
    case Broadcast.get_assignment(identifier) do
      {device, assignment, _type} ->
        cur_dispatch = HaulTruckDispatchAgent.get(%{asset_id: assignment.asset_id})

        Endpoint.broadcast("#{@operators}:#{device.uuid}", "haul:set dispatch", %{
          dispatch: cur_dispatch
        })

      _ ->
        nil
    end
  end

  def send_dispatches_to_dispatcher() do
    dispatches = %{
      current: HaulTruckDispatchAgent.current(),
      historic: HaulTruckDispatchAgent.historic()
    }

    Endpoint.broadcast(@dispatch, "haul:set dispatches", dispatches)
  end

  def send_dispatches_to_dig_units() do
    dispatches = %{
      dispatches: HaulTruckDispatchAgent.current()
    }

    AssetAgent.get_assets()
    |> Enum.filter(&(&1.type in ["Excavator", "Loader"]))
    |> Enum.map(fn load_unit ->
      case Broadcast.get_assignment(%{asset_id: load_unit.id}) do
        {device, _assignment, _type} ->
          Endpoint.broadcast("#{@operators}:#{device.uuid}", "dig:set dispatches", dispatches)

        _ ->
          nil
      end
    end)
  end

  def send_dispatches_to_water_carts() do
    dispatches = %{
      dispatches: HaulTruckDispatchAgent.current()
    }

    AssetAgent.get_assets()
    |> Enum.filter(&(&1.type == "Watercart"))
    |> Enum.map(fn load_unit ->
      case Broadcast.get_assignment(%{asset_id: load_unit.id}) do
        {device, _assignment, _type} ->
          Endpoint.broadcast(
            "#{@operators}:#{device.uuid}",
            "watercart:set dispatches",
            dispatches
          )

        _ ->
          nil
      end
    end)
  end

  def send_manual_cycles_to_asset(identifier) do
    case Broadcast.get_assignment(identifier) do
      {device, %{asset_id: asset_id, operator_id: operator_id}, _type} ->
        cycles =
          ManualCycleAgent.get_by(%{asset_id: asset_id, operator_id: operator_id, deleted: false})

        Endpoint.broadcast("#{@operators}:#{device.uuid}", "haul:set manual cycles", %{
          cycles: cycles
        })

      _ ->
        nil
    end
  end

  def send_manual_cycles_to_dispatcher() do
    cycles = Enum.reject(ManualCycleAgent.get(), &(&1.deleted == true))
    Endpoint.broadcast(@dispatch, "haul:set manual cycles", %{cycles: cycles})
  end
end
