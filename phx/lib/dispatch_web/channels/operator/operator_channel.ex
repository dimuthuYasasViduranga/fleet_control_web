defmodule DispatchWeb.OperatorChannel do
  @moduledoc nil

  use DispatchWeb, :channel
  use Appsignal.Instrumentation.Decorators

  require Logger

  alias __MODULE__.{HaulTruckTopics, DigUnitTopics, WaterCartTopics}

  alias DispatchWeb.{Presence, Broadcast}

  alias Dispatch.{
    Helper,
    AssetAgent,
    OperatorAgent,
    OperatorMessageAgent,
    OperatorMessageTypeAgent,
    DispatcherMessageAgent,
    DeviceAssignmentAgent,
    EngineHoursAgent,
    TimeCodeAgent,
    TimeAllocationAgent,
    LocationAgent,
    TrackAgent,
    MaterialTypeAgent,
    LoadStyleAgent,
    AssetRadioAgent,
    PreStartAgent,
    PreStartSubmissionAgent,
    DigUnitActivityAgent,
    MapTileAgent
  }

  alias Phoenix.Socket

  @type topic :: String.t()

  @spec join(topic, any(), Socket.t()) :: {:ok, Socket.t()}
  def join("operators:" <> _device_uuid, _params, socket) do
    send(self(), :after_join)
    operator_id = socket.assigns.operator_id
    device_uuid = socket.assigns.device_uuid
    device_id = socket.assigns.device_id

    Logger.info(
      "[Joined operators] device: #{device_id}[#{device_uuid}], operator: #{operator_id}"
    )

    Broadcast.send_activity(%{device_id: device_id}, "operator", "operator login")
    {:ok, socket}
  end

  @spec handle_info(:after_join, Socket.t()) :: {:noreply, Socket.t()}
  def handle_info(:after_join, socket) do
    "operators:" <> device_uuid = socket.topic

    timestamp = System.system_time(:second)
    info = %{online_at: inspect(timestamp)}

    {:ok, _} = Presence.track(socket.channel_pid, "dispatchers:all", device_uuid, info)
    {:noreply, socket}
  end

  @spec handle_in(String.t(), map(), Socket.t()) ::
          {:noreply, Socket.t()}
          | {:reply, :ok, Socket.t()}
  @decorate channel_action()
  def handle_in("get device state", params, socket) do
    operator_id = socket.assigns.operator_id
    device_id = socket.assigns.device_id
    device_name = "#{device_id}[#{socket.assigns.device_uuid}]"

    assignment = DeviceAssignmentAgent.get(%{device_id: device_id})
    asset_id = assignment[:asset_id]

    state =
      case get_connect_type(params) do
        :new ->
          Logger.info("[New Login] device: #{device_name}, operator: #{operator_id}")

          # logout all other assets that have the operator logged in
          logout_other_assets(asset_id, operator_id)

          if asset_id do
            DeviceAssignmentAgent.change(asset_id, %{
              operator_id: operator_id,
              timestamp: Helper.naive_timestamp()
            })
          end

          Broadcast.send_assignments_to_all()

          get_device_state(asset_id)

        connect_type ->
          Logger.info(
            "[Device Reconnect] #{connect_type} | device: #{device_name}, operator: #{operator_id}"
          )

          case assignment[:operator_id] == operator_id do
            true -> get_device_state(asset_id)
            _ -> %{logout: "Operator has changed device"}
          end
      end

    push(socket, "set device state", state)

    {:noreply, socket}
  end

  def handle_in("logout", %{}, socket) do
    device_id = socket.assigns.device_id
    device_uuid = socket.assigns.device_uuid
    operator_id = socket.assigns.operator_id

    case DeviceAssignmentAgent.get_asset_id(%{device_id: device_id}) do
      nil ->
        nil

      asset_id ->
        change = %{operator_id: nil, timestamp: Helper.naive_timestamp()}
        DeviceAssignmentAgent.change(asset_id, change)

        Broadcast.send_assignments_to_all()
        Broadcast.send_activity(%{asset_id: asset_id}, "operator", "operator logout")
    end

    Logger.info("[Left operators] device: #{device_id}[#{device_uuid}], operator: #{operator_id}")
    Presence.untrack(socket, device_uuid)

    {:reply, :ok, socket}
  end

  def handle_in("submit offline logins", logins, socket) when is_list(logins) do
    device_id = socket.assigns.device_id
    now = NaiveDateTime.utc_now()

    logins
    |> Enum.map(fn login ->
      %{
        device_id: device_id,
        asset_id: login["asset_id"],
        operator_id: login["operator_id"],
        timestamp: Helper.to_naive(login["timestamp"]),
        server_timestamp: now
      }
    end)
    |> Enum.reject(fn login ->
      any_nils =
        login
        |> Map.values()
        |> Enum.any?(&is_nil/1)

      in_future = NaiveDateTime.compare(login.timestamp, now) == :gt

      any_nils || in_future
    end)
    |> Enum.each(fn login ->
      DeviceAssignmentAgent.new(login)

      Broadcast.send_activity(
        %{device_id: login.device_id},
        "operator",
        "operator login",
        login.timestamp
      )
    end)

    Broadcast.send_assignments_to_all()
    {:reply, :ok, socket}
  end

  def handle_in("submit logouts", logouts, socket) when is_list(logouts) do
    device_id = socket.assigns.device_id
    now = NaiveDateTime.utc_now()

    logouts
    |> Enum.reject(fn logout ->
      asset_id = logout["asset_id"]
      timestamp = logout["timestamp"]

      is_nil(asset_id) || !timestamp ||
        NaiveDateTime.compare(
          Helper.to_naive(timestamp),
          NaiveDateTime.add(now, @max_clock_lead_s)
        ) == :gt
    end)
    |> Enum.each(fn logout ->
      timestamp = logout["timestamp"]
      asset_id = logout["asset_id"]

      DeviceAssignmentAgent.new(%{
        asset_id: asset_id,
        device_id: device_id,
        operator_id: nil,
        timestamp: timestamp,
        server_timestamp: now
      })

      Broadcast.send_activity(
        %{device_id: device_id},
        "operator",
        "operator logout",
        timestamp
      )
    end)

    Broadcast.send_assignments_to_all()
    {:reply, :ok, socket}
  end

  def handle_in("submit dispatcher message acknowledgements", acknowledgements, socket)
      when is_list(acknowledgements) do
    device_id = socket.assigns.device_id

    Enum.each(acknowledgements, fn acknowledgement ->
      timestamp = acknowledgement["timestamp"]

      DispatcherMessageAgent.acknowledge(
        acknowledgement["id"],
        acknowledgement["answer"],
        device_id,
        timestamp
      )

      Broadcast.send_activity(
        %{device_id: device_id},
        "operator",
        "dispatcher message acknowledged",
        timestamp
      )
    end)

    Broadcast.send_dispatcher_messages_to(%{device_id: device_id})
    {:reply, :ok, socket}
  end

  def handle_in("submit messages", messages, socket) when is_list(messages) do
    Enum.each(messages, fn message ->
      case OperatorMessageAgent.new(message) do
        {:ok, message} ->
          Broadcast.send_activity(
            %{asset_id: message.asset_id},
            "operator",
            "operator message",
            message.timestamp
          )

        _ ->
          nil
      end
    end)

    Broadcast.send_operator_messages_to_dispatcher()

    # for each asset in the messages, send unread operator messages
    messages
    |> Enum.map(& &1["asset_id"])
    |> Enum.uniq()
    |> Enum.each(&Broadcast.send_unread_operator_messages_to_operator/1)

    {:reply, :ok, socket}
  end

  def handle_in("submit engine hours", engine_hours_list, socket)
      when is_list(engine_hours_list) do
    engine_hours_list
    |> Enum.filter(&(!is_nil(&1["asset_id"])))
    |> Enum.map(fn engine_hours ->
      case EngineHoursAgent.new(engine_hours) do
        {:ok, eh} ->
          Broadcast.send_activity(
            %{asset_id: eh.asset_id},
            "operator",
            "engine hours updated",
            eh.timestamp
          )

          eh.asset_id

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.map(&Broadcast.send_engine_hours_to(%{asset_id: &1}))

    Broadcast.send_engine_hours_to_dispatcher()

    {:reply, :ok, socket}
  end

  def handle_in("submit allocations", allocations, socket) when is_list(allocations) do
    allocations
    |> Enum.map(&Helper.to_atom_map!/1)
    |> Enum.group_by(& &1.asset_id)
    |> Enum.map(fn {asset_id, allocs} ->
      TimeAllocationAgent.update_all(allocs)
      Broadcast.send_active_allocation_to(%{asset_id: asset_id})
    end)

    Broadcast.send_allocations_to_dispatcher()

    {:reply, :ok, socket}
  end

  def handle_in("submit exceptions", exceptions, socket) when is_list(exceptions) do
    exceptions
    |> Enum.map(&Helper.to_atom_map!/1)
    |> TimeAllocationAgent.update_all()

    Enum.each(exceptions, &Broadcast.send_active_allocation_to(%{asset_id: &1["asset_id"]}))
    Broadcast.send_allocations_to_dispatcher()

    {:reply, :ok, socket}
  end

  def handle_in("submit pre-start submissions", submissions, socket) when is_list(submissions) do
    Enum.each(submissions, &PreStartSubmissionAgent.add/1)

    Broadcast.send_pre_start_submissions_to_all()

    {:reply, :ok, socket}
  end

  def handle_in("set device track", track, socket) do
    with true <- Application.get_env(:dispatch_web, :use_device_gps),
         {:ok, track} <- TrackAgent.add(parse_device_track(track), :normal) do
      Broadcast.send_track(track)
    else
      _ -> nil
    end

    {:noreply, socket}
  end

  def handle_in("haul:" <> _ = topic, payload, socket) do
    HaulTruckTopics.handle_in(topic, payload, socket)
  end

  def handle_in("dig:" <> _ = topic, payload, socket) do
    DigUnitTopics.handle_in(topic, payload, socket)
  end

  defp get_connect_type(params) do
    case params["connect"] do
      "new" -> :new
      "hard_reconnect" -> :hard_reconnect
      _ -> :reconnect
    end
  end

  defp logout_other_assets(asset_id, operator_id) do
    asset_ids =
      DeviceAssignmentAgent.current()
      |> Enum.filter(&(&1.operator_id == operator_id && &1.asset_id != asset_id))
      |> Enum.map(& &1.asset_id)

    {:ok, _} = DeviceAssignmentAgent.clear_operators(asset_ids)
    Enum.each(asset_ids, &Broadcast.force_logout(%{asset_id: &1}))
  end

  defp parse_device_track(nil), do: nil

  defp parse_device_track(track) do
    pos = track["position"]
    vel = track["velocity"]
    acc = track["accuracy"]

    %{
      asset_id: track["asset_id"],
      asset_name: track["asset_name"],
      asset_type: track["asset_type"],
      description: nil,
      ignition: track["ignition"],
      position: %{
        lat: pos["lat"],
        lng: pos["lng"],
        alt: pos["alt"]
      },
      accuracy: %{
        horizontal: acc["horizontal"],
        vertical: acc["vertical"]
      },
      speed_ms: vel["speed"],
      heading: vel["heading"],
      timestamp: Helper.to_naive(track["timestamp"]),
      valid: track["valid"]
    }
  end

  defp get_device_state(asset_id) do
    assignment = DeviceAssignmentAgent.get(%{asset_id: asset_id}) || %{}

    asset = AssetAgent.get_asset(%{id: asset_id})
    asset_type_id = asset[:type_id]

    operator_id = assignment[:operator_id]

    dispatcher_messages = DispatcherMessageAgent.all(asset_id)

    active_allocation = TimeAllocationAgent.get_active(%{asset_id: asset_id})

    locations =
      LocationAgent.active_locations()
      |> Enum.map(&Map.drop(&1, [:polygon]))

    latest_track = TrackAgent.get(%{asset_id: asset_id})

    other_tracks = TrackAgent.all() |> Enum.reject(&(&1.asset_id == asset_id))

    common_state = %{
      device_id: assignment[:device_id],
      asset_id: asset_id,
      operator_id: operator_id,
      assets: AssetAgent.get_assets(),
      asset_types: AssetAgent.get_types(),
      asset_radios: AssetRadioAgent.all(),
      operators: OperatorAgent.all(),
      locations: locations,
      material_types: MaterialTypeAgent.get_active(),
      load_styles: LoadStyleAgent.all(),
      time_codes: TimeCodeAgent.get_time_codes(),
      time_code_groups: TimeCodeAgent.get_time_code_groups(),
      time_code_tree_elements: TimeCodeAgent.get_time_code_tree_elements(asset_type_id),
      device_assignments: DeviceAssignmentAgent.current(),
      dig_unit_activities: DigUnitActivityAgent.current(),
      assignment: assignment,
      dispatcher_messages: dispatcher_messages,
      unread_operator_messages: OperatorMessageAgent.unread(asset_id),
      operator_message_types: OperatorMessageTypeAgent.types(),
      operator_message_type_tree: OperatorMessageTypeAgent.tree_elements(asset_type_id),
      engine_hours: EngineHoursAgent.get_asset(asset_id),
      allocation: active_allocation,
      track: latest_track,
      other_tracks: other_tracks,
      pre_start_ticket_status_types: PreStartSubmissionAgent.ticket_status_types(),
      pre_start_control_categories: PreStartAgent.categories(),
      pre_start_forms: PreStartAgent.all(),
      pre_start_submissions: %{
        current: PreStartSubmissionAgent.current(asset_id),
        historic: PreStartSubmissionAgent.historic(asset_id)
      },
      map_manifest: MapTileAgent.get(),
      send_device_gps: Application.get_env(:dispatch_web, :use_device_gps, false)
    }

    # get asset type is defined through using Topics
    case get_asset_type_state(asset, operator_id) do
      nil ->
        %{common: common_state}

      {asset_type, asset_type_state} ->
        %{
          :common => common_state,
          asset_type => asset_type_state
        }
    end
  end

  def get_asset_type_state(asset, operator_id) do
    asset_type = asset[:secondary_type] || asset[:type]

    case asset_type do
      nil ->
        nil

      "Haul Truck" ->
        {asset_type, HaulTruckTopics.get_asset_type_state(asset, operator_id)}

      "Dig Unit" ->
        {asset_type, DigUnitTopics.get_asset_type_state(asset, operator_id)}

      "Watercart" ->
        {asset_type, WaterCartTopics.get_asset_type_state(asset, operator_id)}

      _ ->
        Logger.error("No state for asset: '#{asset.name}' of type '#{asset.type}'")
        nil
    end
  end
end
