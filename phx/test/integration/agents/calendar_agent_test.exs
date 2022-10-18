defmodule FleetControl.CalendarAgentTest do
  use FleetControlWeb.RepoCase
  @moduletag :agent

  alias FleetControl.CalendarAgent
  alias HpsData.Dim.Calendar

  setup do
    CalendarAgent.start_link([])
    :ok
  end

  test "get shifts" do
    actual_count = CalendarAgent.shifts() |> length()
    assert actual_count > 0
  end

  test "get shift types" do
    actual_count = CalendarAgent.shift_types() |> length()
    assert actual_count == 2
  end

  describe "is current? -" do
    setup do
      [shift | _] = CalendarAgent.shifts()
      [shift: shift]
    end

    test "before shift", %{shift: shift} do
      now = ~N[1990-01-01 00:00:00.000000]
      is_current = CalendarAgent.between?(shift, now)
      assert is_current == false
    end

    test "on shift start", %{shift: shift} do
      now = shift.shift_start
      is_current = CalendarAgent.between?(shift, now)
      assert is_current == true
    end

    test "within shift", %{shift: shift} do
      now = NaiveDateTime.add(shift.shift_start, 30)
      is_current = CalendarAgent.between?(shift, now)
      assert is_current == true
    end

    test "on shift end", %{shift: shift} do
      now = shift.shift_end
      is_current = CalendarAgent.between?(shift, now)
      assert is_current == false
    end

    test "after shift", %{shift: shift} do
      now = ~N[2030-01-01 00:00:00.000000]
      is_current = CalendarAgent.between?(shift, now)
      assert is_current == false
    end
  end

  test "update!" do
    shifts = CalendarAgent.shifts()
    initial_count = length(shifts)
    [%{shift_type_id: shift_type_id} | _] = shifts

    # does not matter that the inserted calendar is wrong
    %Calendar{
      year: 0,
      quarter: 0,
      month: 0,
      day_of_month: 0,
      shift_type_id: shift_type_id,
      week_of_year: 0,
      day_of_week: 0,
      shift_start_utc: ~N[2020-01-01 00:00:00.000000],
      shift_end_utc: ~N[2020-01-01 00:00:00.000000]
    }
    |> Repo.insert!()

    CalendarAgent.refresh!()

    actual_count = CalendarAgent.shifts() |> length()

    assert actual_count == initial_count + 1
  end
end
