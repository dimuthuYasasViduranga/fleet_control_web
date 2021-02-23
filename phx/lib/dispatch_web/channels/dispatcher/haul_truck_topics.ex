defmodule DispatchWeb.DispatcherChannel.HaulTruckTopics do
  @moduledoc """
  Holds all haul truck specific topics to make the dispatcher channel cleaner
  """

  alias Dispatch.{
    Helper,
    HaulTruckDispatchAgent,
    ManualCycleAgent,
    CalendarAgent,
    EngineHoursAgent,
    TrackAgent,
    Tracks
  }

  alias DispatchWeb.Broadcast

  def handle_in("haul:set dispatch", payload, socket) do
    set_dispatch(payload, socket)
  end

  def handle_in(
        "haul:set mass dispatch",
        %{"asset_ids" => asset_ids, "dispatch" => dispatch},
        socket
      ) do
    case HaulTruckDispatchAgent.mass_set(asset_ids, dispatch) do
      {:ok, dispatches} ->
        dispatches
        |> Enum.map(&%{asset_id: &1.asset_id})
        |> Enum.uniq()
        |> Broadcast.HaulTruck.send_dispatches()

        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  def handle_in("haul:update manual cycle", cycle, socket) do
    cycle = Map.put(cycle, "timestamp", Helper.naive_timestamp())

    case ManualCycleAgent.add(cycle) do
      {:ok, cycle} ->
        Broadcast.send_activity(
          %{asset_id: cycle["asset_id"]},
          "dispatcher",
          "Manual cycle updated",
          cycle["timestamp"]
        )

        Broadcast.HaulTruck.send_manual_cycles_to_asset(%{asset_id: cycle.asset_id})
        Broadcast.HaulTruck.send_manual_cycles_to_dispatcher()

        {:reply, :ok, socket}

      _ ->
        {:reply, {:error, %{error: "invalid cycle"}}, socket}
    end
  end

  def handle_in("haul:delete manual cycle", cycle_id, socket) do
    now = Helper.naive_timestamp()

    case ManualCycleAgent.delete(cycle_id, now) do
      {:ok, cycle} ->
        Broadcast.send_activity(
          %{asset_id: cycle.asset_id},
          "dispatcher",
          "Manual cycle delete",
          now
        )

        Broadcast.HaulTruck.send_manual_cycles_to_asset(%{asset_id: cycle.asset_id})
        Broadcast.HaulTruck.send_manual_cycles_to_dispatcher()

        {:reply, :ok, socket}

      _ ->
        {:reply, {:error, %{error: "cannot delete cycle"}}}
    end
  end

  def handle_in("haul:get manual cycle data", calendar_id, socket) do
    case CalendarAgent.get(%{id: calendar_id}) do
      nil ->
        {:reply, {:error, %{error: "shift does not exist"}}, socket}

      shift ->
        range = %{start_time: shift.shift_start, end_time: shift.shift_end}
        engine_hours = EngineHoursAgent.fetch_by_range!(range)
        cycles = ManualCycleAgent.fetch_by_range!(range)

        payload = %{
          shift: shift,
          engine_hours: engine_hours,
          cycles: cycles
        }

        {:reply, {:ok, payload}, socket}
    end
  end

  def set_dispatch(dispatch, socket) do
    case HaulTruckDispatchAgent.set(dispatch) do
      {:ok, dispatch} ->
        asset_id = dispatch.asset_id
        Broadcast.HaulTruck.send_dispatch(%{asset_id: asset_id})
        update_track_data(asset_id)

        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  defp update_track_data(asset_id) do
    case TrackAgent.get(%{asset_id: asset_id}) do
      nil ->
        nil

      track ->
        track
        |> Tracks.add_info()
        |> Broadcast.send_track()
    end
  end

  defp to_error({:error, reason}), do: to_error(reason)

  defp to_error(%Ecto.Changeset{} = changeset), do: to_error(hd(changeset.errors))

  defp to_error(reason), do: {:error, %{error: reason}}
end
