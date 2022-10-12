defmodule FleetControl.Helper.Test do
  use ExUnit.Case, async: true
  @moduletag :unit

  alias FleetControl.Helper

  defp to_span(start_time, end_time) do
    %{start_time: start_time, end_time: end_time}
  end

  describe "coverage/2 -" do
    test "unknown" do
      coverage = Helper.coverage(to_span(nil, nil), to_span(nil, nil))
      assert coverage == :unknown
    end

    test "equals" do
      span = to_span(~N[2020-01-01 00:00:00], ~N[2020-01-01 01:00:00])
      coverage = Helper.coverage(span, span)
      assert coverage == :equals
    end

    test "covers" do
      b = to_span(~N[2020-01-01 00:00:00], ~N[2020-01-02 00:00:00])
      a = to_span(NaiveDateTime.add(b.start_time, -60), NaiveDateTime.add(b.end_time, 60))
      coverage = Helper.coverage(a, b)
      assert coverage == :covers
    end

    test "within" do
      b = to_span(~N[2020-01-01 00:00:00], ~N[2020-01-02 00:00:00])
      a = to_span(NaiveDateTime.add(b.start_time, 60), NaiveDateTime.add(b.end_time, -60))
      coverage = Helper.coverage(a, b)
      assert coverage == :within
    end

    test "end_within" do
      b = to_span(~N[2020-01-01 00:00:00], ~N[2020-01-02 00:00:00])
      a = to_span(NaiveDateTime.add(b.start_time, -60), NaiveDateTime.add(b.end_time, -60))
      coverage = Helper.coverage(a, b)
      assert coverage == :end_within
    end

    test "start_within" do
      b = to_span(~N[2020-01-01 00:00:00], ~N[2020-01-02 00:00:00])
      a = to_span(NaiveDateTime.add(b.start_time, 60), NaiveDateTime.add(b.end_time, 60))
      coverage = Helper.coverage(a, b)
      assert coverage == :start_within
    end

    test "no_overlap" do
      a = to_span(~N[2020-01-01 00:00:00], ~N[2020-01-02 00:00:00])
      b = to_span(NaiveDateTime.add(a.end_time, 60), NaiveDateTime.add(a.end_time, 120))
      coverage = Helper.coverage(a, b)
      assert coverage == :no_overlap
    end
  end

  describe "to_naive/2 -" do
    test "nil" do
      actual = Helper.to_naive(nil)
      assert actual == nil
    end

    test "naive" do
      input = ~N[2020-01-01 00:00:00.123456]
      actual = Helper.to_naive(input)
      assert NaiveDateTime.compare(actual, input) == :eq
      assert actual.microsecond == input.microsecond
    end

    test "string" do
      actual = Helper.to_naive("2020-01-01T00:00:00.123456Z")
      assert NaiveDateTime.compare(actual, ~N[2020-01-01 00:00:00.123456]) == :eq
      assert actual.microsecond == {123_456, 6}
    end

    test "unix" do
      actual = Helper.to_naive(1_602_137_019_123)
      assert NaiveDateTime.compare(actual, ~N[2020-10-08 06:03:39.123000]) == :eq
      assert actual.microsecond == {123_000, 6}
    end
  end

  describe "to_unix/2 -" do
    test "nil" do
      actual = Helper.to_unix(nil)
      assert actual == nil
    end

    test "naive" do
      actual = Helper.to_unix(~N[2020-10-08 06:03:39.123000])
      assert actual == 1_602_137_019_123
    end

    test "string" do
      actual = Helper.to_unix("2020-10-08T06:03:39.123000Z")
      assert actual == 1_602_137_019_123
    end

    test "unix" do
      expected = 1_602_137_019_123
      actual = Helper.to_unix(expected)
      assert actual == 1_602_137_019_123
    end
  end

  describe "naive_to_usec/1" do
    test "change (no microseconds)" do
      input = ~N[2020-01-01 00:00:00]
      actual = Helper.naive_to_usec(input)
      assert input.microsecond == {0, 0}
      assert actual.microsecond == {0, 6}
    end

    test "not change (has microseconds)" do
      input = ~N[2020-01-01 00:00:00.123456]
      actual = Helper.naive_to_usec(input)
      assert input.microsecond == {123_456, 6}
      assert actual.microsecond == {123_456, 6}
    end
  end
end
