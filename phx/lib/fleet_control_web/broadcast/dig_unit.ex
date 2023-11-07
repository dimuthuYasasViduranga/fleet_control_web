defmodule FleetControlWeb.Broadcast.DigUnit do
  @operators "operators"
  @dispatch "dispatchers:all"

  alias FleetControlWeb.{Endpoint, Broadcast}

  alias FleetControl.{DigUnitActivityAgent, HaulTruckDispatchAgent}

  def send_activities_to_all(action \\ :alert) do
    payload = %{
      current: DigUnitActivityAgent.current(),
      historic: DigUnitActivityAgent.historic(),
      live: DigUnitActivityAgent.fetch_dig_unit_activities(nil, nil),
      action: action
    }

    Broadcast.broadcast_all_operators("dig:set activities", %{activities: payload.current})
    Endpoint.broadcast(@dispatch, "dig:set activities", payload)
  end

  def send_activity_to_asset(identifier) do
    case Broadcast.get_assignment(identifier) do
      {device, assignment, _type} ->
        cur_activity = DigUnitActivityAgent.get(%{asset_id: assignment.asset_id})

        haul_truck_dispatches =
          HaulTruckDispatchAgent.current()
          |> Enum.filter(&(&1.dig_unit_id == assignment.asset_id))

        payload = %{
          activity: cur_activity,
          haul_truck_dispatches: haul_truck_dispatches
        }

        Endpoint.broadcast("#{@operators}:#{device.uuid}", "dig:set activity", payload)

      _ ->
        nil
    end
  end

  def send_activities_to_dispatcher() do
    payload = %{
      current: DigUnitActivityAgent.current(),
      historic: DigUnitActivityAgent.historic()
    }

    Endpoint.broadcast(@dispatch, "dig:set activities", payload)
  end
end
