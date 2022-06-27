defmodule FleetControl.OperatorAgent do
  @moduledoc """
  Store for all available operators
  """

  use Agent
  alias FleetControl.{Helper, AgentHelper}
  require Logger

  alias HpsData.Schemas.Dispatch.Operator
  alias HpsData.Repo

  @type operator :: map()

  import Ecto.Query, only: [from: 2]

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    from(o in Operator,
      select: %{
        id: o.id,
        name: o.name,
        nickname: o.nickname,
        employee_id: o.employee_id,
        deleted: o.deleted
      }
    )
    |> Repo.all()
    |> Enum.map(&{&1.employee_id, &1})
    |> Enum.into(%{})
  end

  defp all_map(), do: Agent.get(__MODULE__, & &1)

  @spec refresh!() :: :ok
  def refresh!(), do: AgentHelper.set(__MODULE__, &init/0)

  @spec all() :: list(operator)
  def all(), do: Map.values(all_map())

  @spec active() :: list(operator)
  def active(), do: Enum.reject(all(), &(&1.deleted == true))

  @spec get(atom, term) :: operator | nil
  def get(:employee_id, value), do: all_map()[value]
  def get(key, value), do: Enum.find(all(), &(&1[key] == value))

  @spec add(String.t(), String.t(), String.t()) ::
          {:ok, operator} | {:error, :employee_id_taken | :invalid_employee_id | term}
  def add(nil, _, _), do: {:error, :invalid_employee_id}

  def add(employee_id, name, nickname) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Repo.get_by(Operator, %{employee_id: employee_id}) do
        nil ->
          %{employee_id: employee_id, name: name, nickname: nickname}
          |> Operator.new()
          |> Repo.insert()
          |> update_agent(state)

        _ ->
          {{:error, :employee_id_taken}, state}
      end
    end)
  end

  @spec bulk_add(list(map)) :: {:ok, list(map)} | {:error, term}
  def buld_add([]), do: {:ok, []}

  def bulk_add(operators) do
    Agent.get_and_update(__MODULE__, fn state ->
      count = length(operators)

      case Repo.insert_all(Operator, operators, returning: true) do
        {^count, operators} ->
          operators = Enum.map(operators, &Operator.to_map/1)

          operator_map =
            operators
            |> Enum.map(&{&1.employee_id, &1})
            |> Enum.into(%{})

          {{:ok, operators}, Map.merge(state, operator_map)}

        _ ->
          {{:error, :invalid_operators}, state}
      end
    end)
  end

  @spec update(integer, String.t(), String.t()) ::
          {:ok, operator} | {:error, :invalid_id | term}
  def update(id, name, nickname) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Helper.get_by_or_nil(Repo, Operator, %{id: id}) do
        nil ->
          {{:error, :invalid_id}, state}

        operator ->
          operator
          |> Operator.changeset(%{name: name, nickname: nickname})
          |> Repo.update()
          |> update_agent(state)
      end
    end)
  end

  @spec delete(integer) :: {:ok, operator} | {:error, :invalid_id | :already_deleted | term}
  def delete(id) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Helper.get_by_or_nil(Repo, Operator, %{id: id}) do
        nil ->
          {{:error, :invalid_id}, state}

        %{deleted: true} ->
          {{:error, :already_deleted}, state}

        operator ->
          operator
          |> Operator.changeset(%{deleted: true})
          |> Repo.update()
          |> update_agent(state)
      end
    end)
  end

  @spec restore(integer) ::
          {:ok, operator} | {:error, :invalid_id | :not_deleted | term}
  def restore(nil), do: {:error, :invalid_id}

  def restore(id) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Repo.get_by(Operator, %{id: id}) do
        nil ->
          {{:error, :invalid_id}, state}

        %{deleted: false} ->
          {{:error, :not_deleted}, state}

        operator ->
          operator
          |> Operator.changeset(%{deleted: false})
          |> Repo.update()
          |> update_agent(state)
      end
    end)
  end

  defp update_agent({:ok, %Operator{} = operator}, state) do
    operator = Operator.to_map(operator)
    update_agent({:ok, operator}, state)
  end

  defp update_agent({:ok, operator}, state) do
    state = Map.put(state, operator.employee_id, operator)
    {{:ok, operator}, state}
  end

  defp update_agent(error, state), do: {error, state}
end
