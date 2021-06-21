defmodule Dispatch.Unit.OperatorTimeAllocationTest do
  use ExUnit.Case
  @moduletag :unit

  alias Dispatch.OperatorTimeAllocation

  defp to_span(start_time, end_time), do: %{start_time: start_time, end_time: end_time}

  describe "flatten_spans/1 -" do
    test "no spans" do
      actual = OperatorTimeAllocation.flatten_spans([])
      assert actual == []
    end

    test "1 element" do
      span = to_span(~N[2020-01-01 00:00:00], ~N[2020-02-01 00:00:00])
      expected = [span]

      actual = OperatorTimeAllocation.flatten_spans([span])
      assert actual == expected
    end

    test "gaps between preserved" do
      a_start = ~N[2020-01-01 00:00:00]
      a_end = NaiveDateTime.add(a_start, 60)
      b_start = NaiveDateTime.add(a_end, 60)
      b_end = NaiveDateTime.add(b_start, 60)

      a = to_span(a_start, a_end)
      b = to_span(b_start, b_end)

      expected = [a, b]

      actual = OperatorTimeAllocation.flatten_spans([a, b])

      assert actual == expected
    end

    test "no overlap (end and start touching)" do
      a_start = ~N[2020-01-01 00:00:00]
      a_end = NaiveDateTime.add(a_start, 60)
      b_start = a_end
      b_end = NaiveDateTime.add(b_start, 60)

      a = to_span(a_start, a_end)
      b = to_span(b_start, b_end)

      expected = [a, b]

      actual = OperatorTimeAllocation.flatten_spans([a, b])

      assert actual == expected
    end

    test "overlap completely within" do
      # Input
      #    |---b---|
      # |------a------|
      #
      # Expected
      # |--|-------|--|

      a_start = ~N[2020-01-01 00:00:00]
      b_start = NaiveDateTime.add(a_start, 60)
      b_end = NaiveDateTime.add(b_start, 60)
      a_end = NaiveDateTime.add(b_end, 60)

      a = to_span(a_start, a_end)
      b = to_span(b_start, b_end)

      expected = [
        to_span(a_start, b_start),
        b,
        to_span(b_end, a_end)
      ]

      actual = OperatorTimeAllocation.flatten_spans([a, b])

      assert actual == expected
    end

    test "start within, end outside" do
      # Input
      #    |-----b-----|
      # |-----a-----|
      #
      # Expected
      # |-a|-----b-----|

      a_start = ~N[2020-01-01 00:00:00]
      b_start = NaiveDateTime.add(a_start, 60)
      a_end = NaiveDateTime.add(b_start, 60)
      b_end = NaiveDateTime.add(a_end, 60)

      a = to_span(a_start, a_end)
      b = to_span(b_start, b_end)

      expected = [
        to_span(a_start, b_start),
        b
      ]

      actual = OperatorTimeAllocation.flatten_spans([a, b])

      assert actual == expected
    end

    test "multiple overlaps on one elemnt" do
      # Input
      #      |-----c------|
      #   |-----b------|
      # |-----a------|
      #
      # Expected
      # |a-|b-|----c------|

      a_start = ~N[2020-01-01 00:00:00]
      b_start = NaiveDateTime.add(a_start, 60)
      c_start = NaiveDateTime.add(b_start, 60)
      a_end = NaiveDateTime.add(c_start, 60)
      b_end = NaiveDateTime.add(a_end, 60)
      c_end = NaiveDateTime.add(b_end, 60)

      a = to_span(a_start, a_end)
      b = to_span(b_start, b_end)
      c = to_span(c_start, c_end)

      expected = [
        to_span(a_start, b_start),
        to_span(b_start, c_start),
        c
      ]

      actual = OperatorTimeAllocation.flatten_spans([a, b, c])

      assert actual == expected
    end

    test "one elements overlaps 2 others with gaps" do
      # Input
      #  |-------- a ----------|
      #      |-b-|     |-c-|
      #
      # Expected
      #  |-a-|-b-|--a--|-c-|-a-|

      a_start = ~N[2020-01-01 00:00:00]
      b_start = NaiveDateTime.add(a_start, 60)
      b_end = NaiveDateTime.add(b_start, 60)
      c_start = NaiveDateTime.add(b_end, 60)
      c_end = NaiveDateTime.add(c_start, 60)
      a_end = NaiveDateTime.add(c_end, 60)

      a = to_span(a_start, a_end)
      b = to_span(b_start, b_end)
      c = to_span(c_start, c_end)

      expected = [
        to_span(a_start, b_start),
        to_span(b_start, b_end),
        to_span(b_end, c_start),
        to_span(c_start, c_end),
        to_span(c_end, a_end)
      ]

      actual = OperatorTimeAllocation.flatten_spans([a, b, c])

      assert actual == expected
    end

    test "equal sized elements" do
      start_time = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(start_time, 60)

      a = to_span(start_time, end_time)

      expected = [a]

      actual = OperatorTimeAllocation.flatten_spans([a, a])

      assert actual == expected
    end

    test "zero duration elements" do
      a_start = ~N[2020-01-01 00:00:00]
      a_end = a_start
      b_start = a_end
      b_end = NaiveDateTime.add(b_start, 60)
      c_start = b_end
      c_end = c_start

      a = to_span(a_start, a_end)
      b = to_span(b_start, b_end)
      c = to_span(c_start, c_end)

      expected = [a, b, c]

      actual = OperatorTimeAllocation.flatten_spans([a, b, c])

      assert actual == expected
    end
  end

  describe "find_gaps/2 (start and end) -" do
    test "0 elements" do
      actual = OperatorTimeAllocation.find_gaps([])
      assert actual == []
    end

    test "element within range" do
      range_start = ~N[2020-01-01 00:00:00]
      a_start = NaiveDateTime.add(range_start, 60)
      a_end = NaiveDateTime.add(a_start, 60)
      range_end = NaiveDateTime.add(a_end, 60)

      a = to_span(a_start, a_end)
      actual = OperatorTimeAllocation.find_gaps([a], to_span(range_start, range_end))

      expected = [
        to_span(range_start, a_start),
        to_span(a_end, range_end)
      ]

      assert actual == expected
    end

    test "element equal to range" do
      range_start = ~N[2020-01-01 00:00:00]
      range_end = NaiveDateTime.add(range_start, 60)

      a = to_span(range_start, range_end)
      actual = OperatorTimeAllocation.find_gaps([a], to_span(range_start, range_end))

      assert actual == []
    end

    test "element bigger than range" do
      a_start = ~N[2020-01-01 00:00:00]
      range_start = NaiveDateTime.add(a_start, 60)
      range_end = NaiveDateTime.add(range_start, 60)
      a_end = NaiveDateTime.add(range_end, 60)

      a = to_span(a_start, a_end)
      actual = OperatorTimeAllocation.find_gaps([a], to_span(range_start, range_end))

      assert actual == []
    end

    test "gap between elements" do
      # Input
      # |---a---|      |---b---|
      #
      # Expected
      #         |------|

      range_start = ~N[2020-01-01 00:00:00]
      a_end = NaiveDateTime.add(range_start, 60)
      b_start = NaiveDateTime.add(a_end, 60)
      range_end = NaiveDateTime.add(b_start, 60)

      a = to_span(range_start, a_end)
      b = to_span(b_start, range_end)

      expected = [
        to_span(a_end, b_start)
      ]

      actual = OperatorTimeAllocation.find_gaps([a, b], to_span(range_start, range_end))

      assert actual == expected
    end
  end

  describe "find_gaps/2 (only start) -" do
    test "0 elements" do
      actual = OperatorTimeAllocation.find_gaps([])
      assert actual == []
    end

    test "element within range" do
      range_start = ~N[2020-01-01 00:00:00]
      a_start = NaiveDateTime.add(range_start, 60)
      a_end = NaiveDateTime.add(a_start, 60)

      a = to_span(a_start, a_end)
      actual = OperatorTimeAllocation.find_gaps([a], to_span(range_start, nil))

      expected = [
        to_span(range_start, a_start)
      ]

      assert actual == expected
    end

    test "element equal to range" do
      range_start = ~N[2020-01-01 00:00:00]
      a_end = NaiveDateTime.add(range_start, 60)

      a = to_span(range_start, a_end)
      actual = OperatorTimeAllocation.find_gaps([a], to_span(range_start, nil))

      assert actual == []
    end

    test "element bigger than range" do
      a_start = ~N[2020-01-01 00:00:00]
      range_start = NaiveDateTime.add(a_start, 60)
      a_end = NaiveDateTime.add(range_start, 60)

      a = to_span(a_start, a_end)
      actual = OperatorTimeAllocation.find_gaps([a], to_span(range_start, nil))

      assert actual == []
    end

    test "gap between elements" do
      # Input
      # |---a---|      |---b---|
      #
      # Expected
      #         |------|

      range_start = ~N[2020-01-01 00:00:00]
      a_end = NaiveDateTime.add(range_start, 60)
      b_start = NaiveDateTime.add(a_end, 60)
      b_end = NaiveDateTime.add(b_start, 60)

      a = to_span(range_start, a_end)
      b = to_span(b_start, b_end)

      expected = [
        to_span(a_end, b_start)
      ]

      actual = OperatorTimeAllocation.find_gaps([a, b], to_span(range_start, nil))

      assert actual == expected
    end
  end

  describe "find_gaps/2 (only end) -" do
    test "0 elements" do
      actual = OperatorTimeAllocation.find_gaps([])
      assert actual == []
    end

    test "element within range" do
      a_start = ~N[2020-01-01 00:00:00]
      a_end = NaiveDateTime.add(a_start, 60)
      range_end = NaiveDateTime.add(a_end, 60)

      a = to_span(a_start, a_end)
      actual = OperatorTimeAllocation.find_gaps([a], to_span(nil, range_end))

      expected = [
        to_span(a_end, range_end)
      ]

      assert actual == expected
    end

    test "element equal to range" do
      a_start = ~N[2020-01-01 00:00:00]
      range_end = NaiveDateTime.add(a_start, 60)

      a = to_span(a_start, range_end)
      actual = OperatorTimeAllocation.find_gaps([a], to_span(nil, range_end))

      assert actual == []
    end

    test "element bigger than range" do
      a_start = ~N[2020-01-01 00:00:00]
      range_end = NaiveDateTime.add(a_start, 60)
      a_end = NaiveDateTime.add(range_end, 60)

      a = to_span(a_start, a_end)
      actual = OperatorTimeAllocation.find_gaps([a], to_span(nil, range_end))

      assert actual == []
    end

    test "gap between elements" do
      # Input
      # |---a---|      |---b---|
      #
      # Expected
      #         |------|

      a_start = ~N[2020-01-01 00:00:00]
      a_end = NaiveDateTime.add(a_start, 60)
      b_start = NaiveDateTime.add(a_end, 60)
      range_end = NaiveDateTime.add(b_start, 60)

      a = to_span(a_start, a_end)
      b = to_span(b_start, range_end)

      expected = [
        to_span(a_end, b_start)
      ]

      actual = OperatorTimeAllocation.find_gaps([a, b], to_span(nil, range_end))

      assert actual == expected
    end
  end

  describe "find_gaps/2 (no start or end)" do
    test "0 elements" do
      actual = OperatorTimeAllocation.find_gaps([])
      assert actual == []
    end

    test "1 element" do
      a_start = ~N[2020-01-01 00:00:00]
      a_end = NaiveDateTime.add(a_start, 60)

      a = to_span(a_start, a_end)
      actual = OperatorTimeAllocation.find_gaps([a])

      assert actual == []
    end

    test "gap between elements" do
      # Input
      # |---a---|      |---b---|
      #
      # Expected
      #         |------|

      a_start = ~N[2020-01-01 00:00:00]
      a_end = NaiveDateTime.add(a_start, 60)
      b_start = NaiveDateTime.add(a_end, 60)
      b_end = NaiveDateTime.add(b_start, 60)

      a = to_span(a_start, a_end)
      b = to_span(b_start, b_end)

      expected = [
        to_span(a_end, b_start)
      ]

      actual = OperatorTimeAllocation.find_gaps([a, b])

      assert actual == expected
    end
  end

  describe "split_span_by/2 -" do
    test "no splitters" do
      timestamp = ~N[2021-01-01 00:00:00]
      a = to_span(timestamp, NaiveDateTime.add(timestamp, 60))

      actual = OperatorTimeAllocation.split_span_by(a, [])

      assert actual == []
    end

    test "splitter has no overlap" do
      a_start = ~N[2020-01-01 00:00:00]
      a_end = NaiveDateTime.add(a_start, 60)
      s_start = NaiveDateTime.add(a_end, 60)
      s_end = NaiveDateTime.add(s_start, 60)

      a = to_span(a_start, a_end)
      s = to_span(s_start, s_end)

      actual = OperatorTimeAllocation.split_span_by(a, [s])

      assert actual == []
    end

    test "splitter equal" do
      a_start = ~N[2020-01-01 00:00:00]
      a_end = NaiveDateTime.add(a_start, 60)

      a = to_span(a_start, a_end)
      s = to_span(a_start, a_end)

      expected = [
        {a, s}
      ]

      actual = OperatorTimeAllocation.split_span_by(a, [s])

      assert actual == expected
    end

    test "splitter covers" do
      s_start = ~N[2020-01-01 00:00:00]
      a_start = NaiveDateTime.add(s_start, 60)
      a_end = NaiveDateTime.add(a_start, 60)
      s_end = NaiveDateTime.add(a_end, 60)

      a = to_span(a_start, a_end)
      s = to_span(s_start, s_end)

      expected = [
        {a, s}
      ]

      actual = OperatorTimeAllocation.split_span_by(a, [s])

      assert actual == expected
    end

    test "splitter within" do
      a_start = ~N[2020-01-01 00:00:00]
      s_start = NaiveDateTime.add(a_start, 60)
      s_end = NaiveDateTime.add(s_start, 60)
      a_end = NaiveDateTime.add(s_end, 60)

      a = to_span(a_start, a_end)
      s = to_span(s_start, s_end)

      expected = [
        {to_span(s_start, s_end), s}
      ]

      actual = OperatorTimeAllocation.split_span_by(a, [s])

      assert actual == expected
    end

    test "splitter ends in" do
      s_start = ~N[2020-01-01 00:00:00]
      a_start = NaiveDateTime.add(s_start, 60)
      s_end = NaiveDateTime.add(a_start, 60)
      a_end = NaiveDateTime.add(s_end, 60)

      a = to_span(a_start, a_end)
      s = to_span(s_start, s_end)

      expected = [
        {to_span(a_start, s_end), s}
      ]

      actual = OperatorTimeAllocation.split_span_by(a, [s])

      assert actual == expected
    end

    test "splitter starts in" do
      a_start = ~N[2020-01-01 00:00:00]
      s_start = NaiveDateTime.add(a_start, 60)
      a_end = NaiveDateTime.add(s_start, 60)
      s_end = NaiveDateTime.add(a_end, 60)

      a = to_span(a_start, a_end)
      s = to_span(s_start, s_end)

      expected = [
        {to_span(s_start, a_end), s}
      ]

      actual = OperatorTimeAllocation.split_span_by(a, [s])

      assert actual == expected
    end
  end

  describe "point_in_time_to_spans/2 -" do
    test "no data" do
      actual = OperatorTimeAllocation.point_in_time_to_spans([])
      assert actual == []
    end

    test "1 point (no end time)" do
      point = %{timestamp: ~N[2020-01-01 00:00:00]}
      actual = OperatorTimeAllocation.point_in_time_to_spans([point])

      assert actual == []
    end

    test "1 point (end time)" do
      timestamp = ~N[2020-01-01 00:00:00]
      end_time = NaiveDateTime.add(timestamp, 60)

      point = %{timestamp: timestamp}

      expected = [%{start_time: timestamp, end_time: end_time}]

      actual = OperatorTimeAllocation.point_in_time_to_spans([point], end_time)

      assert actual == expected
    end

    test "1 point (end of time before start)" do
      end_time = ~N[2020-01-01 00:00:00]
      timestamp = NaiveDateTime.add(end_time, 60)

      point = %{timestamp: timestamp}

      actual = OperatorTimeAllocation.point_in_time_to_spans([point], end_time)

      assert actual == []
    end

    test "2 points (no end time)" do
      ts_a = ~N[2020-01-01 00:00:00]
      ts_b = NaiveDateTime.add(ts_a, 60)
      end_time = NaiveDateTime.add(ts_b, 60)

      input = [
        %{timestamp: ts_a},
        %{timestamp: ts_b}
      ]

      expected = [
        %{start_time: ts_a, end_time: ts_b},
        %{start_time: ts_b, end_time: end_time}
      ]

      actual = OperatorTimeAllocation.point_in_time_to_spans(input, end_time)

      assert actual == expected
    end

    test "2 equal points (no end time)" do
      timestamp = ~N[2020-01-01 00:00:00]

      input = [
        %{timestamp: timestamp},
        %{timestamp: timestamp}
      ]

      expected = [
        %{start_time: timestamp, end_time: timestamp}
      ]

      actual = OperatorTimeAllocation.point_in_time_to_spans(input)

      assert actual == expected
    end

    test "2 points (end time before range)" do
      end_time = ~N[2020-01-01 00:00:00]
      ts_a = NaiveDateTime.add(end_time, 60)
      ts_b = NaiveDateTime.add(ts_a, 60)

      input = [
        %{timestamp: ts_a},
        %{timestamp: ts_b}
      ]

      expected = [
        %{start_time: ts_a, end_time: ts_b}
      ]

      actual = OperatorTimeAllocation.point_in_time_to_spans(input, end_time)

      assert actual == expected
    end
  end

  describe "remove_assignment_overlaps/1" do
    test "0 elements" do
      assert OperatorTimeAllocation.remove_assignment_overlaps([]) == []
    end

    test "1 element" do
      a = ~N[2021-01-01 00:00:00]
      b = NaiveDateTime.add(a, 60)
      span = to_span(a, b)

      assert OperatorTimeAllocation.remove_assignment_overlaps([span]) == [span]
    end

    test "2 elements (no overlap with gap)" do
      # input     |-------|       |-------|
      #
      # expected  |-------|       |-------|
      #
      #
      # TS        A       B       C       D
      #           +0      +1      +2      +3

      a = ~N[2021-01-01 00:00:00]
      b = NaiveDateTime.add(a, 60)
      c = NaiveDateTime.add(b, 60)
      d = NaiveDateTime.add(c, 60)

      spans = [
        to_span(a, b),
        to_span(c, d)
      ]

      assert OperatorTimeAllocation.remove_assignment_overlaps(spans) == spans
    end

    test "2 elements (no overlap adjacent)" do
      # input     |-------|-------|
      #
      # expected  |-------|-------|
      #
      #
      # TS        A       B       C
      #           +0      +1      +2

      a = ~N[2021-01-01 00:00:00]
      b = NaiveDateTime.add(a, 60)
      c = NaiveDateTime.add(b, 60)

      spans = [
        to_span(a, b),
        to_span(b, c)
      ]

      assert OperatorTimeAllocation.remove_assignment_overlaps(spans) == spans
    end

    test "2 elements (completely covered)" do
      # input     |-----------------------|
      #                   |-------|
      #
      # expected  |-------|-------|
      #
      #
      # TS        A       B       C       D
      #           +0      +1      +2      +3

      a = ~N[2021-01-01 00:00:00]
      b = NaiveDateTime.add(a, 60)
      c = NaiveDateTime.add(b, 60)
      d = NaiveDateTime.add(c, 60)

      spans = [
        to_span(a, d),
        to_span(b, c)
      ]

      expected = [
        to_span(a, b),
        to_span(b, c)
      ]

      assert OperatorTimeAllocation.remove_assignment_overlaps(spans) == expected
    end

    test "2 elements (start inside, end outside)" do
      # input             |---------------|
      #           |---------------|
      #
      # expected  |-------|---------------|
      #
      #
      # TS        A       B       C       D
      #           +0      +1      +2      +3

      a = ~N[2021-01-01 00:00:00]
      b = NaiveDateTime.add(a, 60)
      c = NaiveDateTime.add(b, 60)
      d = NaiveDateTime.add(c, 60)

      spans = [
        to_span(a, c),
        to_span(b, d)
      ]

      expected = [
        to_span(a, b),
        to_span(b, d)
      ]

      assert OperatorTimeAllocation.remove_assignment_overlaps(spans) == expected
    end

    test "2 elements (equal)" do
      # input     |-------|
      #           |-------|
      #
      # expected  |-------|
      #
      # TS        A       B
      #           +0      +1

      a = ~N[2021-01-01 00:00:00]
      b = NaiveDateTime.add(a, 60)

      spans = [
        to_span(a, b),
        to_span(a, b)
      ]

      expected = [
        to_span(a, b)
      ]

      assert OperatorTimeAllocation.remove_assignment_overlaps(spans) == expected
    end
  end

  describe "create_operator_allocations/1 -" do
    defp to_alloc(asset, start_time, end_time, data) do
      %{
        asset_id: asset[:id],
        start_time: start_time,
        end_time: end_time,
        data: data
      }
    end

    defp to_assignment(asset, operator, timestamp) do
      %{
        asset_id: asset[:id],
        operator_id: operator[:id],
        timestamp: timestamp
      }
    end

    test "no data" do
      start_time = ~N[2020-01-01 00:00:00]

      data = %{
        start_time: start_time,
        end_time: NaiveDateTime.add(start_time, 60),
        assets: [],
        operators: [],
        time_allocations: [],
        device_assignments: []
      }

      actual = OperatorTimeAllocation.create_operator_allocations(data)

      assert actual == []
    end

    test "1 asset (no op, op, no op)" do
      # Asset Allocs
      #         |-----T1-----|-----T2-----|-----T3-----|
      #
      # Device Assignments
      #         |------------|------------|
      # asset:  A            A            A
      # op:     -            O            -
      #
      # Expected (operator, asset, TC)
      #         | (O, -, -)  | (O, A, T2) |  (O, -, -) |
      asset = %{id: "Asset"}
      operator = %{id: "Person"}

      start_time = ~N[2020-01-01 00:00:00]
      login = NaiveDateTime.add(start_time, 60)
      logout = NaiveDateTime.add(login, 60)
      end_time = NaiveDateTime.add(logout, 60)

      asset_time_allocs = [
        to_alloc(asset, start_time, login, "Standby"),
        to_alloc(asset, login, logout, "Ready"),
        to_alloc(asset, logout, end_time, "MEM")
      ]

      assignments = [
        to_assignment(asset, nil, start_time),
        to_assignment(asset, operator, login),
        to_assignment(asset, nil, logout)
      ]

      data = %{
        start_time: start_time,
        end_time: end_time,
        assets: [asset],
        operators: [operator],
        time_allocations: asset_time_allocs,
        device_assignments: assignments
      }

      expected = [
        %{
          start_time: start_time,
          end_time: login,
          operator_id: operator.id,
          asset_id: nil
        },
        %{
          start_time: login,
          end_time: logout,
          operator_id: operator.id,
          asset_id: asset.id,
          data: "Ready"
        },
        %{
          start_time: logout,
          end_time: end_time,
          operator_id: operator.id,
          asset_id: nil
        }
      ]

      actual = OperatorTimeAllocation.create_operator_allocations(data)

      assert actual == expected
    end

    test "asset data with no operator login" do
      # Asset Allocs
      #         |-----T1-----|-----T2-----|-----T3-----|
      #
      # Expected
      #         Nothing
      asset = %{id: "Asset"}
      operator = %{id: "Person"}

      start_time = ~N[2020-01-01 00:00:00]
      ts_a = NaiveDateTime.add(start_time, 60)
      ts_b = NaiveDateTime.add(ts_a, 60)
      end_time = NaiveDateTime.add(ts_b, 60)

      asset_time_allocs = [
        to_alloc(asset, start_time, ts_a, "Standby"),
        to_alloc(asset, ts_a, ts_b, "Ready"),
        to_alloc(asset, ts_a, end_time, "MEM")
      ]

      data = %{
        start_time: start_time,
        end_time: end_time,
        assets: [asset],
        operators: [operator],
        time_allocations: asset_time_allocs,
        device_assignments: []
      }

      actual = OperatorTimeAllocation.create_operator_allocations(data)

      assert actual == []
    end

    test "assignments with no asset allocations" do
      # Asset Allocs
      #         |                                     |
      #
      # Device Assignments
      #         |------------|------------|
      # asset:  A            A            A
      # op:     -            O            -
      #
      # Expected (operator, asset, TC)
      #         | (O, -, -)  | (O, A, -) |  (O, -, -) |
      asset = %{id: "Asset"}
      operator = %{id: "Person"}

      start_time = ~N[2020-01-01 00:00:00]
      login = NaiveDateTime.add(start_time, 60)
      logout = NaiveDateTime.add(login, 60)
      end_time = NaiveDateTime.add(logout, 60)

      assignments = [
        to_assignment(asset, nil, start_time),
        to_assignment(asset, operator, login),
        to_assignment(asset, nil, logout)
      ]

      data = %{
        start_time: start_time,
        end_time: end_time,
        assets: [asset],
        operators: [operator],
        time_allocations: [],
        device_assignments: assignments
      }

      expected = [
        %{
          start_time: start_time,
          end_time: login,
          operator_id: operator.id,
          asset_id: nil
        },
        %{
          start_time: login,
          end_time: logout,
          operator_id: operator.id,
          asset_id: asset.id
        },
        %{
          start_time: logout,
          end_time: end_time,
          operator_id: operator.id,
          asset_id: nil
        }
      ]

      actual = OperatorTimeAllocation.create_operator_allocations(data)

      assert actual == expected
    end

    test "time allocation longer than log in period" do
      # Asset 1 (A1)
      # TA      |     TA1     |                   TA2                   |
      # Op      |             |      X      |             |     X       |
      #
      # ts      A             B             C             D             E
      #         +0            +1            +2            +3            +4
      #
      # Expected
      #         |  (O, -, -)  |(O, A1, TA2) |  (O, -, -)  | (O, A1, TA2) |
      asset = %{id: "Asset"}
      operator = %{id: "Person"}

      a = ~N[2020-01-01 00:00:00]
      b = NaiveDateTime.add(a, 60)
      c = NaiveDateTime.add(b, 60)
      d = NaiveDateTime.add(c, 60)
      e = NaiveDateTime.add(d, 60)

      assignments = [
        to_assignment(asset, nil, a),
        to_assignment(asset, operator, b),
        to_assignment(asset, nil, c),
        to_assignment(asset, operator, d)
      ]

      ta1 = to_alloc(asset, a, b, "TA1")
      ta2 = to_alloc(asset, b, e, "TA2")

      allocations = [ta1, ta2]

      data = %{
        start_time: a,
        end_time: e,
        assets: [asset],
        operators: [operator],
        time_allocations: allocations,
        device_assignments: assignments
      }

      expected = [
        %{
          start_time: a,
          end_time: b,
          operator_id: operator.id,
          asset_id: nil
        },
        %{
          start_time: b,
          end_time: c,
          data: ta2.data,
          operator_id: operator.id,
          asset_id: asset.id
        },
        %{
          start_time: c,
          end_time: d,
          operator_id: operator.id,
          asset_id: nil
        },
        %{
          start_time: d,
          end_time: e,
          data: ta2.data,
          operator_id: operator.id,
          asset_id: asset.id
        }
      ]

      actual = OperatorTimeAllocation.create_operator_allocations(data)

      assert actual == expected
    end

    test "logout of asset after login to another" do
      # This is a case only seen due to a desyn in device clocks that are then submitted to
      # the server

      # Asset 1
      # TC        |------TA1------|------TA2------|
      # O         |   x           |               |
      #
      # Asset 2
      # TC        |--TB1--|------TB2------|--TB3--|
      # O         |       |       x       |       |
      #

      # expected
      # asset     |   1   |       2       |   -   |
      # TA        |  TA1  |      TB2      |   -   |
      # O         |   O   |       O       |   -   |

      # TS        A       B       C       D       E
      #           +0      +1      +2      +3      +4

      asset_1 = %{id: "Asset 1"}
      asset_2 = %{id: "Asset 2"}
      operator = %{id: "Person"}

      a = ~N[2020-01-01 00:00:00]
      b = NaiveDateTime.add(a, 60)
      c = NaiveDateTime.add(b, 60)
      d = NaiveDateTime.add(c, 60)
      e = NaiveDateTime.add(d, 60)

      assignments = [
        to_assignment(asset_1, operator, a),
        to_assignment(asset_2, operator, b),
        to_assignment(asset_1, nil, c),
        to_assignment(asset_2, nil, d)
      ]

      ta1 = to_alloc(asset_1, a, c, "1 - Dig Ore")
      ta2 = to_alloc(asset_1, c, e, "1 - Not Required")
      tb1 = to_alloc(asset_2, a, b, "2 - Not Required")
      tb2 = to_alloc(asset_2, b, d, "2 - Hauling ore")
      tb3 = to_alloc(asset_2, d, e, "2 - Not Required")

      allocations = [ta1, ta2, tb1, tb2, tb3]

      data = %{
        start_time: a,
        end_time: e,
        assets: [asset_1, asset_2],
        operators: [operator],
        time_allocations: allocations,
        device_assignments: assignments
      }

      expected = [
        %{
          start_time: a,
          end_time: b,
          data: ta1.data,
          operator_id: operator.id,
          asset_id: asset_1.id
        },
        %{
          start_time: b,
          end_time: d,
          data: tb2.data,
          operator_id: operator.id,
          asset_id: asset_2.id
        },
        %{
          start_time: d,
          end_time: e,
          operator_id: operator.id,
          asset_id: nil
        }
      ]

      actual = OperatorTimeAllocation.create_operator_allocations(data)

      assert actual == expected
    end
  end

  test "logout of asset after login to another (old login overing)" do
    # This is a case only seen due to a desyn in device clocks that are then submitted to
    # the server

    # Asset 1
    # TC        |--------------TA1--------------|
    # O         |               x               |
    #
    # Asset 2
    # TC        |--TB1--|------TB2------|--TB3--|
    # O         |       |       x       |       |
    #

    # expected
    # asset     |   1   |       2       |   -   |
    # TA        |  TA1  |      TB2      |   -   |
    # O         |   O   |       O       |   -   |

    # TS        A       B       C       D       E
    #           +0      +1      +2      +3      +4

    asset_1 = %{id: "Asset 1"}
    asset_2 = %{id: "Asset 2"}
    operator = %{id: "Person"}

    a = ~N[2020-01-01 00:00:00]
    b = NaiveDateTime.add(a, 60)
    c = NaiveDateTime.add(b, 60)
    d = NaiveDateTime.add(c, 60)
    e = NaiveDateTime.add(d, 60)

    assignments = [
      to_assignment(asset_1, operator, a),
      to_assignment(asset_2, operator, b),
      to_assignment(asset_1, nil, e),
      to_assignment(asset_2, nil, d)
    ]

    ta1 = to_alloc(asset_1, a, e, "1 - Dig Ore")
    tb1 = to_alloc(asset_2, a, b, "2 - Not Required")
    tb2 = to_alloc(asset_2, b, d, "2 - Hauling ore")
    tb3 = to_alloc(asset_2, d, e, "2 - Not Required")

    allocations = [ta1, tb1, tb2, tb3]

    data = %{
      start_time: a,
      end_time: e,
      assets: [asset_1, asset_2],
      operators: [operator],
      time_allocations: allocations,
      device_assignments: assignments
    }

    expected = [
      %{
        start_time: a,
        end_time: b,
        data: ta1.data,
        operator_id: operator.id,
        asset_id: asset_1.id
      },
      %{
        start_time: b,
        end_time: d,
        data: tb2.data,
        operator_id: operator.id,
        asset_id: asset_2.id
      },
      %{
        start_time: d,
        end_time: e,
        operator_id: operator.id,
        asset_id: nil
      }
    ]

    actual = OperatorTimeAllocation.create_operator_allocations(data)

    assert actual == expected
  end
end
