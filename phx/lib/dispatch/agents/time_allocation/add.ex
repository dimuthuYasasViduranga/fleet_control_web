defmodule FleetControl.TimeAllocationAgent.Add do
  alias FleetControl.Helper, as: DHelper
  alias FleetControl.TimeAllocationAgent.{Helper, Update}

  alias HpsData.Schemas.Dispatch.TimeAllocation
  alias HpsData.Repo

  alias Ecto.Multi

  require Logger

  @type state :: map
  @type allocation :: map
  @type input_alloc :: %{
          asset_id: integer,
          time_code_id: integer,
          start_time: NaiveDateTime.t() | integer,
          end_time: NaiveDateTime.t() | integer | nil
        }

  @spec add(module, map | input_alloc) :: {:ok, allocation} | {:error, :invalid_keys | term}
  def add(module, %{"asset_id" => _asset_id} = alloc) do
    alloc = DHelper.to_atom_map!(alloc)
    add(module, alloc)
  end

  def add(module, alloc) do
    if Helper.has_keys?(alloc, [:asset_id, :time_code_id, :start_time, :end_time]) do
      unless alloc[:created_by_operator] || alloc[:created_by_dispatcher] do
        Logger.error("Time allocation created without recording it's source")
      end

      alloc =
        %{
          alloc
          | start_time: DHelper.to_naive(alloc.start_time),
            end_time: DHelper.to_naive(alloc.end_time)
        }
        |> ensure_allocation_before_timestamp(NaiveDateTime.utc_now())

      Agent.get_and_update(module, fn state ->
        case alloc do
          %{end_time: nil} = alloc -> add_active_allocation(alloc, state)
          alloc -> add_completed_allocation(alloc, state)
        end
      end)
    else
      {:error, :invalid_keys}
    end
  end

  defp ensure_allocation_before_timestamp(allocation, timestamp) do
    allocation =
      case Helper.naive_compare?(allocation.start_time, [:gt], timestamp) do
        true -> Map.put(allocation, :start_time, timestamp)
        false -> allocation
      end

    cond do
      is_nil(allocation[:end_time]) ->
        allocation

      Helper.naive_compare?(allocation.end_time, [:lt], allocation.start_time) ->
        Map.put(allocation, :end_time, allocation.start_time)

      true ->
        allocation
    end
  end

  defp add_active_allocation(alloc, state) do
    case state.active[alloc.asset_id] do
      nil ->
        # no current element, just insert
        add_completed_allocation(alloc, state)

      current ->
        cond do
          Helper.naive_compare?(alloc.start_time, [:eq, :lt], current.start_time) ->
            {{:error, :start_before_active}, state}

          true ->
            deleted_current =
              TimeAllocation
              |> Repo.get_by!(%{id: current.id})
              |> TimeAllocation.changeset(%{deleted: true})

            completed =
              current
              |> Map.put(:end_time, alloc.start_time)
              |> create_new_allocation(state.no_task_id)

            new_current = create_new_allocation(alloc, state.no_task_id)

            {resp, state} =
              Multi.new()
              |> Multi.update(:deleted_current, deleted_current)
              |> Multi.insert(:completed, completed)
              |> Multi.insert(:new_current, new_current)
              |> Repo.transaction()
              |> update_agent_from_commits(
                [:deleted_current, :completed, :new_current],
                state
              )

            {List.last(resp), state}
        end
    end
  end

  defp add_completed_allocation(alloc, state) do
    alloc
    |> create_new_allocation(state.no_task_id)
    |> Repo.insert()
    |> Update.update_agent(state)
  end

  def create_new_allocation(params, no_task_id) do
    %{params | time_code_id: params[:time_code_id] || no_task_id}
    |> TimeAllocation.new()
  end

  defp update_agent_from_commits({:ok, _}, [], state), do: {[], state}

  defp update_agent_from_commits({:ok, commits}, [key | keys], state) do
    {resp, state} = update_agent_from_commits({:ok, commits}, keys, state)
    {alloc, state} = Update.update_agent({:ok, commits[key]}, state)
    {[alloc | resp], state}
  end

  defp update_agent_from_commits(error, _, state), do: {error, state}
end
