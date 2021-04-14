defmodule Dispatch.PreStartSubmissionAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{
    AssetAgent,
    OperatorAgent,
    DispatcherAgent,
    PreStartAgent,
    PreStartSubmissionAgent
  }

  alias HpsData.Schemas.Dispatch.PreStart

  setup_all _ do
    AssetAgent.start_link([])
    [asset | _] = AssetAgent.get_assets()

    OperatorAgent.start_link([])
    [operator | _] = OperatorAgent.active()

    [asset: asset, operator: operator]
  end

  setup tags do
    DispatcherAgent.start_link([])
    {:ok, dispatcher} = DispatcherAgent.add("abcde", "Test A")
    PreStartAgent.start_link([])

    PreStartSubmissionAgent.start_link([])

    section = %{
      "title" => "Section A",
      "controls" => [%{"label" => "Control 1"}]
    }

    {:ok, pre_start} =
      PreStartAgent.add(tags[:asset].type_id, dispatcher.id, [section], NaiveDateTime.utc_now())

    control =
      pre_start.sections
      |> List.first()
      |> Map.get(:controls)
      |> List.first()

    status_types =
      PreStartSubmissionAgent.ticket_status_types()
      |> Enum.map(&{&1.name, &1.id})
      |> Enum.into(%{})

    [form_id: pre_start.id, control: control, status_types: status_types]
  end

  describe "add/1 -" do
    test "valid", %{asset: asset, operator: op, form_id: form_id, control: control} do
      response = %{
        control_id: control.id,
        answer: nil,
        comment: "A comment"
      }

      submission = %{
        form_id: form_id,
        asset_id: asset.id,
        operator_id: op.id,
        comment: "Some comment",
        responses: [response],
        timestamp: NaiveDateTime.utc_now()
      }

      {:ok, actual} = PreStartSubmissionAgent.add(submission)

      [actual_response] = actual.responses

      # return
      assert actual.form_id == form_id
      assert actual.asset_id == asset.id
      assert actual.operator_id == op.id
      assert actual.comment == submission.comment

      assert actual_response.control_id == control.id
      assert actual_response.answer == response.answer
      assert actual_response.comment == response.comment

      # store
      assert PreStartSubmissionAgent.current() == [actual]

      # database
      assert_db_contains(PreStart.Response, Map.drop(actual_response, [:ticket]))
      assert_db_count(PreStart.Response, 1)

      ecto_submission =
        Map.take(actual, [
          :id,
          :form_id,
          :asset_id,
          :operator_id,
          :employee_id,
          :comment,
          :timestamp,
          :server_timestamp
        ])

      assert_db_contains(PreStart.Submission, ecto_submission)
      assert_db_count(PreStart.Submission, 1)
    end

    test "invalid (invalid form id)", %{asset: asset, operator: op, control: control} do
      response = %{
        control_id: control.id,
        answer: nil,
        comment: "A comment"
      }

      submission = %{
        form_id: -1,
        asset_id: asset.id,
        operator_id: op.id,
        comment: "Some comment",
        responses: [response],
        timestamp: NaiveDateTime.utc_now()
      }

      error = PreStartSubmissionAgent.add(submission)
      assert_ecto_error(error)
    end

    test "invalid (no operator identifier)", %{asset: asset, form_id: form_id, control: control} do
      response = %{
        control_id: control.id,
        answer: nil,
        comment: "A comment"
      }

      submission = %{
        form_id: form_id,
        asset_id: asset.id,
        operator_id: nil,
        employee_id: nil,
        comment: "Some comment",
        responses: [response],
        timestamp: NaiveDateTime.utc_now()
      }

      error = PreStartSubmissionAgent.add(submission)
      assert_ecto_error(error)
    end

    test "invalid (no responses)", %{asset: asset, operator: op, form_id: form_id} do
      submission = %{
        form_id: form_id,
        asset_id: asset.id,
        operator_id: op.id,
        comment: "Some comment",
        responses: [],
        timestamp: NaiveDateTime.utc_now()
      }

      error = PreStartSubmissionAgent.add(submission)
      assert error == {:error, :missing_responses}
    end

    @tag :capture_log
    test "invalid (invalid response control ids)", %{asset: asset, operator: op, form_id: form_id} do
      Process.flag(:trap_exit, true)

      response = %{
        control_id: -1,
        answer: nil,
        comment: "A comment"
      }

      submission = %{
        form_id: form_id,
        asset_id: asset.id,
        operator_id: op.id,
        comment: "Some comment",
        responses: [response],
        timestamp: NaiveDateTime.utc_now()
      }

      pid = Process.whereis(PreStartSubmissionAgent)

      catch_exit do
        PreStartSubmissionAgent.add(submission)
      end

      assert_receive {
        :EXIT,
        ^pid,
        {%Postgrex.Error{}, _stack}
      }
    end
  end

  @tag :skip
  describe "add_ticket/1 -" do
    defp create_response(asset, operator, form_id, control) do
      response = %{
        control_id: control.id,
        answer: false,
        comment: nil
      }

      submission = %{
        form_id: form_id,
        asset_id: asset.id,
        operator_id: operator.id,
        comment: nil,
        responses: [response],
        timestamp: NaiveDateTime.utc_now()
      }

      {:ok, actual} = PreStartSubmissionAgent.add(submission)

      resp_control =
        actual.form.sections
        |> List.first()
        |> Map.get(:controls)
        |> List.first()

      {form_id, resp_control}
    end

    test "valid", %{
      asset: asset,
      operator: op,
      form_id: form_id,
      control: control,
      status_types: st
    } do
      {form_id, response} = create_response(asset, op, form_id, control)

      ticket = %{
        response_id: response.id,
        dispatcher_id: nil,
        status_type_id: st["raised"],
        timestamp: NaiveDateTime.utc_now()
      }

      PreStartSubmissionAgent.add_ticket(ticket)

      # return

      # store

      # database
    end

    test "invalid (invalid response id)" do
    end

    test "" do
    end
  end

  describe "update_ticket/1 -" do
    test "valid" do
      # create form

      # submit ticket

      # add a ticket

      # update ticket
    end

    test "invalid (invalid ticket id)" do
    end
  end
end
