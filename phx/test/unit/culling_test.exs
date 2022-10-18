defmodule FleetControl.CullingTest do
  use ExUnit.Case
  @moduletag :unit

  alias FleetControl.Culling

  describe "add -" do
    test "single element" do
      element = %{name: "test"}
      actual = Culling.add([], element, nil)
      assert actual == [element]
    end

    test "multiple elements" do
      elements = [%{name: "test"}, %{name: "test 2"}]
      actual = Culling.add([], elements, nil)
      assert actual == elements
    end
  end

  describe "override_or_add -" do
    test "no matching, add new" do
      element = %{name: "test"}
      actual = Culling.override_or_add([], element, &(&1.name == element.name), nil)
      assert actual == [element]
    end

    test "has match, override" do
      element = %{name: "test", value: 7}
      initial = [%{name: "test", value: 6}]

      actual =
        Culling.override_or_add(
          initial,
          element,
          &(&1.name == element.name),
          nil
        )

      assert actual == [element]
    end
  end

  describe "override -" do
    test "no match, no change" do
      element = %{name: "test"}
      actual = Culling.override([], element, &(&1.name == element.name), nil)
      assert actual == []
    end

    test "match, override element" do
      element = %{name: "test", value: 7}
      initial = [%{name: "test", value: 6}]

      actual = Culling.override(initial, element, &(&1.name == element.name), nil)
      assert actual == [element]
    end
  end

  describe "culling (ensured amount) -" do
    test "by size" do
      opts = %{max_size: 5}
      expected = [7, 6, 5, 4, 3]
      initial = expected ++ [2, 1]

      actual = Culling.cull(initial, opts)

      assert actual == expected
    end

    test "by age" do
      opts = %{time_key: :timestamp, max_age: 3600}
      now = NaiveDateTime.utc_now()
      old = NaiveDateTime.add(now, -2 * opts.max_age)

      actual = Culling.cull([%{timestamp: now}, %{timestamp: old}], opts)

      assert actual == [%{timestamp: now}]
    end

    test "by group with group size" do
      opts = %{group_key: :name, max_group_size: 2}

      a1 = %{name: "a", value: 1}
      a2 = %{name: "a", value: 2}
      a3 = %{name: "a", value: 3}
      b1 = %{name: "b", value: 1}

      actual = Culling.cull([a3, a2, a1, b1], opts)

      expected = [a3, a2, b1]

      assert actual == expected
    end

    test "by group with max age" do
      opts = %{time_key: :timestamp, group_key: :name, max_age: 3600}

      now = NaiveDateTime.utc_now()
      before_now = NaiveDateTime.add(now, -60)
      old = NaiveDateTime.add(now, -2 * opts.max_age)

      a1 = %{name: "a", timestamp: now}
      a2 = %{name: "a", timestamp: old}
      b1 = %{name: "b", timestamp: before_now}

      actual = Culling.cull([a1, a2, b1], opts)
      expected = [a1, b1]

      assert actual == expected
    end
  end

  test "culls (keep 1 element outside range)" do
    max_age = 3600
    opts = %{time_key: :timestamp, max_age: {max_age, 1}}

    now = NaiveDateTime.utc_now()
    old = NaiveDateTime.add(now, -2 * max_age)

    a = %{value: 1, timestamp: now}
    b = %{value: 2, timestamp: old}
    c = %{value: 3, timestamp: NaiveDateTime.add(old, -30)}

    initial = [a, b, c]

    actual = Culling.cull(initial, opts)

    expected = [a, b]

    assert actual == expected
  end
end
