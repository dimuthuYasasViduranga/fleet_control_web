defmodule Dispatch.ManualCycleAgent do
  @moduledoc """
  Stores a recent history of manually entered cycles and provides an API to
  create, delete and update cycles
  """

  alias Dispatch.{Helper, AgentHelper}
  use Agent

  import Ecto.Query, only: [from: 2, subquery: 1]
  alias Ecto.Multi

  alias HpsData.Asset
  alias HpsData.Repo
  alias HpsData.Schemas.Dispatch

  @type timerange :: %{start_time: NaiveDateTime.t(), end_time: NaiveDateTime.t()}
  @type manual_cycle :: map

  @cull_opts %{
    time_key: :start_time,
    group_key: :asset_id,
    max_age: 24 * 60 * 60
  }

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    %{
      cycles: pull_cycles()
    }
  end

  defp pull_cycles() do
    recent = NaiveDateTime.add(NaiveDateTime.utc_now(), -@cull_opts.max_age)

    latest_cycles = pull_latest_cycles()
    historic_cycles = pull_historic_cycles(recent)

    Enum.uniq(latest_cycles ++ historic_cycles)
  end

  def pull_latest_cycles() do
    max_query =
      from(a in Asset,
        select: %{
          asset_id: a.id,
          start_time:
            fragment(
              "SELECT
              MAX(start_time)
            FROM dis_manual_cycle
            WHERE asset_id = ?",
              a.id
            )
        }
      )

    from(
      a in subquery(max_query),
      join: c in Dispatch.ManualCycle,
      on: [asset_id: a.asset_id, start_time: a.start_time],
      select: %{
        id: c.id,
        asset_id: c.asset_id,
        operator_id: c.operator_id,
        start_time: c.start_time,
        end_time: c.end_time,
        load_location_id: c.load_location_id,
        dump_location_id: c.dump_location_id,
        load_unit_id: c.load_unit_id,
        material_type_id: c.material_type_id,
        relative_level: c.relative_level,
        shot: c.shot,
        deleted: c.deleted,
        timestamp: c.timestamp,
        server_timestamp: c.server_timestamp
      }
    )
    |> Repo.all()
  end

  def pull_historic_cycles(min_datetime) do
    from(c in Dispatch.ManualCycle,
      where: c.end_time >= ^min_datetime,
      select: %{
        id: c.id,
        asset_id: c.asset_id,
        operator_id: c.operator_id,
        start_time: c.start_time,
        end_time: c.end_time,
        load_location_id: c.load_location_id,
        dump_location_id: c.dump_location_id,
        load_unit_id: c.load_unit_id,
        material_type_id: c.material_type_id,
        relative_level: c.relative_level,
        shot: c.shot,
        deleted: c.deleted,
        timestamp: c.timestamp,
        server_timestamp: c.server_timestamp
      }
    )
    |> Repo.all()
  end

  @doc """
  Get all cycles that start within the given range
  """
  @spec fetch_by_range!(timerange) :: list(manual_cycle)
  def fetch_by_range!(%{start_time: start_time, end_time: end_time}) do
    # all cycles that start within the shift
    from(c in Dispatch.ManualCycle,
      where: c.start_time >= ^start_time and c.start_time < ^end_time,
      where: c.deleted != true,
      select: %{
        id: c.id,
        asset_id: c.asset_id,
        operator_id: c.operator_id,
        start_time: c.start_time,
        end_time: c.end_time,
        load_location_id: c.load_location_id,
        dump_location_id: c.dump_location_id,
        load_unit_id: c.load_unit_id,
        material_type_id: c.material_type_id,
        relative_level: c.relative_level,
        shot: c.shot,
        deleted: c.deleted,
        timestamp: c.timestamp,
        server_timestamp: c.server_timestamp
      }
    )
    |> Repo.all()
  end

  @spec get() :: list(manual_cycle)
  def get(), do: Agent.get(__MODULE__, & &1.cycles)

  @spec get(%{id: integer}) :: manual_cycle | nil
  def get(%{id: id}), do: Enum.filter(get(), &(&1.id == id))

  @spec get_by(map) :: list(manual_cycle)
  def get_by(params) do
    get()
    |> Enum.filter(fn cycle ->
      Enum.all?(params, fn {key, value} -> cycle[key] == value end)
    end)
  end

  @spec add(map()) :: {:ok, manual_cycle} | {:error, term}
  def add(%{"asset_id" => _asset_id} = cycle) do
    cycle
    |> Helper.to_atom_map!()
    |> add()
  end

  def add(%{id: _id} = cycle), do: edit(cycle)

  def add(cycle) do
    cycle = Dispatch.ManualCycle.new(cycle)

    Agent.get_and_update(__MODULE__, fn state ->
      cycle
      |> Repo.insert()
      |> update_agent(state)
    end)
  end

  @spec edit(map()) :: {:ok, manual_cycle} | {:error, :invalid_id | term}
  def edit(%{"id" => _id} = cycle) do
    cycle
    |> Helper.to_atom_map!()
    |> edit()
  end

  def edit(%{id: nil}), do: {:error, :invalid_id}

  def edit(%{id: id} = cycle) do
    new_cycle = Dispatch.ManualCycle.new(cycle)

    transaction =
      Multi.new()
      |> Multi.run(:delete_old, fn repo, _ ->
        Dispatch.ManualCycle
        |> repo.get_by(%{id: id})
        |> case do
          nil ->
            {:error, :invalid_id}

          to_delete ->
            to_delete
            |> Dispatch.ManualCycle.changeset(%{deleted: true})
            |> repo.update()
        end
      end)
      |> Multi.insert(:new_cycle, new_cycle)

    Agent.get_and_update(__MODULE__, fn state ->
      transaction
      |> Repo.transaction()
      |> case do
        {:ok, commits} ->
          {_, state} = update_agent({:ok, commits.delete_old}, state)
          update_agent({:ok, commits.new_cycle}, state)

        error ->
          {error, state}
      end
    end)
  end

  def edit(_), do: {:error, :invalid_id}

  @spec delete(integer, NaiveDateTime.t()) ::
          {:ok, manual_cycle} | {:error, :invalid_id | :already_deleted}
  def delete(nil, _timestamp), do: {:error, :invalid_id}

  def delete(cycle_id, timestamp) do
    timestamp = Helper.to_naive(timestamp)

    Agent.get_and_update(__MODULE__, fn state ->
      Dispatch.ManualCycle
      |> Repo.get(cycle_id)
      |> case do
        nil ->
          {{:error, :invalid_id}, state}

        %{deleted: true} ->
          {{:error, :already_deleted}, state}

        record ->
          record
          |> Dispatch.ManualCycle.changeset(%{deleted: true, deleted_at: timestamp})
          |> Repo.update()
          |> update_agent(state)
      end
    end)
  end

  defp update_agent({:ok, %Dispatch.ManualCycle{} = cycle}, state) do
    map_cycle = Dispatch.ManualCycle.to_map(cycle)
    update_agent({:ok, map_cycle}, state)
  end

  defp update_agent({:ok, cycle}, state) do
    state =
      AgentHelper.override_or_add(
        state,
        :cycles,
        cycle,
        &(&1.id == cycle.id),
        @cull_opts
      )

    {{:ok, cycle}, state}
  end

  defp update_agent(error, state), do: {error, state}
end
