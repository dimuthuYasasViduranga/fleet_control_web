defmodule DispatchWeb.DispatcherChannel.DigUnitTopics do
  @moduledoc false

  alias Dispatch.DigUnitActivityAgent

  alias DispatchWeb.Broadcast

  def handle_in("dig:set activity", activity, socket) do
    case DigUnitActivityAgent.add(activity) do
      {:ok, activity} ->
        identifier = %{asset_id: activity.asset_id}
        Broadcast.DigUnit.send_activity_to_asset(identifier)
        Broadcast.DigUnit.send_activities_to_all()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  defp to_error({:error, reason}), do: to_error(reason)

  defp to_error(%Ecto.Changeset{} = changeset), do: to_error(hd(changeset.errors))

  defp to_error(reason), do: {:error, %{error: reason}}
end
