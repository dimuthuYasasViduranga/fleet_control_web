defmodule Dispatch.Unit.OperatorTimeAllocationTest do
  use ExUnit.Case
  @moduletag :unit

  alias Dispatch.OperatorTimeAllocation

  def to_span(start_time, end_time), do: %{start_time: start_time, end_time: end_time}

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
      # |------a------|

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

  describe "build_report/1" do
    test "no data" do
    end

    test "asset data with no operator login" do
    end
  end
end
