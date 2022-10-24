defmodule FleetControlWeb.DispatcherChannel do
  @moduledoc nil

  require Logger
  use Appsignal.Instrumentation.Decorators
  use FleetControlWeb.Authorization.Decorator

  use FleetControlWeb, :channel

  alias FleetControlWeb.DispatcherChannel
  alias DispatcherChannel.Topics
  alias DispatcherChannel.Report

  alias FleetControlWeb.Broadcast

  alias FleetControl.Helper
  alias FleetControl.AssetRadioAgent
  alias FleetControl.TimeAllocation
  alias FleetControl.CalendarAgent
  alias FleetControl.RoutingAgent

  alias FleetControlWeb.DispatcherChannel.Setup

  def join("dispatchers:all", _params, socket) do
    send(self(), :after_join)
    permissions = socket.assigns.permissions
    resp = Setup.join(permissions)
    {:ok, resp, socket}
  end

  def join(_topic, _params, _socket), do: {:error, %{reason: "unauthorized"}}

  def handle_info(:after_join, socket) do
    # sync server presence information (automatically updated while connected)
    Broadcast.send_presence_state()
    {:noreply, socket}
  end

  @decorate channel_action()
  def handle_in("refresh:" <> subtopic, payload, socket) do
    Topics.Refresh.handle_in(subtopic, payload, socket)
  end

  @decorate authorized(:can_dispatch)
  def handle_in("haul:" <> subtopic, payload, socket) do
    Topics.HaulTruck.handle_in(subtopic, payload, socket)
  end

  def handle_in("auth:" <> subtopic, payload, socket) do
    Topics.Auth.handle_in(subtopic, payload, socket)
  end

  def handle_in("dig:" <> subtopic, payload, socket) do
    Topics.DigUnit.handle_in(subtopic, payload, socket)
  end

  def handle_in("pre-start:" <> subtopic, payload, socket) do
    Topics.PreStart.handle_in(subtopic, payload, socket)
  end

  def handle_in("track:" <> subtopic, payload, socket) do
    Topics.Track.handle_in(subtopic, payload, socket)
  end

  @decorate authorized(:can_edit_time_codes)
  def handle_in("time-code:" <> subtopic, payload, socket) do
    Topics.TimeCode.handle_in(subtopic, payload, socket)
  end

  @decorate authorized(:can_edit_asset_roster)
  def handle_in("asset:" <> subtopic, payload, socket) do
    Topics.Asset.handle_in(subtopic, payload, socket)
  end

  def handle_in("device:" <> subtopic, payload, socket) do
    Topics.Device.handle_in(subtopic, payload, socket)
  end

  def handle_in("operator:" <> subtopic, payload, socket) do
    Topics.Operator.handle_in(subtopic, payload, socket)
  end

  def handle_in("operator-message:" <> subtopic, payload, socket) do
    Topics.OperatorMessage.handle_in(subtopic, payload, socket)
  end

  def handle_in("dispatcher-message:" <> subtopic, payload, socket) do
    Topics.DispatcherMessage.handle_in(subtopic, payload, socket)
  end

  def handle_in("time-allocation:" <> subtopic, payload, socket) do
    Topics.TimeAllocation.handle_in(subtopic, payload, socket)
  end

  def handle_in("set page visited", payload, socket) do
    case payload["page"] do
      nil ->
        nil

      page ->
        user_name = socket.assigns[:current_user][:user_name]
        Appsignal.increment_counter("page_count", 1, %{page: page, user_name: user_name})
    end

    {:noreply, socket}
  end

  def handle_in("set radio number", payload, socket) do
    %{"asset_id" => asset_id, "radio_number" => radio_number} = payload
    AssetRadioAgent.set(asset_id, radio_number)
    Broadcast.send_asset_radios()
    {:reply, :ok, socket}
  end

  @decorate authorized(:can_edit_routing)
  def handle_in("routing:update", payload, socket) do
    case RoutingAgent.update(
           payload["route_id"],
           payload["vertices"],
           payload["edges"],
           payload["restriction_groups"]
         ) do
      {:ok, _state} ->
        Broadcast.send_routing_data()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  def handle_in(
        "report:time allocation",
        %{"start_time" => start_time, "end_time" => end_time, "asset_ids" => asset_ids},
        socket
      ) do
    report_start = Helper.to_naive(start_time)
    report_end = Helper.to_naive(end_time)
    reports = Report.generate_report(report_start, report_end, asset_ids)

    IO.inspect("report:time allocation")
    Process.send_after(socket.transport_pid, :garbage_collect, 1_000)
    {:reply, {:ok, %{reports: reports}}, socket}
  end

  def handle_in("report:time allocation", calendar_id, socket) when is_integer(calendar_id) do
    case CalendarAgent.get(%{id: calendar_id}) do
      %{shift_start: start_time, shift_end: end_time} ->
        reports_pid = Task.async(fn -> Report.generate_report(start_time, end_time) end)
        reports = Task.await(reports_pid, 10_000)

        IO.inspect("report:time allocation - calendar")
        Process.send_after(socket.transport_pid, :garbage_collect, 1_000)
        {:reply, {:ok, %{reports: reports}}, socket}

      _ ->
        {:reply, to_error("shift does not exist"), socket}
    end
  end

  def add_default_time_allocation(asset_id, time_code_id) do
    %{
      asset_id: asset_id,
      time_code_id: time_code_id,
      start_time: NaiveDateTime.utc_now(),
      end_time: nil,
      created_by_dispatcher: true,
      deleted: false
    }
    |> TimeAllocation.Agent.add()
  end

  @doc """
  Converts multiple errors types into a format useable for a socket error response
  """
  def to_error({:error, reason}), do: to_error(reason)

  def to_error(%Ecto.Changeset{} = changeset), do: to_error(hd(changeset.errors))

  def to_error({key, {reason, _extra}}), do: to_error("#{key} - #{reason}")

  def to_error(reason), do: {:error, %{error: reason}}
end
