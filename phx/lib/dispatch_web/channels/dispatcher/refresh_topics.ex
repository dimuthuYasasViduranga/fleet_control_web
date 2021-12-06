defmodule DispatchWeb.DispatcherChannel.RefreshTopics do
  @moduledoc """
  Holds all topics relating to agent refreshing
  """
  require Logger
  use DispatchWeb.Authorization.Decorator

  alias DispatchWeb.Broadcast

  @decorate authorized(:can_refresh_agents)
  def handle_in("refresh:" <> subtopic, _, socket) do
    Logger.warn("Refreshing: #{subtopic}")

    case DispatchWeb.DispatcherChannel.RefreshTopics.refresh(subtopic) do
      :ok -> {:reply, :ok, socket}
      {:error, reason} -> {:reply, {:error, %{error: reason}}, socket}
    end
  end

  @spec refresh(String.t()) :: :ok
  def refresh("asset agent") do
    :ok = Dispatch.AssetAgent.refresh!()
    Broadcast.send_asset_data_to_all()
    :ok
  end

  def refresh("location agent") do
    :ok = Dispatch.LocationAgent.refresh!()
    Broadcast.send_location_data_to_all()
    :ok
  end

  def refresh("calendar agent") do
    :ok = Dispatch.CalendarAgent.refresh!()
    Broadcast.send_calendar_data_to_all()
    :ok
  end

  def refresh("device agent") do
    :ok = Dispatch.DeviceAgent.refresh!()
    Broadcast.send_devices_to_dispatcher()
    :ok
  end

  def refresh("operator agent") do
    :ok = Dispatch.OperatorAgent.refresh!()
    Broadcast.send_operators_to_all()
    :ok
  end

  def refresh("operator message agent") do
    :ok = Dispatch.OperatorMessageAgent.refresh!()

    Dispatch.AssetAgent.get_assets()
    |> Enum.each(&Broadcast.send_unread_operator_messages_to_operator(&1.id))

    Broadcast.send_operator_messages_to_dispatcher()
    :ok
  end

  def refresh("time code agent") do
    :ok = Dispatch.TimeCodeAgent.refresh!()
    Broadcast.send_time_code_data_to_all()
    :ok
  end

  def refresh("fleetops agent") do
    :ok = Dispatch.HaulAgent.refresh!()
    Broadcast.send_fleetops_data_to_all()
    :ok
  end

  def refresh("pre-start agent") do
    :ok = Dispatch.PreStartAgent.refresh!()
    Broadcast.send_pre_start_forms_to_all()
    Broadcast.send_pre_start_control_categories_to_all()
    :ok
  end

  def refresh("pre-start submission agent") do
    :ok = Dispatch.PreStartSubmissionAgent.refresh!()
    Broadcast.send_pre_start_submissions_to_all()
    :ok
  end

  def refresh(_), do: {:error, :invalid_refresh}
end
