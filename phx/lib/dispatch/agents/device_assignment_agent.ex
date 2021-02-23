defmodule Dispatch.DeviceAssignmentAgent do
  @moduledoc """
  Holds both the current assignments and a transient history of assignments
  There is no guarentee that historic contains the current assignment, due to some
    current assignments being older than the transient history limit
  """

  alias Dispatch.{Helper, AgentHelper}
  use Agent
  import Ecto.Query, only: [from: 2, subquery: 1]
  import Ecto.Query.API, only: [map: 2]

  alias HpsData.Repo
  alias HpsData.Schemas.Dispatch.DeviceAssignment
  alias HpsData.Asset

  @cull_opts %{
    time_key: :timestamp,
    max_age: {12 * 60 * 60, 1},
    group_key: :asset_id
  }

  @select_data_keys [
    :id,
    :asset_id,
    :device_id,
    :operator_id,
    :timestamp,
    :server_timestamp
  ]

  @type assignment :: map

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    %{
      historic: historic_assignments(),
      current: current_assignments()
    }
  end

  defmacrop select_data(q) do
    quote do
      map(unquote(q), @select_data_keys)
    end
  end

  defp historic_assignments() do
    {max_age, _} = @cull_opts.max_age
    now = NaiveDateTime.utc_now()
    recent = NaiveDateTime.add(now, -max_age, :second)
    fetch_by_range!(%{start_time: recent, end_time: now})
  end

  defp current_assignments() do
    max_query = get_latest_query()

    from(a in subquery(max_query),
      join: da in DeviceAssignment,
      on: da.asset_id == a.asset_id and da.timestamp == a.timestamp,
      order_by: [desc: a.asset_id, desc: da.timestamp],
      select: select_data(da)
    )
    |> Repo.all()
    |> Enum.map(&{&1.asset_id, &1})
    |> Enum.into(%{})
  end

  @doc """
  Returns all device_assignments within the specified range, plus 1 on either side of
  the range to ensure interpolation is possible
  """
  @spec fetch_by_range!(map) :: list
  def fetch_by_range!(%{start_time: start_time, end_time: end_time}) do
    first_elements = get_first_rows_by(start_time, "<")
    end_elements = get_first_rows_by(end_time, ">")

    assignments =
      from(da in DeviceAssignment,
        where: da.timestamp >= ^start_time and da.timestamp <= ^end_time,
        select: select_data(da)
      )
      |> Repo.all()

    first_elements ++ assignments ++ end_elements
  end

  @spec historic() :: list(assignment)
  def historic(), do: Agent.get(__MODULE__, & &1.historic)

  @spec current() :: list(assignment)
  def current() do
    Agent.get(__MODULE__, & &1.current)
    |> Map.values()
  end

  @spec get(map) :: assignment | nil
  def get(%{device_id: id}), do: Enum.find(current(), &(&1.device_id == id))
  def get(%{asset_id: id}), do: Enum.find(current(), &(&1.asset_id == id))
  def get(%{operator_id: id}), do: Enum.find(current(), &(&1.operator_id == id))

  @spec get_asset_id(map) :: integer | nil
  def get_asset_id(props), do: get(props)[:asset_id]

  @spec new(map) :: {:ok, assignment} | {:error, term}
  def new(%{"asset_id" => _asset_id} = assignment) do
    assignment
    |> Helper.to_atom_map!()
    |> new()
  end

  def new(assignment) do
    assignment
    |> DeviceAssignment.new()
    |> insert()
  end

  @spec change(integer, map) :: {:ok, assignment} | {:error, term}
  def change(asset_id, change) do
    Agent.get_and_update(__MODULE__, &change(&1, asset_id, change))
  end

  def change(state, asset_id, change) do
    case state.current[asset_id] do
      nil ->
        change
        |> Map.merge(%{asset_id: asset_id})
        |> Map.put_new(:timestamp, Helper.naive_timestamp())
        |> DeviceAssignment.new()
        |> insert(state)

      assignment ->
        change =
          change
          |> Map.drop([:asset_id])
          |> Map.put_new(:timestamp, Helper.naive_timestamp())

        assignment
        |> DeviceAssignment.new()
        |> DeviceAssignment.changeset(change)
        |> insert(state)
    end
  end

  @spec clear_operators(list(integer)) :: {:ok, list(assignment)} | {:error, term}
  def clear_operators([]), do: {:ok, []}

  def clear_operators(asset_ids) do
    Agent.get_and_update(__MODULE__, fn state ->
      now = NaiveDateTime.utc_now()

      entries =
        state.current
        |> Map.values()
        |> Enum.filter(&Enum.member?(asset_ids, &1.asset_id))
        |> Enum.map(
          &%{
            device_id: &1.device_id,
            asset_id: &1.asset_id,
            operator_id: nil,
            timestamp: now,
            server_timestamp: now
          }
        )

      {new_state, assigns} =
        DeviceAssignment
        |> Repo.insert_all(entries, returning: true)
        |> elem(1)
        |> Enum.reduce({state, []}, fn assign, {state, assigns} ->
          {{:ok, new_assign}, state} = update_state(assign, state)
          {state, [new_assign | assigns]}
        end)

      {{:ok, assigns}, new_state}
    end)
  end

  @spec clear(integer) :: {:ok, assignment} | {:error, term}
  def clear(asset_id) do
    %{asset_id: asset_id, timestamp: Helper.naive_timestamp()}
    |> DeviceAssignment.new()
    |> insert()
  end

  defp insert(struct_or_changeset) do
    Agent.get_and_update(__MODULE__, &insert(struct_or_changeset, &1))
  end

  defp insert(struct_or_changeset, state) do
    struct_or_changeset
    |> Repo.insert()
    |> case do
      {:ok, new_assignment} ->
        update_state(new_assignment, state)

      error ->
        {error, state}
    end
  end

  defp update_state(%DeviceAssignment{} = assignment, state) do
    update_state(DeviceAssignment.to_map(assignment), state)
  end

  defp update_state(assignment, state) do
    # add assignment to historic
    state = AgentHelper.add(state, :historic, assignment, @cull_opts)

    # set as current if required
    case is_new_current?(assignment, state.current[assignment.asset_id]) do
      true ->
        current_assigns = Map.put(state.current, assignment.asset_id, assignment)
        state = Map.put(state, :current, current_assigns)
        {{:ok, assignment}, state}

      _ ->
        {{:ok, assignment}, state}
    end
  end

  defp is_new_current?(_new_assignment, nil), do: true

  defp is_new_current?(_new_assignment, %{timestamp: nil}), do: true

  defp is_new_current?(new_assignment, %{timestamp: timestamp}) do
    NaiveDateTime.compare(new_assignment.timestamp, timestamp) == :gt
  end

  defp get_first_rows_by(timestamp, comparitor) do
    search_query = get_search_query(timestamp, comparitor)

    from(a in subquery(search_query),
      join: da in DeviceAssignment,
      on: da.asset_id == a.asset_id and da.timestamp == a.timestamp,
      select: select_data(da)
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
              FROM dis_device_assignment
              WHERE asset_id = ?",
            a.id
          )
      }
    )
  end

  defp get_search_query(timestamp, ">") do
    from(a in Asset,
      select: %{
        asset_id: a.id,
        timestamp:
          fragment(
            "SELECT
                MIN(timestamp)
              FROM dis_device_assignment
              WHERE asset_id = ? and timestamp > ?",
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
              FROM dis_device_assignment
              WHERE asset_id = ? and timestamp < ?",
            a.id,
            ^timestamp
          )
      }
    )
  end
end
