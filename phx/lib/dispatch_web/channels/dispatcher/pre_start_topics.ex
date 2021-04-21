defmodule DispatchWeb.DispatcherChannel.PreStartTopics do
  @moduledoc """
  Holds the pre start specific topics
  """

  alias Dispatch.{Helper, PreStartAgent, PreStartSubmissionAgent}
  alias DispatchWeb.Broadcast
  use DispatchWeb.Authorization.Decorator
  import DispatchWeb.DispatcherChannel, only: [to_error: 1]

  defp get_dispatcher_id(socket), do: socket.assigns[:current_user][:id]

  def handle_in(topic, data, socket) do
    case topic do
      "pre-start:add form" -> add_form(topic, data, socket)
      _ -> handle(topic, data, socket)
    end
  end

  @decorate authorized(:can_edit_pre_starts)
  defp add_form(
         "pre-start:add form",
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

  defp handle(
         "pre-start:get submissions",
         data,
         socket
       ) do
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

        {:reply, {:ok, payload}, socket}
    end
  end

  defp handle("pre-start:set response ticket", params, socket) do
    dispatcher_id = get_dispatcher_id(socket)

    params
    |> Map.put(:dispatcher_id, dispatcher_id)
    |> PreStartSubmissionAgent.add_ticket()
    |> case do
      {:ok, ticket, _submission} ->
        Broadcast.send_pre_start_submissions_to_all()
        {:reply, {:ok, %{ticket: ticket}}, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  defp handle("pre-start:update response ticket status", params, socket) do
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
end
