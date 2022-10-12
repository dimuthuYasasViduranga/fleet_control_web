defmodule FleetControl do
  alias FleetControl.{DispatcherAgent, PreStartSubmissionAgent}
  alias FleetControlWeb.Broadcast

  def set_pre_start_ticket(user_id, name, params) do
    {:ok, dispatcher} = DispatcherAgent.add(user_id, name)

    params
    |> Map.put(:dispatcher_id, dispatcher.id)
    |> PreStartSubmissionAgent.add_ticket()
    |> case do
      {:ok, ticket, _submission} ->
        Broadcast.send_pre_start_submissions_to_all()
        {:ok, %{ticket: ticket}}

      error ->
        error
    end
  end

  def update_pre_start_ticket(user_id, name, params) do
    {:ok, dispatcher} = DispatcherAgent.add(user_id, name)

    params
    |> Map.put(:dispatcher_id, dispatcher.id)
    |> PreStartSubmissionAgent.update_ticket_status()
    |> case do
      {:ok, status, submissions} ->
        if status.active == true and length(submissions) > 0 do
          Broadcast.send_pre_start_submissions_to_all()
        end

        {:ok, %{status: status}}

      error ->
        error
    end
  end
end
