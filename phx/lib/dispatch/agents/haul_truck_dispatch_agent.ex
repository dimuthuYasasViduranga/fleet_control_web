defmodule FleetControl.HaulTruckDispatchAgent do
  @moduledoc """
  Stores a recent history of dispatches for haul trucks
  """
  use Agent

  require Logger

  alias FleetControl.{Helper, AgentHelper}
  alias HpsData.Repo
  alias HpsData.Schemas.Dispatch
  alias HpsData.{Asset, AssetType}

  import Ecto.Query, only: [from: 2, subquery: 1]
  alias Ecto.Multi

  @type dispatch :: map

  @cull_opts %{
    time_key: :timestamp,
    max_age: 12 * 60 * 60,
    max_size: 500
  }

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    %{
      historic: get_historic_dispatches(),
      current: get_current_dispatches()
    }
  end

  defp get_historic_dispatches() do
    now = Helper.naive_timestamp()
    recent = NaiveDateTime.add(now, -@cull_opts.max_age, :second)

    from(d in Dispatch.HaulDispatch,
      where: d.server_timestamp > ^recent,
      select: %{
        id: d.id,
        group_id: d.group_id,
        asset_id: d.asset_id,
        dig_unit_id: d.dig_unit_id,
        load_location_id: d.load_location_id,
        dump_location_id: d.dump_location_id,
        server_timestamp: d.server_timestamp,
        timestamp: d.timestamp,
        activity_id: d.activity_id,
        acknowledge_id: d.acknowledge_id
      }
    )
    |> Repo.all()
  end

  defp get_current_dispatches() do
    max_query = get_latest_query()

    from(a in subquery(max_query),
      join: at in AssetType,
      on: [id: a.asset_type_id],
      join: d in Dispatch.HaulDispatch,
      on: [asset_id: a.asset_id, timestamp: a.timestamp],
      where: at.type == "Haul Truck",
      select: %{
        id: d.id,
        group_id: d.group_id,
        asset_id: a.asset_id,
        dig_unit_id: d.dig_unit_id,
        load_location_id: d.load_location_id,
        dump_location_id: d.dump_location_id,
        server_timestamp: d.server_timestamp,
        timestamp: d.timestamp,
        activity_id: d.activity_id,
        acknowledge_id: d.acknowledge_id
      }
    )
    |> Repo.all()
  end

  @spec historic() :: list(dispatch)
  def historic(), do: Agent.get(__MODULE__, & &1.historic)

  @spec current() :: list(dispatch)
  def current(), do: Agent.get(__MODULE__, & &1.current)

  @spec get(map) :: dispatch | nil
  def get(%{asset_id: asset_id}) do
    Enum.find(current(), &(&1.asset_id == asset_id))
  end

  def get(%{id: id}) do
    Enum.find(historic(), &(&1.id == id))
  end

  @spec set(map) :: {:ok, dispatch} | {:error, term}
  def set(%{"asset_id" => _asset_id} = dispatch) do
    dispatch
    |> Helper.to_atom_map!()
    |> set()
  end

  def set(dispatch) do
    Agent.get_and_update(__MODULE__, fn state ->
      dispatch
      |> Map.put(:timestamp, Helper.to_naive(dispatch.timestamp))
      |> set(state)
    end)
  end

  def set(dispatch, state) do
    state.current
    |> Enum.find(&(&1.asset_id == dispatch.asset_id))
    |> can_insert?(dispatch)
    |> case do
      true ->
        dispatch
        |> Dispatch.HaulDispatch.new()
        |> Repo.insert()
        |> case do
          {:ok, dispatch} ->
            {dispatch, state} = update_agent(dispatch, state)
            {{:ok, dispatch}, state}

          error ->
            {error, state}
        end

      _ ->
        {{:error, :no_change}, state}
    end
  end

  @spec mass_set(list(integer), map, NaiveDateTime.t()) ::
          {:ok, list(map)} | {:error, :invalid_timestamp | term}
  def mass_set(asset_ids, dispatch, timestamp \\ NaiveDateTime.utc_now())
  def mass_set(_, _, nil), do: {:error, :invalid_timestamp}

  def mass_set(asset_ids, dispatch, timestamp) do
    dispatch = Helper.to_atom_map!(dispatch)
    server_timestamp = NaiveDateTime.utc_now()

    base_dispatch = %{
      dig_unit_id: dispatch[:dig_unit_id],
      load_location_id: dispatch[:load_location_id],
      dump_location_id: dispatch[:dump_location_id],
      timestamp: timestamp,
      server_timestamp: server_timestamp
    }

    dispatches =
      asset_ids
      |> Enum.uniq()
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&Map.put(base_dispatch, :asset_id, &1))

    Agent.get_and_update(__MODULE__, &insert_mass_dispatches(&1, dispatches))
  end

  defp insert_mass_dispatches(state, []), do: {{:ok, []}, state}

  defp insert_mass_dispatches(state, dispatches) do
    transaction =
      Multi.new()
      |> Multi.insert_all(:dispatches, Dispatch.HaulDispatch, dispatches, returning: true)
      |> Multi.run(:group_id, fn repo, %{dispatches: {_, dispatches}} ->
        ids = Enum.map(dispatches, & &1.id)
        min_id = Enum.min(ids)

        from(d in Dispatch.HaulDispatch, where: d.id in ^ids)
        |> repo.update_all(set: [group_id: min_id])
        |> case do
          {0, _} -> {:error, :failed_group_id}
          _ -> {:ok, min_id}
        end
      end)

    transaction
    |> Repo.transaction()
    |> case do
      {:ok, %{dispatches: {_, inserted}, group_id: group_id}} ->
        {dispatches, state} =
          inserted
          |> Enum.map(&Map.put(&1, :group_id, group_id))
          |> update_agent(state)

        {{:ok, dispatches}, state}

      error ->
        {error, state}
    end
  end

  @spec clear(integer) :: {:ok, dispatch} | {:error, :no_asset | term}
  def clear(asset_id) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Enum.find(state.current, &(&1.asset_id == asset_id)) do
        nil -> {{:error, :no_asset}, state}
        _ -> set(%{asset_id: asset_id, timestamp: Helper.naive_timestamp()}, state)
      end
    end)
  end

  @spec clear_dig_unit(integer) :: {:ok, list(map)} | {:error, term}
  def clear_dig_unit(dig_unit_id) do
    Agent.get_and_update(__MODULE__, fn state ->
      now = NaiveDateTime.utc_now()

      base_dispatch = %{
        dig_unit_id: nil,
        load_location_id: nil,
        dump_location_id: nil,
        timestamp: now,
        server_timestamp: now
      }

      dispatches =
        state.current
        |> Enum.filter(&(&1.dig_unit_id == dig_unit_id))
        |> Enum.map(&Map.put(base_dispatch, :asset_id, &1.asset_id))

      insert_mass_dispatches(state, dispatches)
    end)
  end

  @spec acknowledge(integer, integer, NaiveDateTime.t()) :: {:ok, dispatch} | {:error, term}
  def acknowledge(dispatch_id, device_id, timestamp) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Helper.get_by_or_nil(Repo, Dispatch.HaulDispatch, %{id: dispatch_id}) do
        nil ->
          {{:error, :invalid_id}, state}

        %{acknowledge_id: nil} = dispatch ->
          timestamp = Helper.to_naive(timestamp)

          acknowledgement =
            Dispatch.Acknowledge.new(%{device_id: device_id, timestamp: timestamp})

          Multi.new()
          |> Multi.insert(:acknowledgement, acknowledgement)
          |> Multi.run(:dispatch, fn repo, %{acknowledgement: ack} ->
            dispatch
            |> Dispatch.HaulDispatch.changeset(%{acknowledge_id: ack.id})
            |> repo.update()
          end)
          |> Repo.transaction()
          |> case do
            {:ok, %{dispatch: dispatch}} ->
              {resp, state} = update_agent(dispatch, state)
              {{:ok, resp}, state}

            error ->
              {error, state}
          end

        _ ->
          {{:error, :already_acknowledged}, state}
      end
    end)
  end

  defp update_agent([%Dispatch.HaulDispatch{} = dispatch | dispatches], state) do
    {dispatch, state} = update_agent(dispatch, state)
    {dispatches, state} = update_agent(dispatches, state)
    {[dispatch | dispatches], state}
  end

  defp update_agent([], state), do: {[], state}

  defp update_agent(%Dispatch.HaulDispatch{} = dispatch, state) do
    dispatch
    |> Dispatch.HaulDispatch.to_map()
    |> update_agent(state)
  end

  defp update_agent(dispatch, state) do
    asset_id = dispatch.asset_id

    # add to historic
    state =
      AgentHelper.override_or_add(
        state,
        :historic,
        dispatch,
        &(&1.id == dispatch.id),
        @cull_opts
      )

    state =
      state.current
      |> Enum.find(&(&1.asset_id == asset_id))
      |> is_new_current?(dispatch)
      |> case do
        true ->
          AgentHelper.override_or_add(state, :current, dispatch, &(&1.asset_id == asset_id), nil)

        _ ->
          state
      end

    {dispatch, state}
  end

  defp can_insert?(current, new) do
    is_nil(current) ||
      NaiveDateTime.compare(new[:timestamp], current[:timestamp]) != :gt ||
      new[:dig_unit_id] !== current[:dig_unit_id] ||
      new[:load_location_id] !== current[:load_location_id] ||
      new[:dump_location_id] !== current[:dump_location_id]
  end

  defp is_new_current?(nil, _), do: true

  defp is_new_current?(current, new) do
    NaiveDateTime.compare(current.timestamp, new.timestamp) != :gt
  end

  defp get_latest_query() do
    from(a in Asset,
      select: %{
        asset_id: a.id,
        asset_type_id: a.asset_type_id,
        timestamp:
          fragment(
            "SELECT
              MAX(timestamp)
            FROM dis_haul_dispatch
            WHERE asset_id = ?",
            a.id
          )
      }
    )
  end
end
