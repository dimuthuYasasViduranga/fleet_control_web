defmodule FleetControlWeb.DispatcherChannel.Topics.Operator do
  alias FleetControlWeb.Broadcast
  alias FleetControl.OperatorAgent

  @decorate authorized(:can_edit_operators)
  def handle_in("operator:add", payload, socket) do
    %{
      "name" => name,
      "nickname" => nickname,
      "employee_id" => employee_id
    } = payload

    case OperatorAgent.add(employee_id, name, nickname) do
      {:ok, _operator} ->
        Broadcast.send_operators_to_all()
        {:reply, :ok, socket}

      {:error, :employee_id_taken} ->
        {:reply, to_error("Employee ID already taken"), socket}
    end
  end

  @decorate authorized(:can_edit_operators)
  def handle_in("operator:update", payload, socket) do
    %{
      "id" => id,
      "name" => name,
      "nickname" => nickname
    } = payload

    case OperatorAgent.update(id, name, nickname) do
      {:ok, _operator} ->
        Broadcast.send_operators_to_all()
        {:reply, :ok, socket}

      {:error, :not_found} ->
        {:reply, to_error("No employee found"), socket}

      {:error, :invalid_name} ->
        {:reply, to_error("Invalid name"), socket}
    end
  end

  @decorate authorized(:can_edit_operators)
  def handle_in("operator:bulk-add", %{"operators" => operators}, socket) do
    operators =
      Enum.map(operators, fn o ->
        %{
          name: o["name"],
          nickname: o["nickname"],
          employee_id: o["employee_id"]
        }
      end)

    case OperatorAgent.bulk_add(operators) do
      {:ok, _operators} ->
        Broadcast.send_operators_to_all()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  @decorate authorized(:can_edit_operators)
  def handle_in("operator:set-enabled", %{"id" => operator_id, "enabled" => enabled}, socket) do
    case enabled do
      true ->
        OperatorAgent.restore(operator_id)

      false ->
        Broadcast.force_logout(%{operator_id: operator_id})
        OperatorAgent.delete(operator_id)
    end
    |> case do
      {:ok, _operator} ->
        Broadcast.send_operators_to_all()
        {:reply, :ok, socket}

      {:error, :invalid_id} ->
        {:reply, to_error("No employee found"), socket}
    end
  end
end
