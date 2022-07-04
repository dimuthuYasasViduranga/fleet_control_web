defmodule FleetControlWeb.DispatcherChannel.Topics.HaulTruck do
  @moduledoc """
  Holds all haul truck specific topics to make the dispatcher channel cleaner
  """

  use FleetControlWeb.Authorization.Decorator

  alias FleetControl.{
    HaulTruckDispatchAgent,
    TrackAgent,
    Tracks
  }

  alias FleetControlWeb.Broadcast

  def handle_in("set dispatch", payload, socket) do
    set_dispatch(payload, socket)
  end

  def handle_in(
        "set mass dispatch",
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
