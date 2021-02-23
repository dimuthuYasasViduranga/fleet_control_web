defmodule DispatchWeb.DispatcherChannel.PreStartTopics do
  @moduledoc """
  Holds the pre start specific topics
  """

  alias Dispatch.PreStartAgent
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

    Broadcast.send_pre_starts_to_all()

    {:reply, :ok, socket}
  end

  def handle_in("pre-start:get submissions", shift_id, socket) do
    # optional timestamp, if not given, default to now
    IO.inspect("---- get form")
    IO.inspect(shift_id)

    {:reply, :ok, socket}
  end
end
