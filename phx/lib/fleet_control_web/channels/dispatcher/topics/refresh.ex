defmodule FleetControlWeb.DispatcherChannel.Topics.Refresh do
  @moduledoc """
  Holds all topics relating to agent refreshing
  """
  require Logger
  use HpsPhx.Authorization.Decorator

  alias FleetControlWeb.Broadcast

  @decorate authorized_channel("fleet_control_refresh_agents")
  def handle_in(subtopic, _, socket) do
    Logger.warn("Refreshing: #{subtopic}")

    case refresh(subtopic) do
      :ok -> {:reply, :ok, socket}
      {:error, reason} -> {:reply, {:error, %{error: reason}}, socket}
    end
  end

  @spec refresh(String.t()) :: :ok
  def refresh("asset agent") do
    :ok = FleetControl.AssetAgent.refresh!()
    Broadcast.send_asset_data_to_all()
    :ok
  end

  def refresh("location agent") do
    :ok = FleetControl.LocationAgent.refresh!()
    Broadcast.send_location_data_to_all()
    :ok
  end

  def refresh("calendar agent") do
    :ok = FleetControl.CalendarAgent.refresh!()
    Broadcast.send_calendar_data_to_all()
    :ok
  end

  def refresh("device agent") do
    :ok = FleetControl.DeviceAgent.refresh!()
    Broadcast.send_devices_to_dispatcher()
    :ok
  end

  def refresh("operator agent") do
    :ok = FleetControl.OperatorAgent.refresh!()
    Broadcast.send_operators_to_all()
    :ok
  end

  def refresh("operator message agent") do
    :ok = FleetControl.OperatorMessageAgent.refresh!()

    FleetControl.AssetAgent.get_assets()
    |> Enum.each(&Broadcast.send_unread_operator_messages_to_operator(&1.id))

    Broadcast.send_operator_messages_to_dispatcher()
    :ok
  end

  def refresh("time code agent") do
    :ok = FleetControl.TimeCodeAgent.refresh!()
    Broadcast.send_time_code_data_to_all()
    :ok
  end

  def refresh("pre-start agent") do
    :ok = FleetControl.PreStartAgent.refresh!()
    Broadcast.send_pre_start_forms_to_all()
    Broadcast.send_pre_start_control_categories_to_all()
    :ok
  end

  def refresh("pre-start submission agent") do
    :ok = FleetControl.PreStartSubmissionAgent.refresh!()
    Broadcast.send_pre_start_submissions_to_all()
    :ok
  end

  def refresh(_), do: {:error, :invalid_refresh}
end
