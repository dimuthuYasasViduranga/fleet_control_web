defmodule FleetControlWeb.DispatcherChannel.Topics.DigUnit do
  alias FleetControl.DigUnitActivityAgent

  use HpsPhx.Authorization.Decorator
  alias FleetControlWeb.Broadcast

  import FleetControlWeb.DispatcherChannel, only: [to_error: 1]

  @decorate authorized_channel("fleet_control_dispatch")
  def handle_in("set activity", activity, socket) do
    case DigUnitActivityAgent.add(activity) do
      {:ok, activity} ->
        identifier = %{asset_id: activity.asset_id}
        Broadcast.DigUnit.send_activity_to_asset(identifier)
        Broadcast.DigUnit.send_activities_to_all()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  @decorate authorized_channel("fleet_control_dispatch")
  def handle_in("edit", activities, socket) do
    DigUnitActivityAgent.update_all(activities)
    |> case do
      {:ok, _, _, _} ->
        activities
        |> Enum.map(& &1["asset_id"])
        |> Enum.uniq()
        |> Enum.each(&Broadcast.DigUnit.send_activity_to_asset(%{asset_id: &1}))

        Broadcast.DigUnit.send_activities_to_all()

        {:reply, :ok, socket}

      {{:error, reason}, _} ->
        {:reply, to_error(reason), socket}
    end
  end
end
