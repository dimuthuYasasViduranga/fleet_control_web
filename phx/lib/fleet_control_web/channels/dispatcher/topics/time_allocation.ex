defmodule FleetControlWeb.DispatcherChannel.Topics.TimeAllocation do
  alias FleetControl.OperatorTimeAllocation
  alias FleetControl.TimeAllocation
  alias FleetControl.Haul
  alias FleetControl.DeviceAssignmentAgent
  alias FleetControl.CalendarAgent

  alias FleetControlWeb.Broadcast

  use HpsPhx.Authorization.Decorator
  import FleetControlWeb.DispatcherChannel, only: [to_error: 1]

  def handle_in("set", %{"asset_id" => asset_id} = allocation, socket) do
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
        "mass-set",
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

  @decorate authorized_channel("fleet_control_edit_time_allocations")
  def handle_in("edit", allocations, socket) do
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

  @decorate authorized_channel("fleet_control_lock_time_allocations")
  def handle_in("lock", %{"ids" => ids, "calendar_id" => cal_id}, socket) do
    dispatcher_id = socket.assigns[:current_user][:id]

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

  @decorate authorized_channel("fleet_control_lock_time_allocations")
  def handle_in("unlock", ids, socket) when is_list(ids) do
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

  def handle_in("get-data", calendar_id, socket) do
    ref = Phoenix.Channel.socket_ref(socket)

    case CalendarAgent.get(%{id: calendar_id}) do
      nil ->
        {:reply, to_error("shift does not exist"), socket}

      shift ->
        task =
          Task.async(fn ->
            range = %{start_time: shift.shift_start, end_time: shift.shift_end}
            allocations = FleetControl.TimeAllocation.EctoQueries.fetch_by_range!(range)

            device_assignments = DeviceAssignmentAgent.fetch_by_range!(range)

            timeusage = Haul.fetch_timeusage_by_range!(%{calendar_id: calendar_id})
            cycles = Haul.fetch_cycles_by_range!(%{calendar_id: calendar_id})

            payload = %{
              shift: shift,
              allocations: allocations,
              device_assignments: device_assignments,
              timeusage: timeusage,
              cycles: cycles
            }

            Phoenix.Channel.reply(ref, {:ok, payload})
          end)

        Task.await(task)
        send(self(), :gc)

        {:noreply, socket}
    end
  end

  def handle_in("get-operator-data", calendar_id, socket) do
    ref = Phoenix.Channel.socket_ref(socket)

    case CalendarAgent.get(%{id: calendar_id}) do
      nil ->
        {:reply, to_error("shift does not exists"), socket}

      shift ->
        task =
          Task.async(fn ->
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

            Phoenix.Channel.reply(ref, {:ok, payload})
          end)

        Task.await(task)
        send(self(), :gc)

        {:noreply, socket}
    end
  end

  def handle_info(:gc, socket) do
    send(socket.transport_pid, :garbage_collect)
    :erlang.garbage_collect()
    {:noreply, socket}
  end
end
