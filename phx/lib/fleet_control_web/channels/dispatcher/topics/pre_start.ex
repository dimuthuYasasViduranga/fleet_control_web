defmodule FleetControlWeb.DispatcherChannel.Topics.PreStart do
  @moduledoc """
  Holds the pre start specific topics
  """

  alias FleetControl.{Helper, PreStartAgent, PreStartSubmissionAgent}
  alias FleetControlWeb.Broadcast
  use FleetControlWeb.Authorization.Decorator
  import FleetControlWeb.DispatcherChannel, only: [to_error: 1]

  @decorate authorized(:can_edit_pre_starts)
  def handle_in(
        "add form",
        %{"asset_type_id" => asset_type_id, "sections" => sections} = data,
        socket
      ) do
    dispatcher_id = get_dispatcher_id(socket)

    PreStartAgent.add(
      asset_type_id,
      dispatcher_id,
      sections,
      data["timestamp"] || NaiveDateTime.utc_now()
    )

    Broadcast.send_pre_start_forms_to_all()

    {:reply, :ok, socket}
  end

  @decorate authorized(:can_edit_pre_starts)
  def handle_in("update control categories", controls, socket)
      when is_list(controls) do
    controls
    |> Enum.map(&parse_category/1)
    |> PreStartAgent.update_categories()
    |> case do
      {:ok, _} ->
        Broadcast.send_pre_start_control_categories_to_all()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  @decorate authorized(:can_edit_pre_start_tickets)
  def handle_in("set response ticket", params, socket) do
    dispatcher_id = get_dispatcher_id(socket)

    params
    |> Map.put(:dispatcher_id, dispatcher_id)
    |> PreStartSubmissionAgent.add_ticket()
    |> case do
      {:ok, ticket, _submission} ->
        Broadcast.send_pre_start_submissions_to_all()
        # fixme possible socket_ref treatment
        {:reply, {:ok, %{ticket: ticket}}, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  @decorate authorized(:can_edit_pre_start_tickets)
  def handle_in("update response ticket status", params, socket) do
    dispatcher_id = get_dispatcher_id(socket)

    params
    |> Map.put(:dispatcher_id, dispatcher_id)
    |> PreStartSubmissionAgent.update_ticket_status()
    |> case do
      {:ok, status, submissions} ->
        if status.active == true and length(submissions) > 0 do
          Broadcast.send_pre_start_submissions_to_all()
        end

        {:reply, {:ok, %{status: status}}, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  def handle_in("get submissions", data, socket) do
    start_time = Helper.to_naive(data["start_time"])
    end_time = Helper.to_naive(data["end_time"])

    cond do
      is_nil(start_time) || is_nil(end_time) ->
        {:error, %{error: "Invalid time range"}, socket}

      true ->
        submissions = PreStartSubmissionAgent.get_between(start_time, end_time)

        payload = %{
          ref_id: data["ref_id"],
          submissions: submissions
        }

        # fixme possible socket_ref treatment
        {:reply, {:ok, payload}, socket}
    end
  end

  defp parse_category(cat) do
    %{
      id: cat["id"],
      name: cat["name"],
      action: cat["action"],
      order: cat["order"] || 0
    }
  end

  defp get_dispatcher_id(socket), do: socket.assigns[:current_user][:id]
end
