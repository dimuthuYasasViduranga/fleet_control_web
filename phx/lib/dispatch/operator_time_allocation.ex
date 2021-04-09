defmodule Dispatch.OperatorTimeAllocation do
  @moduledoc """
  Used to fetch data for, and generate operator centric time allocation information
  """

  alias Dispatch.{AssetAgent, OperatorAgent, DeviceAssignmentAgent}
  alias HpsData.Schemas.Dispatch.{TimeAllocation, TimeCode, TimeCodeGroup}
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]

  @type time_data :: %{
          start_time: NaiveDateTime.t(),
          end_time: NaiveDateTime.t(),
          assets: list(map),
          operators: list(map),
          time_allocations: list(map),
          device_assignments: list(map)
        }

  @type operator_time_allocation :: %{
          start_time: NaiveDateTime.t(),
          end_time: NaiveDateTime.t(),
          operator: map | nil,
          asset: map | nil,
          time_code: map | nil,
          time_code_group: map | nil,
          locked: boolean
        }

  @type span :: %{
          start_time: NaiveDateTime.t(),
          end_time: NaiveDateTime.t()
        }

  @type gap_range :: %{
          optional(:start_time) => NaiveDateTime.t(),
          optional(:end_time) => NaiveDateTime.t()
        }

  @spec fetch_data(NaiveDateTime.t(), NaiveDateTime.t()) :: map()
  def fetch_data(start_time, end_time) do
    assets = AssetAgent.get_assets()

    operators = OperatorAgent.all()

    time_allocations = pull_time_allocations(start_time, end_time)

    device_assignments = pull_device_assignments(start_time, end_time)

    %{
      start_time: start_time,
      end_time: end_time,
      assets: assets,
      operators: operators,
      time_allocations: time_allocations,
      device_assignments: device_assignments
    }
  end

  defp pull_time_allocations(start_time, end_time) do
    from(ta in TimeAllocation,
      where:
        (ta.start_time < ^end_time and ta.end_time > ^start_time) or
          (is_nil(ta.end_time) and ta.start_time < ^end_time),
      where: ta.deleted == false,
      join: tc in TimeCode,
      on: [id: ta.time_code_id],
      join: tcg in TimeCodeGroup,
      on: [id: tc.group_id],
      select: %{
        id: ta.id,
        asset_id: ta.asset_id,
        time_code_id: ta.time_code_id,
        time_code: tc.name,
        time_code_group: tcg.name,
        start_time: ta.start_time,
        end_time: ta.end_time,
        deleted: ta.deleted
      }
    )
    |> Repo.all()
  end

  defp pull_device_assignments(start_time, end_time) do
    DeviceAssignmentAgent.fetch_by_range!(%{start_time: start_time, end_time: end_time})
  end

  @spec build_report(time_data) :: %{
          start_time: NaiveDateTime.t(),
          end_time: NaiveDateTime.t(),
          operators: list(map),
          assets: list(map),
          data: list(operator_time_allocation)
        }
  def build_report(data) do
    start_time = data.start_time
    end_time = data.end_time

    time_allocs =
      Enum.map(data.assets, fn asset ->
        # for each asset
        # get relevant allocations

        # get relevant device assignmnets

        # convert device assignments to spans

        # add operator tags to each allocation (and split on change)
        []
      end)
      |> List.flatten()

    # remove all allocations without an operator id
    # group all allocations by operator_id
    time_alloc_lookup =
      time_allocs
      |> Enum.filter(&is_nil(&1.asset_id))
      |> Enum.group_by(& &1.operator_id)

    Enum.map(data.operators, fn operator ->
      operator_allocs =
        case time_alloc_lookup[operator.id] do
          nil ->
            []

          allocs ->
            gaps = find_gaps(allocs, %{start_time: start_time, end_time: end_time})

            [gaps] ++ allocs
        end
        |> Enum.sort_by(& &1.start_time, {:asc, NaiveDateTime})
    end)

    # for each operator
    # get allocations

    # if there is at least 1 allocation, find remaining no_asset gaps
    # this will require flattening all allocations for the operator first (because of overlaps, etc)
  end

  @doc """
  Returns a list of spans, corresponding to any gaps in the given data
  If start_time is given, gaps between start_time and first element are detected
  If end_time is given, gaps between last element and end are detected
  """
  @spec find_gaps(list(span), gap_range) :: list(span)
  def find_gaps(spans, range \\ %{})

  def find_gaps([], range) do
    case {range[:start_time], range[:end_time]} do
      {nil, _} -> []
      {_, nil} -> []
      {start_time, end_time} -> [%{start_time: start_time, end_time: end_time}]
    end
  end

  def find_gaps(spans, range) do
    flat_elements = flatten_spans(spans)

    start_time =
      [range[:start_time], List.first(flat_elements)[:start_time]]
      |> naive_min_or_max(:min)

    end_time =
      [range[:end_time], List.last(flat_elements)[:end_time]]
      |> naive_min_or_max(:max)

    (flat_elements ++ [%{start_time: end_time, end_time: end_time}])
    |> Enum.reduce({start_time, []}, fn span, {timestamp, gaps} ->
      gaps =
        case NaiveDateTime.compare(span.start_time, timestamp) do
          :eq -> gaps
          _ -> [%{start_time: timestamp, end_time: span.start_time} | gaps]
        end

      {span.end_time, gaps}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp naive_min_or_max(list, min_or_max) do
    non_nil_list = Enum.reject(list, &is_nil/1)
    apply(Enum, min_or_max, [non_nil_list, NaiveDateTime])
  end

  @doc """
  Flattens all span based elements to remove any overlaps. If there are gaps, gaps remain intact
  """
  @spec flatten_spans(list(span)) :: list(map)
  def flatten_spans([]), do: []
  def flatten_spans(spans) when length(spans) == 1, do: spans

  def flatten_spans(spans) do
    spans
    |> Enum.map(fn span -> [{span.start_time, :start, span}, {span.end_time, :end, span}] end)
    |> List.flatten()
    |> Enum.sort_by(&elem(&1, 0), {:asc, NaiveDateTime})
    |> Enum.dedup_by(fn {ts, type, _span} -> {ts, type} end)
    |> Enum.reduce({[], []}, &do_flatten_key_event/2)
    |> elem(1)
    |> Enum.reverse()
  end

  defp do_flatten_key_event({_ts, _type, span}, {[], completed}), do: {[span], completed}

  defp do_flatten_key_event(event, {[partial | other_partials] = all_partials, completed}) do
    {next_timestamp, next_type, next_span} = event

    cond do
      # if next one is a start, make a completed partial, add old partial to backlog
      next_type == :start ->
        completed_span = Map.put(partial, :end_time, next_timestamp)
        {[next_span | all_partials], [completed_span | completed]}

      # if it is the end of the current partial
      next_type == :end && NaiveDateTime.compare(partial.end_time, next_timestamp) == :eq ->
        completed_span = Map.put(partial, :end_time, next_timestamp)

        {other_partials, [completed_span | completed]}

        # move all the other partials up
        other_partials = Enum.map(other_partials, &Map.put(&1, :start_time, next_timestamp))

        {other_partials, [completed_span | completed]}

      true ->
        {all_partials, completed}
    end
  end
end
