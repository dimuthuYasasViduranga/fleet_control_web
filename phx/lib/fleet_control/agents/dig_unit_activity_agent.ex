defmodule FleetControl.DigUnitActivityAgent do
  @moduledoc """
  Holds all the actions for a dig unit
  """

  use Agent

  require Logger

  alias FleetControl.{Helper, AgentHelper}
  alias HpsData.Repo
  alias HpsData.Schemas.Dispatch.DigUnitActivity
  alias HpsData.{Asset, AssetType}

  import Ecto.Query, only: [from: 2, subquery: 1]
  alias Ecto.Multi

  @type activity :: map

  @cull_opts %{
    time_key: :timestamp,
    max_age: 12 * 60 * 60,
    group_key: :asset_id
  }

  @dig_unit_types ["Excavator", "Loader"]

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    %{
      historic: get_historic_activities(),
      current: get_current_activities()
    }
  end

  defp get_historic_activities() do
    now = Helper.naive_timestamp()
    recent = NaiveDateTime.add(now, -@cull_opts.max_age, :second)

    from(d in DigUnitActivity,
      where: d.timestamp > ^recent,
      select: %{
        id: d.id,
        asset_id: d.asset_id,
        location_id: d.location_id,
        material_type_id: d.material_type_id,
        load_style_id: d.load_style_id,
        group_id: d.group_id,
        timestamp: d.timestamp,
        server_timestamp: d.server_timestamp
      }
    )
    |> Repo.all()
  end

  defp get_current_activities() do
    max_query = get_latest_query()

    from(md in subquery(max_query),
      join: a in Asset,
      on: [id: md.asset_id],
      join: at in AssetType,
      on: [id: a.asset_type_id],
      join: d in DigUnitActivity,
      on: [asset_id: md.asset_id, timestamp: md.timestamp],
      where: at.type in ^@dig_unit_types,
      select: %{
        id: d.id,
        asset_id: a.id,
        location_id: d.location_id,
        material_type_id: d.material_type_id,
        load_style_id: d.load_style_id,
        group_id: d.group_id,
        timestamp: d.timestamp,
        server_timestamp: d.server_timestamp
      }
    )
    |> Repo.all()
  end

  @spec historic() :: list(activity)
  def historic(), do: Agent.get(__MODULE__, & &1.historic)

  @spec current() :: list(activity)
  def current(), do: Agent.get(__MODULE__, & &1.current)

  @spec get(map) :: activity | nil
  def get(%{asset_id: asset_id}) do
    Enum.find(current(), &(&1.asset_id == asset_id))
  end

  def get(%{id: id}) do
    Enum.find(historic(), &(&1.id == id))
  end

  @spec add(%{
          asset_id: integer,
          location_id: integer | nil,
          material_type_id: integer | nil,
          load_style_id: integer | nil,
          timestamp: NaiveDateTime.t() | integer
        }) :: {:ok, activity} | {:error, term}
  def add(%{"asset_id" => _} = activity) do
    activity
    |> Helper.to_atom_map!()
    |> add()
  end

  def add(activity), do: Agent.get_and_update(__MODULE__, &add(activity, &1))

  def add(activity, state) do
    activity
    |> DigUnitActivity.new()
    |> Repo.insert()
    |> update_agent(state)
  end

  @spec clear(integer) :: {:ok, activity} | {:error, :no_asset | term}
  def clear(asset_id) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Enum.find(state.current, &(&1.asset_id == asset_id)) do
        nil ->
          {{:error, :no_asset}, state}

        _ ->
          add(
            %{
              asset_id: asset_id,
              location_id: nil,
              material_type_id: nil,
              load_style_id: nil,
              timestamp: Helper.naive_timestamp()
            },
            state
          )
      end
    end)
  end

  @spec mass_set(list(integer), map, NaiveDateTime.t()) ::
          {:ok, list(map)} | {:error, :invalid_timestamp | term}
  def mass_set(asset_ids, activity, timestamp \\ NaiveDateTime.utc_now())
  def mass_set(_, _, nil), do: {:error, :invalid_timestamp}

  def mass_set(asset_ids, activity, timestamp) do
    activity = Helper.to_atom_map!(activity)
    server_timestamp = NaiveDateTime.utc_now()

    base_activity = %{
      location_id: activity.location_id,
      material_type_id: activity.material_type_id,
      load_style_id: activity.load_style_id,
      timestamp: timestamp,
      server_timestamp: server_timestamp
    }

    asset_ids
    |> Enum.uniq()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&Map.put(base_activity, :asset_id, &1))
    |> insert_mass_activities()
  end

  defp insert_mass_activities([]), do: {:ok, []}

  defp insert_mass_activities(activities) do
    transaction =
      Multi.new()
      |> Multi.insert_all(:activities, DigUnitActivity, activities, returning: true)
      |> Multi.run(:group_id, fn repo, %{activities: {_, activities}} ->
        ids = Enum.map(activities, & &1.id)
        min_id = Enum.min(ids)

        from(a in DigUnitActivity, where: a.id in ^ids)
        |> repo.update_all(set: [group_id: min_id])
        |> case do
          {0, _} -> {:error, :failed_group_id}
          _ -> {:ok, min_id}
        end
      end)

    Agent.get_and_update(__MODULE__, fn state ->
      transaction
      |> Repo.transaction()
      |> case do
        {:ok, %{activities: {_, inserted}, group_id: group_id}} ->
          {activities, state} =
            inserted
            |> Enum.map(&Map.put(&1, :group_id, group_id))
            |> update_agent(state)

          {{:ok, activities}, state}

        error ->
          {error, state}
      end
    end)
  end

  defp update_agent([%DigUnitActivity{} = activity | activities], state) do
    {{:ok, activity}, state} = update_agent({:ok, activity}, state)
    {activities, state} = update_agent(activities, state)
    {[activity | activities], state}
  end

  defp update_agent([], state), do: {[], state}

  defp update_agent({:ok, %DigUnitActivity{} = activity}, state) do
    activity = DigUnitActivity.to_map(activity)
    update_agent({:ok, activity}, state)
  end

  defp update_agent({:ok, activity}, state) do
    # add to historic
    state =
      AgentHelper.override_or_add(
        state,
        :historic,
        activity,
        &(&1.id == activity.id),
        @cull_opts
      )

    # set as current if required
    state =
      if should_be_current?(state.current, activity) do
        AgentHelper.override_or_add(
          state,
          :current,
          activity,
          &(&1.asset_id == activity.asset_id),
          nil
        )
      else
        state
      end

    resp = {:ok, activity}
    {resp, state}
  end

  defp update_agent(error, state), do: {error, state}

  defp should_be_current?(current_activities, proposed) do
    current_activities
    |> Enum.find(&(&1.asset_id == proposed.asset_id))
    |> Access.get(:timestamp)
    |> case do
      nil -> true
      old_timestamp -> NaiveDateTime.compare(old_timestamp, proposed.timestamp) == :lt
    end
  end

  defp get_latest_query() do
    from(d in DigUnitActivity,
      group_by: d.asset_id,
      select: %{
        asset_id: d.asset_id,
        timestamp: max(d.timestamp)
      }
    )
  end
end
