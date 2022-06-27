defmodule FleetControl.EngineHoursAgent do
  use Agent

  alias FleetControl.{Helper, AgentHelper}

  require Logger
  alias HpsData.Schemas.Dispatch.EngineHours
  alias HpsData.Repo
  alias HpsData.Asset

  @cull_opts %{
    time_key: :timestamp,
    group_key: :asset_id,
    max_age: 24 * 60 * 60
  }

  import Ecto.Query, only: [from: 2, subquery: 1]

  @spec start_link(any()) :: {:ok, pid()}
  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    recent = NaiveDateTime.add(NaiveDateTime.utc_now(), -@cull_opts.max_age)

    %{
      current: pull_current(),
      historic: pull_historic(recent)
    }
  end

  defp pull_historic(recent) do
    from(eh in EngineHours,
      order_by: [desc: eh.timestamp, desc: eh.server_timestamp],
      where: eh.timestamp >= ^recent,
      select: %{
        id: eh.id,
        asset_id: eh.asset_id,
        operator_id: eh.operator_id,
        hours: eh.hours,
        timestamp: eh.timestamp,
        server_timestamp: eh.server_timestamp,
        deleted: eh.deleted
      }
    )
    |> Repo.all()
  end

  defp pull_current() do
    max_query = get_latest_query()

    from(a in subquery(max_query),
      join: eh in EngineHours,
      on: eh.asset_id == a.asset_id and eh.timestamp == a.timestamp,
      select: %{
        id: eh.id,
        asset_id: eh.asset_id,
        operator_id: eh.operator_id,
        hours: eh.hours,
        timestamp: eh.timestamp,
        server_timestamp: eh.server_timestamp,
        deleted: eh.deleted
      }
    )
    |> Repo.all()
    |> Enum.map(&{&1.asset_id, &1})
    |> Enum.into(%{})
  end

  def historic(), do: Agent.get(__MODULE__, & &1.historic)

  def current(), do: Agent.get(__MODULE__, & &1.current) |> Map.values()

  @spec get_asset(integer) :: map | nil
  def get_asset(asset_id), do: Agent.get(__MODULE__, & &1.current)[asset_id]

  @spec new(map) :: {:ok, map} | {:error, term}
  def new(%{"asset_id" => _asset_id} = engine_hours) do
    engine_hours
    |> Helper.to_atom_map!()
    |> new()
  end

  def new(engine_hours) do
    Agent.get_and_update(__MODULE__, fn state ->
      engine_hours
      |> EngineHours.new()
      |> Repo.insert()
      |> update_agent(state)
    end)
  end

  @spec fetch_by_range!(map) :: list
  def fetch_by_range!(%{start_time: start_time, end_time: end_time}) do
    first_elements = get_first_rows_by(start_time, "<")
    end_elements = get_first_rows_by(end_time, ">")

    engine_hours =
      from(eh in EngineHours,
        where: eh.timestamp >= ^start_time and eh.timestamp <= ^end_time,
        where: eh.deleted != true,
        select: %{
          id: eh.id,
          asset_id: eh.asset_id,
          operator_id: eh.operator_id,
          hours: eh.hours,
          timestamp: eh.timestamp,
          server_timestamp: eh.server_timestamp,
          deleted: eh.deleted
        }
      )
      |> Repo.all()

    first_elements ++ engine_hours ++ end_elements
  end

  defp update_agent({:ok, %EngineHours{} = engine_hours}, state) do
    engine_hours = EngineHours.to_map(engine_hours)
    update_agent({:ok, engine_hours}, state)
  end

  defp update_agent({:ok, %{asset_id: asset_id} = engine_hours}, state) do
    state =
      AgentHelper.override_or_add(
        state,
        :historic,
        engine_hours,
        &(&1.id == engine_hours.id),
        @cull_opts
      )

    state =
      if is_new?(state.current, engine_hours) do
        current = Map.put(state.current, asset_id, engine_hours)
        Map.put(state, :current, current)
      else
        state
      end

    {{:ok, engine_hours}, state}
  end

  defp update_agent(error, state), do: {error, state}

  defp is_new?(current, new) do
    case current[new.asset_id] do
      nil -> true
      engine_hours -> NaiveDateTime.compare(engine_hours.timestamp, new.timestamp) == :lt
    end
  end

  defp get_first_rows_by(timestamp, comparitor) do
    search_query = get_search_query(timestamp, comparitor)

    from(a in subquery(search_query),
      join: eh in EngineHours,
      on: eh.asset_id == a.asset_id and eh.timestamp == a.timestamp,
      select: %{
        id: eh.id,
        asset_id: eh.asset_id,
        operator_id: eh.operator_id,
        hours: eh.hours,
        timestamp: eh.timestamp,
        server_timestamp: eh.server_timestamp,
        deleted: eh.deleted
      }
    )
    |> Repo.all()
  end

  defp get_latest_query() do
    from(a in Asset,
      select: %{
        asset_id: a.id,
        timestamp:
          fragment(
            "SELECT
              MAX(timestamp)
            FROM dis_engine_hours
            WHERE asset_id = ? and deleted != true",
            a.id
          )
      }
    )
  end

  # though string interpolation would be nicer, this is the NON-sql injection way of doing it
  defp get_search_query(timestamp, ">") do
    from(a in Asset,
      select: %{
        asset_id: a.id,
        timestamp:
          fragment(
            "SELECT
              MIN(timestamp)
            FROM dis_engine_hours
            WHERE asset_id = ? and timestamp > ? and deleted != true",
            a.id,
            ^timestamp
          )
      }
    )
  end

  defp get_search_query(timestamp, "<") do
    from(a in Asset,
      select: %{
        asset_id: a.id,
        timestamp:
          fragment(
            "SELECT
              MAX(timestamp)
            FROM dis_engine_hours
            WHERE asset_id = ? and timestamp < ? and deleted != true",
            a.id,
            ^timestamp
          )
      }
    )
  end
end
