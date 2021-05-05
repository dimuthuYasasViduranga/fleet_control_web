defmodule Dispatch.PreStartAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{AssetAgent, PreStartAgent, DispatcherAgent}
  alias HpsData.Schemas.Dispatch.PreStart

  setup_all _ do
    AssetAgent.start_link([])
    [type_a, type_b | _] = AssetAgent.get_types()

    [type_a: type_a.id, type_b: type_b.id]
  end

  setup _ do
    PreStartAgent.start_link([])
    DispatcherAgent.start_link([])
    {:ok, dispatcher} = DispatcherAgent.add("abcde", "Test A")
    [dispatcher: dispatcher.id]
  end

  defp to_section(title, details, controls) do
    %{
      "title" => title,
      "details" => details,
      "controls" => Enum.map(controls, &%{"label" => &1})
    }
  end

  defp assert_form(actual, asset_type_id, dispatcher_id, sections, timestamp) do
    assert actual.asset_type_id == asset_type_id
    assert actual.dispatcher_id == dispatcher_id
    assert NaiveDateTime.compare(actual.timestamp, timestamp) == :eq

    actual_section_count = length(actual.sections)
    expected_section_count = length(sections)

    if actual_section_count != expected_section_count do
      raise ExUnit.AssertionError,
        message: "Section counts are not equal",
        left: actual_section_count,
        right: expected_section_count
    end

    actual.sections
    |> Enum.zip(sections)
    |> Enum.each(fn {actual, expected} -> assert_section(actual, expected) end)
  end

  defp assert_section(actual, expected) do
    assert actual.title == expected["title"]
    assert actual.details == expected["details"]

    actual_control_count = length(actual.controls)
    expected_control_count = length(expected["controls"])

    if actual_control_count != expected_control_count do
      raise ExUnit.AssertionError,
        message: "Control counts are not equal",
        left: actual_control_count,
        right: expected_control_count
    end

    actual.controls
    |> Enum.zip(expected["controls"])
    |> Enum.each(fn {actual, expected} -> assert_control(actual, expected) end)
  end

  defp assert_control(actual, expected) do
    assert actual.label == expected["label"]
  end

  defp assert_form_in_database(form) do
    ecto_form = %{
      id: form.id,
      asset_type_id: form.asset_type_id,
      dispatcher_id: form.dispatcher_id,
      timestamp: form.timestamp,
      server_timestamp: form.server_timestamp
    }

    assert_db_contains(PreStart.Form, ecto_form)

    {sections, controls} =
      form.sections
      |> Enum.reduce({[], []}, fn s, {sections, all_controls} ->
        section = %{
          id: s.id,
          form_id: s.form_id,
          title: s.title,
          details: s.details,
          order: s.order
        }

        controls =
          Enum.map(s.controls, fn c ->
            %{
              id: c.id,
              section_id: c.section_id,
              label: c.label,
              order: c.order,
              requires_comment: c[:requires_comment],
              category_id: c[:category_id]
            }
          end)

        {[section | sections], all_controls ++ controls}
      end)

    assert_db_contains(PreStart.Section, sections)
    assert_db_contains(PreStart.Control, controls)
  end

  describe "add/4 -" do
    test "valid", %{type_a: type, dispatcher: disp} do
      section = to_section("Section A", nil, ["Control 1"])
      timestamp = NaiveDateTime.utc_now()

      {:ok, actual} = PreStartAgent.add(type, disp, [section], timestamp)

      # return
      assert_form(actual, type, disp, [section], timestamp)

      # store
      assert PreStartAgent.all() == [actual]

      # database
      assert_form_in_database(actual)
      assert_db_count(PreStart.Form, 1)
    end

    test "valid (no contamination)", %{type_a: type_a, type_b: type_b, dispatcher: disp} do
      section_a = to_section("Section A", nil, ["Control A"])
      section_b = to_section("Section B", "details", ["Control B", "Control C"])

      timestamp_b = NaiveDateTime.utc_now()
      timestamp_a = NaiveDateTime.add(timestamp_b, -3600)

      {:ok, actual_a} = PreStartAgent.add(type_a, disp, [section_a], timestamp_a)
      {:ok, actual_b} = PreStartAgent.add(type_b, disp, [section_b], timestamp_b)

      # return
      assert_form(actual_a, type_a, disp, [section_a], timestamp_a)
      assert_form(actual_b, type_b, disp, [section_b], timestamp_b)

      # store
      assert PreStartAgent.all() == [actual_b, actual_a]

      # database
      assert_form_in_database(actual_a)
      assert_form_in_database(actual_b)
      assert_db_count(PreStart.Form, 2)
    end

    test "invalid (no dispatcher id)", %{type_a: type} do
      section = to_section("Section A", nil, ["C1", "C2"])
      error = PreStartAgent.add(type, nil, [section], NaiveDateTime.utc_now())
      assert_ecto_error(error)
    end

    test "invalid (no sections)", %{type_a: type, dispatcher: disp} do
      error = PreStartAgent.add(type, disp, [], NaiveDateTime.utc_now())
      assert error == {:error, :missing_sections}
    end

    test "invalid (no controls)", %{type_a: type, dispatcher: disp} do
      section = to_section("Section A", nil, [])
      error = PreStartAgent.add(type, disp, [section], NaiveDateTime.utc_now())
      assert error == {:error, :missing_section_controls}
    end

    test "invalid (no timestamp)", %{type_a: type, dispatcher: disp} do
      section = to_section("Section A", nil, ["C1"])
      error = PreStartAgent.add(type, disp, [section], nil)
      assert_ecto_error(error)
    end

    test "invalid (nil asset type)", %{dispatcher: disp} do
      section = to_section("Section A", nil, ["C1"])
      error = PreStartAgent.add(nil, disp, [section], NaiveDateTime.utc_now())
      assert error == {:error, :invalid_asset_type}
    end

    test "invalid (invalid asset type)", %{dispatcher: disp} do
      section = to_section("Section A", nil, ["C1"])
      error = PreStartAgent.add(-1, disp, [section], NaiveDateTime.utc_now())
      assert_ecto_error(error)
    end

    test "invalid (malformed section)", %{type_a: type, dispatcher: disp} do
      section =
        to_section("Section A", nil, ["C1"])
        |> Map.drop(["title"])
        |> Map.put("time", 7)

      error = PreStartAgent.add(type, disp, [section], NaiveDateTime.utc_now())

      assert error == {:error, :missing_section_title}
    end

    test "invalid (malformed control)", %{type_a: type, dispatcher: disp} do
      section =
        to_section("Section A", nil, [])
        |> Map.put("controls", [%{"title" => "a title"}])

      error = PreStartAgent.add(type, disp, [section], NaiveDateTime.utc_now())

      assert error == {:error, :missing_control_label}
    end
  end

  describe "update_categories/1 -" do
    test "valid (all new)" do
      input = %{name: "A", action: "B", order: 0}

      {:ok, [actual]} = PreStartAgent.update_categories([input])

      # return
      assert actual.id != nil
      assert actual.name == input.name
      assert actual.action == input.action
      assert actual.order == input.order

      # store
      assert PreStartAgent.categories() == [actual]

      # database
      assert_db_contains(PreStart.ControlCategory, actual)
      assert_db_count(PreStart.ControlCategory, 1)
    end

    test "valid (no changes)" do
      {:ok, [original]} = PreStartAgent.update_categories([%{name: "A", action: "B", order: 0}])

      {:ok, [actual]} = PreStartAgent.update_categories([original])

      # return
      assert actual == original

      # store
      assert PreStartAgent.categories() == [original]

      # database
      assert_db_contains(PreStart.ControlCategory, original)
      assert_db_count(PreStart.ControlCategory, 1)
    end

    test "valid (update)" do
      {:ok, [original]} = PreStartAgent.update_categories([%{name: "A", action: "B", order: 0}])

      input = Map.put(original, :name, "Apple")
      {:ok, [actual]} = PreStartAgent.update_categories([input])

      # return
      assert actual == input

      # store
      assert PreStartAgent.categories() == [input]

      # database
      assert_db_contains(PreStart.ControlCategory, input)
      assert_db_count(PreStart.ControlCategory, 1)
    end

    test "invalid (missing elements)" do
      {:ok, [original]} = PreStartAgent.update_categories([%{name: "A", action: "B", order: 0}])

      input = %{id: -1, name: "B", action: "C", order: -1}
      error = PreStartAgent.update_categories([input])

      assert error == {:error, :invalid_ids}
    end

    test "invalid (invalid id for update)" do
      {:ok, [original]} = PreStartAgent.update_categories([%{name: "A", action: "B", order: 0}])

      input = %{id: -1, name: "B", action: "C", order: -1}
      error = PreStartAgent.update_categories([input, original])

      assert error == {:error, :invalid_ids}
    end

    @tag :capture_log
    test "invalid (malformed category)" do
      Process.flag(:trap_exit, true)
      input = %{no_keys: 27}

      pid = Process.whereis(PreStartAgent)

      catch_exit do
        PreStartAgent.update_categories([input])
      end

      assert_receive {
        :EXIT,
        ^pid,
        {%ArgumentError{}, _stack}
      }
    end
  end

  describe "refresh!/0 -" do
    test "valid", %{type_a: type, dispatcher: disp} do
      section = to_section("Section A", nil, ["C1"])
      {:ok, actual} = PreStartAgent.add(type, disp, [section], NaiveDateTime.utc_now())

      assert PreStartAgent.all() == [actual]

      PreStartAgent.refresh!()

      assert PreStartAgent.all() == [actual]
    end
  end
end
