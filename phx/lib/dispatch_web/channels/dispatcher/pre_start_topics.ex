defmodule DispatchWeb.DispatcherChannel.PreStartTopics do
  @moduledoc """
  Holds the pre start specific topics
  """

  alias Dispatch.{Helper, PreStartAgent, PreStartSubmissionAgent}
  alias DispatchWeb.Broadcast

  defp get_dispatcher_id(socket), do: socket.assigns[:current_user][:id]

  def handle_in(
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

  def handle_in(
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
end
