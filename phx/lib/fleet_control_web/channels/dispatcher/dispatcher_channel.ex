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
  alias FleetControl.OperatorTimeAllocation
  alias FleetControl.OperatorAgent
  alias FleetControl.OperatorMessageTypeAgent
  alias FleetControl.OperatorMessageAgent
  alias FleetControl.DispatcherMessageAgent
  alias FleetControl.DigUnitActivityAgent
  alias FleetControl.DeviceAuthServer
  alias FleetControl.DeviceAssignmentAgent
  alias FleetControl.AssetRadioAgent
  alias FleetControl.TimeAllocation
  alias FleetControl.CalendarAgent
  alias FleetControl.HaulAgent
  alias FleetControl.RoutingAgent

  alias FleetControlWeb.DispatcherChannel.Setup

  alias Phoenix.Socket

  @type topic :: String.t()

  defp get_dispatcher_id(socket), do: socket.assigns[:current_user][:id]

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

  def handle_in("add dispatcher message", payload, socket) do
    dispatcher_id = get_dispatcher_id(socket)

    payload
    |> Map.put("dispatcher_id", dispatcher_id)
    |> DispatcherMessageAgent.new()
    |> case do
      {:ok, _} ->
        Broadcast.send_dispatcher_messages_to(%{asset_id: payload["asset_id"]})
        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, to_error(reason), socket}
    end
  end

  def handle_in("add mass dispatcher message", payload, socket) do
    %{
      "asset_ids" => asset_ids,
      "message" => message,
      "timestamp" => timestamp
    } = payload

    dispatcher_id = get_dispatcher_id(socket)

    asset_ids
    |> DispatcherMessageAgent.new_mass_message(
      message,
      dispatcher_id,
      payload["answers"],
      timestamp
    )
    |> case do
      {:ok, _} ->
        Broadcast.send_dispatcher_messages_to(asset_ids)
        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, to_error(reason), socket}
    end
  end

  def handle_in("acknowledge operator message", nil, socket) do
    {:reply, to_error("No message id given"), socket}
  end

  def handle_in("acknowledge operator message", operator_msg_id, socket) do
    operator_msg_id
    |> OperatorMessageAgent.acknowledge(Helper.naive_timestamp())
    |> case do
      {:ok, %{asset_id: asset_id}} ->
        Broadcast.send_unread_operator_messages_to_operator(asset_id)

      _ ->
        nil
    end

    # broadcast messages to dispatchers
    Broadcast.send_operator_messages_to_dispatcher()
    Broadcast.send_activity(nil, "dispatcher", "operator message acknowledged")

    {:reply, :ok, socket}
  end

  @decorate authorized(:can_edit_messages)
  def handle_in("update operator message type", payload, socket) do
    case payload["override"] do
      true -> OperatorMessageTypeAgent.override(payload)
      _ -> OperatorMessageTypeAgent.update(payload)
    end
    |> case do
      {:ok, _, _} ->
        Broadcast.send_operator_message_types()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  @decorate authorized(:can_edit_messages)
  def handle_in(
        "set operator message type tree",
        %{"asset_type_id" => asset_type_id, "ids" => ids},
        socket
      )
      when is_list(ids) do
    case OperatorMessageTypeAgent.update_tree(asset_type_id, ids) do
      {:ok, _} ->
        Broadcast.send_operator_message_type_tree_to_dispatcher()
        Broadcast.send_operator_message_type_tree_to(asset_type_id)
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  @decorate authorized(:can_edit_operators)
  def handle_in("add operator", payload, socket) do
    %{
      "name" => name,
      "nickname" => nickname,
      "employee_id" => employee_id
    } = payload

    case OperatorAgent.add(employee_id, name, nickname) do
      {:ok, _operator} ->
        Broadcast.send_operators_to_all()
        {:reply, :ok, socket}

      {:error, :employee_id_taken} ->
        {:reply, to_error("Employee ID already taken"), socket}
    end
  end

  @decorate authorized(:can_edit_operators)
  def handle_in("update operator", payload, socket) do
    %{
      "id" => id,
      "name" => name,
      "nickname" => nickname
    } = payload

    case OperatorAgent.update(id, name, nickname) do
      {:ok, _operator} ->
        Broadcast.send_operators_to_all()
        {:reply, :ok, socket}

      {:error, :not_found} ->
        {:reply, to_error("No employee found"), socket}

      {:error, :invalid_name} ->
        {:reply, to_error("Invalid name"), socket}
    end
  end

  @decorate authorized(:can_edit_operators)
  def handle_in("bulk add operators", %{"operators" => operators}, socket) do
    operators =
      Enum.map(operators, fn o ->
        %{
          name: o["name"],
          nickname: o["nickname"],
          employee_id: o["employee_id"]
        }
      end)

    case OperatorAgent.bulk_add(operators) do
      {:ok, _operators} ->
        Broadcast.send_operators_to_all()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  @decorate authorized(:can_edit_operators)
  def handle_in("set operator enabled", %{"id" => operator_id, "enabled" => enabled}, socket) do
    case enabled do
      true ->
        OperatorAgent.restore(operator_id)

      false ->
        Broadcast.force_logout(%{operator_id: operator_id})
        OperatorAgent.delete(operator_id)
    end
    |> case do
      {:ok, _operator} ->
        Broadcast.send_operators_to_all()
        {:reply, :ok, socket}

      {:error, :invalid_id} ->
        {:reply, to_error("No employee found"), socket}
    end
  end

  def handle_in("set allocation", %{"asset_id" => asset_id} = allocation, socket) do
    allocation = Map.put(allocation, :created_by_dispatcher, true)

    case TimeAllocation.Agent.add(allocation) do
      {:ok, _} ->
        Broadcast.send_active_allocation_to(%{asset_id: asset_id})
        Broadcast.send_allocations_to_dispatcher()

        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  def handle_in(
        "mass set allocations",
        %{"time_code_id" => time_code_id, "asset_ids" => asset_ids},
        socket
      ) do
    asset_ids = Enum.uniq(asset_ids)

    case TimeAllocation.Agent.mass_add(time_code_id, asset_ids, created_by_dispatcher: true) do
      {:ok, _, _, _} ->
        Enum.each(asset_ids, &Broadcast.send_active_allocation_to(%{asset_id: &1}))
        Broadcast.send_allocations_to_dispatcher(:no_alert)

        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  @decorate authorized(:can_edit_time_allocations)
  def handle_in("edit time allocations", allocations, socket) do
    allocations = Enum.map(allocations, &Map.put(&1, :updated_by_dispatcher, true))

    TimeAllocation.Agent.update_all(allocations)
    |> case do
      {:error, reason} ->
        {:reply, to_error(reason), socket}

      {:ok, _, _, _} ->
        allocations
        |> Enum.map(& &1["asset_id"])
        |> Enum.uniq()
        |> Enum.each(&Broadcast.send_active_allocation_to(%{asset_id: &1}))

        Broadcast.send_allocations_to_dispatcher()

        {:reply, :ok, socket}
    end
  end

  @decorate authorized(:can_lock_time_allocations)
  def handle_in("lock time allocations", %{"ids" => ids, "calendar_id" => cal_id}, socket) do
    dispatcher_id = get_dispatcher_id(socket)

    case TimeAllocation.Agent.lock(ids, cal_id, dispatcher_id) do
      {:ok, %{new: []}} ->
        {:reply, :ok, socket}

      {:ok, %{new: new_elements}} ->
        # only send to assets if there is a new active for them
        new_elements
        |> Enum.filter(&is_nil(&1.end_time))
        |> Enum.map(& &1.asset_id)
        |> Enum.uniq()
        |> Enum.each(&Broadcast.send_active_allocation_to(%{asset_id: &1}))

        Broadcast.send_allocations_to_dispatcher()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  @decorate authorized(:can_lock_time_allocations)
  def handle_in("unlock time allocations", ids, socket) when is_list(ids) do
    case TimeAllocation.Agent.unlock(ids) do
      {:ok, %{new: []}} ->
        {:reply, :ok, socket}

      {:ok, _} ->
        Broadcast.send_allocations_to_dispatcher()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  def handle_in("get time allocation data", calendar_id, socket) do
    case CalendarAgent.get(%{id: calendar_id}) do
      nil ->
        {:reply, to_error("shift does not exist"), socket}

      shift ->
        range = %{start_time: shift.shift_start, end_time: shift.shift_end}
        allocations = FleetControl.TimeAllocation.EctoQueries.fetch_by_range!(range)

        device_assignments = DeviceAssignmentAgent.fetch_by_range!(range)

        timeusage = HaulAgent.fetch_timeusage_by_range!(%{calendar_id: calendar_id})
        cycles = HaulAgent.fetch_cycles_by_range!(%{calendar_id: calendar_id})

        payload = %{
          shift: shift,
          allocations: allocations,
          device_assignments: device_assignments,
          timeusage: timeusage,
          cycles: cycles
        }

        {:reply, {:ok, payload}, socket}
    end
  end

  def handle_in("get operator time allocation data", calendar_id, socket) do
    case CalendarAgent.get(%{id: calendar_id}) do
      nil ->
        {:reply, to_error("shift does not exists"), socket}

      shift ->
        now = NaiveDateTime.utc_now()

        end_time =
          case NaiveDateTime.compare(shift.shift_end, now) == :gt do
            true -> now
            _ -> shift.shift_end
          end

        report =
          OperatorTimeAllocation.fetch_data(shift.shift_start, end_time)
          |> OperatorTimeAllocation.build_report()
          |> Map.put(:end_time, shift.shift_end)

        payload = %{
          shift: shift,
          data: report
        }

        {:reply, {:ok, payload}, socket}
    end
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

    {:reply, {:ok, %{reports: reports}}, socket}
  end

  def handle_in("report:time allocation", calendar_id, socket) when is_integer(calendar_id) do
    case CalendarAgent.get(%{id: calendar_id}) do
      %{shift_start: start_time, shift_end: end_time} ->
        reports = Report.generate_report(start_time, end_time)
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
  @spec to_error(any) :: {:error, %{error: any}}
  def to_error({:error, reason}), do: to_error(reason)

  def to_error(%Ecto.Changeset{} = changeset), do: to_error(hd(changeset.errors))

  def to_error({key, {reason, _extra}}), do: to_error("#{key} - #{reason}")

  def to_error(reason), do: {:error, %{error: reason}}
end
