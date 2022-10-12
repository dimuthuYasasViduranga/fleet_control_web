defmodule FleetControlWeb.DispatcherChannel.Topics.DigUnit do
  alias FleetControl.DigUnitActivityAgent

  use FleetControlWeb.Authorization.Decorator
  alias FleetControlWeb.Broadcast

  import FleetControlWeb.DispatcherChannel, only: [to_error: 1]

  @decorate authorized(:can_dispatch)
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
end
