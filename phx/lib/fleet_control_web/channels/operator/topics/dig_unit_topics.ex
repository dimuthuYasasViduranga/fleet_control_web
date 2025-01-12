defmodule FleetControlWeb.OperatorChannel.DigUnitTopics do
  @moduledoc """
  Holds all dig unit specific topics
  """
  alias FleetControl.Helper
  alias FleetControl.LoadStyleAgent
  alias FleetControl.DigUnitActivityAgent
  alias FleetControl.HaulTruckDispatchAgent
  alias FleetControlWeb.Broadcast
  alias FleetControlWeb.DispatcherChannel.Topics

  def get_asset_type_state(asset, _operator_id) do
    activity = DigUnitActivityAgent.get(%{asset_id: asset.id})

    %{
      load_styles: LoadStyleAgent.get(%{asset_type: asset.type}) || [],
      activity: activity,
      haul_truck_dispatches: HaulTruckDispatchAgent.current()
    }
  end

  def handle_in("dig:submit activities", activities, socket) when is_list(activities) do
    activities
    |> Enum.map(fn activity ->
      case DigUnitActivityAgent.add(activity) do
        {:ok, new_activity} -> new_activity.asset_id
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.each(&Broadcast.DigUnit.send_activity_to_asset(%{asset_id: &1}))

    Broadcast.DigUnit.send_activities_to_all()

    # used to update the activity of the dig unit
    {:reply, :ok, socket}
  end

  def handle_in("dig:set haul dispatch", payload, socket) do
    payload
    |> Map.put("timestamp", Helper.naive_timestamp())
    |> Topics.HaulTruck.set_dispatch(socket)
  end
end
