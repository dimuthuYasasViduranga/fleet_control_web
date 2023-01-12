defmodule FleetControlWeb.Broadcast do
  @moduledoc """
  The centralised module for broadcasting actions to multiple action types.

  The main purpose is to reduce the duplicated code shared between operators and dispatcher channels
  ie. Both can update device, and there were two equal implementations of broadcasting the updated device

  If the target of a message cannot be found (no device for the given asset_id, etc), there is no need to resent
  as all relevant data is then downloaded once the socket is reconnected
  """

  @operators "operators"
  @dispatch "dispatchers:all"

  require Logger
  alias FleetControlWeb.{Settings, Presence, Endpoint}

  alias FleetControl.{
    Helper,
    DispatcherAgent,
    OperatorAgent,
    AssetAgent,
    OperatorMessageAgent,
    OperatorMessageTypeAgent,
    DispatcherMessageAgent,
    DeviceAgent,
    ActivityAgent,
    DeviceAssignmentAgent,
    EngineHoursAgent,
    AssetRadioAgent,
    TimeCodeAgent,
    TimeAllocation,
    LocationAgent,
    CalendarAgent,
    PreStartAgent,
    PreStartSubmissionAgent,
    RoutingAgent
  }

  @spec get_assignment(map) :: {map, map, map} | {map} | nil
  def get_assignment(%{uuid: uuid}) do
    case DeviceAgent.get(%{uuid: uuid}) do
      nil ->
        nil

      device ->
        case DeviceAssignmentAgent.get(%{device_id: device.id}) do
          nil ->
            {device}

          %{asset_id: nil} ->
            {device}

          assignment ->
            type = Map.get(AssetAgent.get_asset(%{id: assignment.asset_id}), :type)
            {device, assignment, type}
        end
    end
  end

  def get_assignment(%{device_id: device_id}) do
    case DeviceAgent.get(%{id: device_id}) do
      nil ->
        nil

      device ->
        case DeviceAssignmentAgent.get(%{device_id: device_id}) do
          nil ->
            {device}

          %{asset_id: nil} ->
            {device}

          assignment ->
            type = Map.get(AssetAgent.get_asset(%{id: assignment.asset_id}), :type)
            {device, assignment, type}
        end
    end
  end

  def get_assignment(identifier) do
    with %{device_id: device_id} = assignment <- DeviceAssignmentAgent.get(identifier),
         %{uuid: _uuid} = device <- DeviceAgent.get(%{id: device_id}) do
      case assignment[:asset_id] do
        nil ->
          nil

        _ ->
          type = Map.get(AssetAgent.get_asset(%{id: assignment.asset_id}), :type)
          {device, assignment, type}
      end
    end
  end

  defp do_broadcast(recipient, event, payload) do
    Appsignal.increment_counter("broadcast", 1, %{recipient: recipient, event: event})
    Appsignal.increment_counter("broadcast_payload_size", :erlang.external_size(payload), %{event: event})

    Endpoint.broadcast(recipient, event, payload)
  end

  @doc """
  Used to broadcast to all assignments that have a device. There is no guarentee that the message is received.

  If payload is a function, it can allow for conditional broadcast per asset
  """
  @spec broadcast_all_operators(String.t(), map | fun, fun | nil) :: :ok
  def broadcast_all_operators(topic, payload_or_func, asset_filter \\ nil) do
    assets =
      case asset_filter do
        nil -> AssetAgent.get_assets()
        predicate -> AssetAgent.get_assets() |> Enum.filter(&predicate.(&1))
      end

    Enum.map(assets, fn asset ->
      case get_assignment(%{asset_id: asset.id}) do
        {device, assignment, _type} ->
          case is_function(payload_or_func) do
            true -> payload_or_func.(device, assignment)
            _ -> payload_or_func
          end
          |> case do
            nil -> nil
            payload -> do_broadcast("#{@operators}:#{device.uuid}", topic, payload)
          end

        nil ->
          nil
      end
    end)
  end

  def broadcast_to_asset_type(type_identifier, topic, payload) do
    type_identifier
    |> AssetAgent.get_assets()
    |> Enum.map(fn asset ->
      case get_assignment(%{asset_id: asset.id}) do
        {device, _assignment, _type} ->
          do_broadcast("#{@operators}:#{device.uuid}", topic, payload)

        _ ->
          nil
      end
    end)
  end

  @spec force_logout(map, keyword()) :: :ok
  def force_logout(identifier, opts \\ %{}) do
    case get_assignment(identifier) do
      {device, assignment, _type} ->
        Logger.info("[ForceLogout] device `#{device.id}`(#{device.uuid})")
        do_broadcast("#{@operators}:#{device.uuid}", "force logout", opts)

        if Map.get(opts, :clear_operator, false) and assignment.asset_id do
          Logger.info("[ForceLogout] clearing operator for device `#{device.id}`(#{device.uuid})")
          change = %{operator_id: nil, timestamp: Helper.naive_timestamp()}
          DeviceAssignmentAgent.change(assignment.asset_id, change)
        end

        send_assignments_to_all()
        send_activity(%{device_id: device.id}, "operator", "operator logout")

      {device} ->
        Logger.info("[ForceLogout] device `#{device.id}`(#{device.uuid})")
        do_broadcast("#{@operators}:#{device.uuid}", "force logout", opts)

        send_assignments_to_all()
        send_activity(%{device_id: device.id}, "operator", "operator logout")

      _ ->
        nil
    end

    :ok
  end

  def send_location_data_to_all() do
    active_locations =
      LocationAgent.active_locations()
      |> Enum.map(&Map.drop(&1, [:polygon]))

    payload = %{
      dim_locations: LocationAgent.dim_locations(),
      locations: active_locations
    }

    do_broadcast(@dispatch, "set location data", payload)
    broadcast_all_operators("set location data", payload)
  end

  def send_routing_data() do
    payload = %{
      routing: RoutingAgent.get()
    }

    do_broadcast(@dispatch, "set routing data", payload)
    broadcast_all_operators("set routing data", payload)
  end

  def send_asset_data_to_all() do
    payload = %{
      assets: AssetAgent.get_assets(),
      asset_types: AssetAgent.get_types()
    }

    do_broadcast(@dispatch, "set asset data", payload)
  end

  def send_calendar_data_to_all() do
    payload = %{
      shifts: CalendarAgent.shifts(),
      shift_types: CalendarAgent.shift_types()
    }

    do_broadcast(@dispatch, "set calendar data", payload)
  end

  def send_time_code_data_to_all() do
    payload = TimeCodeAgent.get()
    do_broadcast(@dispatch, "set time code data", payload)
    broadcast_all_operators("set time code data", payload)
  end

  def send_operator_message_types() do
    payload = %{
      message_types: OperatorMessageTypeAgent.types(),
      message_type_tree: OperatorMessageTypeAgent.tree_elements()
    }

    do_broadcast(@dispatch, "set operator message types", payload)
    broadcast_all_operators("set operator message types", payload)
  end

  def send_operator_message_type_tree_to_dispatcher() do
    payload = %{
      message_type_tree: OperatorMessageTypeAgent.tree_elements()
    }

    do_broadcast(@dispatch, "operator-message:set-type-tree", payload)
  end

  def send_operator_message_type_tree_to(asset_type_id) do
    payload = %{
      message_type_tree: OperatorMessageTypeAgent.tree_elements()
    }

    broadcast_to_asset_type(%{type_id: asset_type_id}, "operator-message:set-type-tree", payload)
  end

  def send_dispatchers() do
    dispatchers = DispatcherAgent.all()
    do_broadcast(@dispatch, "set dispatchers", %{dispatchers: dispatchers})
  end

  def send_operators_to_all() do
    payload = %{
      operators: OperatorAgent.all()
    }

    do_broadcast(@dispatch, "set operators", payload)
    broadcast_all_operators("set operators", payload)
  end

  def send_operator_messages_to_dispatcher() do
    messages = OperatorMessageAgent.all()
    do_broadcast(@dispatch, "set operator messages", %{messages: messages})
  end

  def send_unread_operator_messages_to_operator(asset_id) do
    case get_assignment(%{asset_id: asset_id}) do
      {device, _assignment, _type} ->
        unread = OperatorMessageAgent.unread(asset_id)

        do_broadcast("#{@operators}:#{device.uuid}", "set unread messages", %{
          messages: unread
        })

      _ ->
        nil
    end
  end

  def send_dispatcher_messages_to(asset_ids) when is_list(asset_ids) do
    send_dispatcher_messages_to_dispatcher()
    Enum.map(asset_ids, &send_dispatcher_message_to_operator(%{asset_id: &1}))
  end

  def send_dispatcher_messages_to(identifier) do
    send_dispatcher_messages_to_dispatcher()
    send_dispatcher_message_to_operator(identifier)
  end

  defp send_dispatcher_messages_to_dispatcher() do
    messages = DispatcherMessageAgent.all()
    do_broadcast(@dispatch, "set dispatcher messages", %{messages: messages})
  end

  defp send_dispatcher_message_to_operator(identifier) do
    case get_assignment(identifier) do
      {device, assignment, _type} ->
        messages = DispatcherMessageAgent.all(assignment.asset_id)

        do_broadcast("#{@operators}:#{device.uuid}", "set dispatcher messages", %{
          messages: messages
        })

      _ ->
        nil
    end
  end

  def send_devices_to_dispatcher() do
    devices = DeviceAgent.safe_all()
    do_broadcast(@dispatch, "set devices", %{devices: devices})
  end

  def send_assignments_to_all() do
    payload = %{
      historic: DeviceAssignmentAgent.historic(),
      current: DeviceAssignmentAgent.current()
    }

    do_broadcast(@dispatch, "set device assignments", payload)
    broadcast_all_operators("set device assignments", %{assignments: payload.current})
  end

  def send_engine_hours_to_dispatcher() do
    payload = %{
      current: EngineHoursAgent.current(),
      historic: EngineHoursAgent.historic()
    }

    do_broadcast(@dispatch, "set engine hours", payload)
  end

  def send_engine_hours_to(identifier) do
    case get_assignment(identifier) do
      {device, assignment, _type} ->
        engine_hours =
          Enum.find(EngineHoursAgent.current(), &(&1.asset_id == assignment.asset_id))

        do_broadcast("#{@operators}:#{device.uuid}", "set engine hours", %{
          engine_hours: engine_hours
        })

      _ ->
        nil
    end
  end

  def send_active_allocation_to(identifier) do
    case get_assignment(identifier) do
      {device, assignment, _type} ->
        allocation = TimeAllocation.Agent.get_active(%{asset_id: assignment.asset_id})

        do_broadcast("#{@operators}:#{device.uuid}", "set allocation", %{
          allocation: allocation
        })

      _ ->
        nil
    end
  end

  def send_allocations_to_dispatcher(action \\ :alert) do
    payload = %{
      historic: TimeAllocation.Agent.historic(),
      active: TimeAllocation.Agent.active(),
      action: action
    }

    do_broadcast(@dispatch, "set time allocations", payload)
  end

  def send_pre_start_forms_to_all() do
    payload = %{
      pre_start_forms: PreStartAgent.all()
    }

    do_broadcast(@dispatch, "set pre-start forms", payload)

    broadcast_all_operators("set pre-start forms", payload)
  end

  def send_pre_start_control_categories_to_all() do
    payload = %{
      categories: PreStartAgent.categories()
    }

    do_broadcast(@dispatch, "set pre-start categories", payload)
    broadcast_all_operators("set pre-start categories", payload)
  end

  def send_pre_start_submissions_to_all() do
    current = PreStartSubmissionAgent.current()
    historic = PreStartSubmissionAgent.historic()

    do_broadcast(@dispatch, "set pre-start submissions", %{current: current})

    broadcast_all_operators("set pre-start submissions", fn _device, %{asset_id: asset_id} ->
      asset_current = Enum.find(current, &(&1.asset_id == asset_id))
      asset_historic = Enum.filter(historic, &(&1.asset_id == asset_id))

      %{
        current: asset_current,
        historic: asset_historic
      }
    end)

    rpc("maintenance-ui", MaintenanceWeb.Broadcast, :send_latest_pre_start_submissions, [current])
  end

  defp rpc(node_name, module, function, args) do
    Node.list()
    |> Enum.filter(&String.starts_with?(Atom.to_string(&1), node_name))
    |> case do
      [node | _] ->
        :rpc.call(node, module, function, args)

      [] ->
        {:error, "unable to access #{node_name}"}
    end
  end

  def send_activity(identifier, source, activity_type) do
    send_activity(identifier, source, activity_type, Helper.timestamp())
  end

  def send_track(nil), do: nil

  def send_track(track) do
    payload = %{track: track}

    # send to target in question
    case get_assignment(%{asset_id: track.asset_id}) do
      {device, _assignment, _type} ->
        do_broadcast("#{@operators}:#{device.uuid}", "set track", payload)

      _ ->
        nil
    end

    # send to dispatcher
    do_broadcast(@dispatch, "new track", payload)

    # send track to excavators, so it can prepare for trucks arriving soon
    broadcast_all_operators("other track", payload, &(&1.type == "Excavator" && &1.id != track.asset_id))
  end

  def send_settings_to_all() do
    settings = Settings.get()

    do_broadcast(@dispatch, "set settings", settings)
    broadcast_all_operators("set settings", settings)
  end

  def send_activity(nil, source, activity_type, timestamp) do
    activity = %{
      activity: activity_type,
      source: source,
      operator_id: nil,
      asset_id: nil,
      device_timestamp: timestamp,
      server_timestamp: Helper.timestamp()
    }

    ActivityAgent.append(activity)
  end

  def send_activity(identifier, source, activity_type, timestamp) do
    # this needs a source type coming in

    case get_assignment(identifier) do
      {_device, assignment, _type} ->
        activity = %{
          activity: activity_type,
          source: source,
          operator_id: assignment.operator_id,
          asset_id: assignment.asset_id,
          device_timestamp: timestamp,
          server_timestamp: Helper.timestamp()
        }

        ActivityAgent.append(activity)

      _ ->
        nil
    end
  end

  def send_time_code_tree_elements() do
    payload = %{
      time_code_tree_elements: TimeCodeAgent.get_time_code_tree_elements()
    }

    do_broadcast(@dispatch, "time-code:set-tree-elements", payload)
  end

  def send_time_code_tree_elements_to(identifier) do
    case AssetAgent.get_type(identifier) do
      nil ->
        nil

      %{id: id, type: asset_type} ->
        payload = %{
          time_code_tree_elements: TimeCodeAgent.get_time_code_tree_elements(id)
        }

        broadcast_to_asset_type(%{type: asset_type}, "time-code:set-tree-elements", payload)
    end

    send_time_code_tree_elements()
  end

  def send_live_queue(queue) do
    do_broadcast(@dispatch, "set live queue", queue)
  end

  def send_presence_state() do
    presence_list = Presence.list(@dispatch)
    do_broadcast(@dispatch, "presence_state", presence_list)
  end

  def send_asset_radios() do
    payload = %{asset_radios: AssetRadioAgent.all()}
    do_broadcast(@dispatch, "set asset radios", payload)
    broadcast_all_operators("set asset radios", payload)
  end

  def set_dispatcher_data(keys, value, parser_type \\ "none")

  def set_dispatcher_data(keys, value, parser_type) when is_list(keys) do
    data = %{keys: keys, value: value, parser_type: parser_type}
    do_broadcast(@dispatch, "setVuexData", data)
  end

  def set_dispatcher_data(key, value, parser_type),
    do: set_dispatcher_data([key], value, parser_type)
end
