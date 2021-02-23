defmodule DispatchWeb.DispatcherChannel do
  @moduledoc nil

  require Logger
  use Appsignal.Instrumentation.Decorators
  use DispatchWeb.Authorization.Decorator

  use DispatchWeb, :channel

  alias __MODULE__.{
    RefreshTopics,
    HaulTruckTopics,
    AuthTopics,
    Report,
    DigUnitTopics,
    PreStartTopics
  }

  alias DispatchWeb.Broadcast
  alias Dispatch.Tracks

  alias Dispatch.{
    Helper,
    AssetAgent,
    ActivityAgent,
    DeviceAgent,
    DispatcherAgent,
    OperatorAgent,
    OperatorMessageTypeAgent,
    OperatorMessageAgent,
    DispatcherMessageAgent,
    HaulTruckDispatchAgent,
    DigUnitActivityAgent,
    DeviceAuthServer,
    DeviceAssignmentAgent,
    EngineHoursAgent,
    AssetRadioAgent,
    TimeCodeAgent,
    TimeAllocationAgent,
    CalendarAgent,
    FleetOpsAgent,
    TrackAgent,
    ManualCycleAgent,
    PreStartAgent,
    PreStartSubmissionAgent
  }

  alias Phoenix.Socket

  @type topic :: String.t()

  defp get_dispatcher_id(socket), do: socket.assigns[:current_user][:id]

  @spec join(topic, any(), Socket.t()) ::
          {:error, %{reason: String.t()}} | {:ok, map(), Socket.t()}
  def join("dispatchers:all", _params, socket) do
    send(self(), :after_join)

    {devices, accept_until} = DeviceAuthServer.get()

    pending_devices = %{
      devices: devices,
      accept_until: accept_until
    }

    resp = %{
      # constants
      time_code_tree_elements: TimeCodeAgent.get_time_code_tree_elements(),
      operator_message_type_tree: OperatorMessageTypeAgent.tree_elements(),
      operators: OperatorAgent.all(),
      dispatchers: DispatcherAgent.all(),

      # devices
      devices: DeviceAgent.safe_all(),
      device_assignments: %{
        current: DeviceAssignmentAgent.current(),
        historic: DeviceAssignmentAgent.historic()
      },
      pending_devices: pending_devices,

      # common
      activities: ActivityAgent.get(),
      operator_messages: OperatorMessageAgent.all(),
      dispatcher_messages: DispatcherMessageAgent.all(),
      engine_hours: %{
        current: EngineHoursAgent.current(),
        historic: EngineHoursAgent.historic()
      },
      radio_numbers: AssetRadioAgent.all(),
      time_allocations: %{
        active: TimeAllocationAgent.active(),
        historic: TimeAllocationAgent.historic()
      },
      fleetops_data: FleetOpsAgent.get(),
      pre_starts: PreStartAgent.all(),
      pre_start_submissions: PreStartSubmissionAgent.all(),
      tracks: TrackAgent.all(),

      # haul truck
      haul_truck: %{
        dispatches: %{
          current: HaulTruckDispatchAgent.current(),
          historic: HaulTruckDispatchAgent.historic()
        },
        manual_cycles: ManualCycleAgent.get() |> Enum.reject(&(&1.deleted == true))
      },

      # dig unit
      dig_unit: %{
        activities: %{
          current: DigUnitActivityAgent.current(),
          historic: DigUnitActivityAgent.historic()
        }
      }
    }

    {:ok, resp, socket}
  end

  def join(_topic, _params, _socket), do: {:error, %{reason: "unauthorized"}}

  @spec handle_info(:after_join, Socket.t()) :: {:noreply, Socket.t()}
  def handle_info(:after_join, socket) do
    # sync server presence information (automatically updated while connected)
    Broadcast.send_presence_state()
    {:noreply, socket}
  end

  @spec handle_in(String.t(), map(), Socket.t()) ::
          {:noreply, Socket.t()}
          | {:reply, :ok | :error | {:error, term}, Socket.t()}
  @decorate channel_action()
  def handle_in("refresh:" <> _ = topic, payload, socket) do
    RefreshTopics.handle_in(topic, payload, socket)
  end

  def handle_in("haul:" <> _ = topic, payload, socket) do
    HaulTruckTopics.handle_in(topic, payload, socket)
  end

  def handle_in("auth:" <> _ = topic, payload, socket) do
    AuthTopics.handle_in(topic, payload, socket)
  end

  def handle_in("dig:" <> _ = topic, payload, socket) do
    DigUnitTopics.handle_in(topic, payload, socket)
  end

  def handle_in("pre-start:" <> _ = topic, payload, socket) do
    PreStartTopics.handle_in(topic, payload, socket)
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

  def handle_in("set assigned asset", payload, socket) do
    %{"device_id" => device_id, "asset_id" => asset_id} = payload

    case set_assigned_asset(device_id, asset_id) do
      :ok -> {:reply, :ok, socket}
      error -> {:reply, to_error(error), socket}
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

  @decorate authorized(:can_edit_time_codes)
  def handle_in("set time code tree elements", payload, socket) do
    %{
      "asset_type_id" => asset_type_id,
      "elements" => elements
    } = payload

    case TimeCodeAgent.set_time_code_tree_elements(asset_type_id, elements) do
      {:error, reason} ->
        {:reply, to_error(reason), socket}

      {:ok, _inserted} ->
        Broadcast.send_time_code_tree_elements_to(%{id: asset_type_id})
        {:reply, :ok, socket}
    end
  end

  @decorate authorized(:can_edit_time_codes)
  def handle_in("update time code", payload, socket) do
    case TimeCodeAgent.add_or_update_time_code(payload) do
      {:ok, _} ->
        Broadcast.send_time_code_data_to_all()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  @decorate authorized(:can_edit_time_codes)
  def handle_in("update time code group", %{"id" => id, "alias" => alias_name}, socket) do
    case TimeCodeAgent.update_group(id, alias_name) do
      {:ok, _} ->
        Broadcast.send_time_code_data_to_all()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
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

  def handle_in("set allocation", %{"asset_id" => asset_id} = allocation, socket) do
    case TimeAllocationAgent.add(allocation) do
      {:ok, _} ->
        Broadcast.send_active_allocation_to(%{asset_id: asset_id})
        Broadcast.send_allocations_to_dispatcher()

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

  def handle_in("edit time allocations", allocations, socket) do
    TimeAllocationAgent.update_all(allocations)
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

  def handle_in("lock time allocations", %{"ids" => ids, "calendar_id" => cal_id}, socket) do
    dispatcher_id = get_dispatcher_id(socket)

    TimeAllocationAgent.lock(ids, cal_id, dispatcher_id)
    |> case do
      {:ok, [], _, _, _} ->
        {:reply, :ok, socket}

      {:ok, [alloc | _], _, _, _} ->
        Broadcast.send_active_allocation_to(%{asset_id: alloc.asset_id})
        Broadcast.send_allocations_to_dispatcher()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  def handle_in("unlock time allocations", ids, socket) when is_list(ids) do
    case TimeAllocationAgent.unlock(ids) do
      {:ok, [], _} ->
        {:reply, :ok, socket}

      {:ok, [alloc | _], _} ->
        Broadcast.send_active_allocation_to(%{asset_id: alloc.asset_id})
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
        allocations = Dispatch.TimeAllocationAgent.Data.fetch_by_range!(range)

        device_assignments = DeviceAssignmentAgent.fetch_by_range!(range)

        timeusage = FleetOpsAgent.fetch_timeusage_by_range!(%{calendar_id: calendar_id})
        cycles = FleetOpsAgent.fetch_cycles_by_range!(%{calendar_id: calendar_id})

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

  def handle_in("force logout device", %{"device_id" => device_id} = payload, socket) do
    time_code_id = payload["time_code_id"]

    case DeviceAssignmentAgent.get(%{device_id: device_id}) do
      %{asset_id: asset_id} ->
        case TimeAllocationAgent.add(%{
               asset_id: asset_id,
               time_code_id: time_code_id,
               start_time: NaiveDateTime.utc_now(),
               end_time: nil,
               deleted: false
             }) do
          {:ok, _} ->
            Broadcast.send_active_allocation_to(%{asset_id: asset_id})
            Broadcast.send_allocations_to_dispatcher()

          _ ->
            nil
        end

      _ ->
        nil
    end

    Broadcast.force_logout(%{device_id: device_id}, %{clear_operator: true})

    {:reply, :ok, socket}
  end

  def handle_in("set device details", %{"device_id" => device_id, "details" => details}, socket) do
    case DeviceAgent.update_details(device_id, details) do
      {:ok, _} ->
        Broadcast.send_devices_to_dispatcher()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  @decorate only_in(:dev)
  def handle_in("track:set mode", mode, socket) when mode in ["mock", "normal"] do
    TrackAgent.set_mode(String.to_existing_atom(mode))
    {:reply, :ok, socket}
  end

  def handle_in("track:set mode", mode, socket) do
    Logger.error("Track agent cannot be set to mode '#{mode}'")
    {:reply, to_error("invalid mode"), socket}
  end

  @decorate only_in(:dev)
  def handle_in("track:set track", track, socket) do
    track
    |> parse_mock_track()
    |> Tracks.add_info()
    |> TrackAgent.add(:mock)
    |> case do
      {:ok, new_track} -> Broadcast.send_track(new_track)
      _ -> Logger.info("Mock track ignored")
    end

    {:noreply, socket}
  end

  @spec set_assigned_asset(integer, integer) ::
          :ok | {:error, :invalid_device_id | :invalid_asset_id | term}
  def set_assigned_asset(device_id, new_asset_id) do
    case valid_device_and_asset(device_id, new_asset_id) do
      :ok ->
        nil

        # logout given device. Re-join if not removed from an asset
        Broadcast.force_logout(%{device_id: device_id}, %{rejoin: new_asset_id != nil})

        # remove existing asset assignment
        remove_device_from_asset(device_id)

        # set new assignment
        set_device_to_asset(device_id, new_asset_id)

        :ok

      error ->
        error
    end
  end

  defp valid_device_and_asset(device_id, asset_id) do
    device = DeviceAgent.get(%{id: device_id})
    asset = AssetAgent.get_asset(%{id: asset_id})

    cond do
      device == nil -> {:error, :invalid_device_id}
      asset_id != nil && asset == nil -> {:error, :invalid_asset_id}
      true -> :ok
    end
  end

  defp remove_device_from_asset(device_id) do
    case DeviceAssignmentAgent.get_asset_id(%{device_id: device_id}) do
      nil ->
        nil

      old_asset_id ->
        Logger.info(
          "[DeviceAssignment] device '#{device_id}' unassigned from asset '#{old_asset_id}'"
        )

        # clear any settings for the asset
        HaulTruckDispatchAgent.clear(old_asset_id)

        DeviceAssignmentAgent.clear(old_asset_id)

        Broadcast.send_activity(%{asset_id: old_asset_id}, "dispatcher", "device unassigned")
        Broadcast.HaulTruck.send_dispatches()
        Broadcast.send_assignments_to_all()
    end
  end

  defp set_device_to_asset(_device_id, nil), do: nil

  defp set_device_to_asset(device_id, asset_id) do
    Logger.info("[DeviceAssignment] device '#{device_id}' assigned to asset '#{asset_id}'")

    DeviceAssignmentAgent.change(asset_id, %{
      device_id: device_id,
      operator_id: nil
    })

    Broadcast.send_activity(%{asset_id: asset_id}, "dispatcher", "device assigned")
    Broadcast.send_assignments_to_all()
  end

  defp to_error({:error, reason}), do: to_error(reason)

  defp to_error(%Ecto.Changeset{} = changeset), do: to_error(hd(changeset.errors))

  defp to_error({key, {reason, _extra}}), do: to_error("#{key} - #{reason}")

  defp to_error(reason), do: {:error, %{error: reason}}

  defp parse_mock_track(track) do
    pos = track["position"]

    %{
      name: track["name"],
      user_id: track["user_id"],
      position: %{
        lat: pos["lat"],
        lng: pos["lng"],
        alt: pos["alt"]
      },
      speed_ms: track["speed_ms"],
      heading: track["heading"],
      ignition: true,
      valid: Map.get(track, "valid", true),
      timestamp: track["timestamp"]
    }
  end
end