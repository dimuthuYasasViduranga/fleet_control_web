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

    [form_id: pre_start.id, control: control, status_types: status_types, dispatcher: dispatcher]
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
      assert PreStartSubmissionAgent.historic() == [actual]

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

  describe "add_ticket/1 -" do
    defp create_response(asset, operator, form_id, control, timestamp \\ NaiveDateTime.utc_now()) do
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
        timestamp: timestamp
      }

      {:ok, actual} = PreStartSubmissionAgent.add(submission)

      [response] = actual.responses

      {form_id, response}
    end

    test "valid", %{
      asset: asset,
      operator: op,
      dispatcher: dispatcher,
      form_id: form_id,
      control: control,
      status_types: status_types
    } do
      {_form_id, response} = create_response(asset, op, form_id, control)

      status_type = status_types["raised"]

      ticket = %{
        response_id: response.id,
        dispatcher_id: dispatcher.id,
        asset_id: asset.id,
        status_type_id: status_type,
        timestamp: NaiveDateTime.utc_now()
      }

      {:ok, actual_ticket, updated_submission} = PreStartSubmissionAgent.add_ticket(ticket)

      # return
      # ticket itself
      assert actual_ticket.id != nil
      assert actual_ticket.asset_id == asset.id
      assert actual_ticket.created_by_dispatcher_id == dispatcher.id
      assert NaiveDateTime.compare(actual_ticket.timestamp, ticket.timestamp) == :eq

      # the active status
      actual_status = actual_ticket.active_status
      assert actual_status.id != nil
      assert actual_status.ticket_id == actual_ticket.id
      assert actual_status.created_by_dispatcher_id == dispatcher.id
      assert actual_status.details == nil
      assert actual_status.reference == nil
      assert actual_status.status_type_id == status_type
      assert NaiveDateTime.compare(actual_status.timestamp, ticket.timestamp) == :eq

      # the updated submission
      assert updated_submission.id == response.submission_id

      # store
      assert PreStartSubmissionAgent.current() == [updated_submission]
      assert PreStartSubmissionAgent.historic() == [updated_submission]

      # database
      actual_response =
        updated_submission.responses
        |> List.first()
        |> Map.drop([:ticket])

      assert_db_contains(PreStart.Ticket, Map.drop(actual_ticket, [:active_status]))
      assert_db_count(PreStart.Ticket, 1)

      assert_db_contains(PreStart.TicketStatus, actual_ticket.active_status)
      assert_db_count(PreStart.TicketStatus, 1)

      assert_db_contains(PreStart.Response, actual_response)
      assert_db_count(PreStart.Response, 1)

      assert_db_contains(PreStart.Submission, Map.drop(updated_submission, [:form, :responses]))
    end

    test "invalid (invalid response id)" do
      error = PreStartSubmissionAgent.add_ticket(%{response_id: nil})
      assert error == {:error, :invalid_id}
    end
  end

  describe "update_ticket/1 -" do
    defp create_response_with_ticket(context, timestamp \\ NaiveDateTime.utc_now()) do
      response = %{
        control_id: context.control.id,
        answer: false,
        comment: nil
      }

      submission = %{
        form_id: context.form_id,
        asset_id: context.asset.id,
        operator_id: context.operator.id,
        comment: nil,
        responses: [response],
        timestamp: timestamp
      }

      {:ok, actual} = PreStartSubmissionAgent.add(submission)

      [response] = actual.responses

      status_type = context.status_types["raised"]

      ticket = %{
        response_id: response.id,
        dispatcher_id: context.dispatcher.id,
        asset_id: context.asset.id,
        status_type_id: status_type,
        timestamp: timestamp
      }

      {:ok, actual_ticket, updated_submission} = PreStartSubmissionAgent.add_ticket(ticket)

      {
        Map.put(response, :ticket_id, actual_ticket.id),
        actual_ticket,
        actual_ticket.active_status,
        updated_submission
      }
    end

    test "valid", %{status_types: status_types} = context do
      {response, ticket, ticket_status, submission} = create_response_with_ticket(context)

      status_type = status_types["pending"]
      timestamp = NaiveDateTime.utc_now()

      params = %{
        ticket_id: ticket.id,
        reference: "ref",
        details: "details",
        status_type_id: status_type,
        timestamp: timestamp
      }

      {:ok, actual_status, [updated_submission]} =
        PreStartSubmissionAgent.update_ticket_status(params)

      # return
      # new status
      assert actual_status.id != ticket_status.id
      assert actual_status.ticket_id == ticket.id
      assert actual_status.reference == "ref"
      assert actual_status.details == "details"
      assert actual_status.active == true
      assert actual_status.created_by_dispatcher_id == nil
      assert actual_status.status_type_id == status_type
      assert NaiveDateTime.compare(actual_status.timestamp, timestamp) == :eq

      # changed submission
      assert updated_submission.id == submission.id
      assert NaiveDateTime.compare(updated_submission.timestamp, submission.timestamp) == :eq

      # response
      [updated_response] = updated_submission.responses
      assert updated_response.id == response.id
      assert updated_response.ticket_id == ticket.id

      # store
      assert PreStartSubmissionAgent.current() == [updated_submission]
      assert PreStartSubmissionAgent.historic() == [updated_submission]

      # database
      assert_db_contains(PreStart.Ticket, Map.drop(ticket, [:active_status]))
      assert_db_count(PreStart.Ticket, 1)

      refute_db_contains(PreStart.TicketStatus, ticket_status)
      assert_db_contains(PreStart.TicketStatus, Map.put(ticket_status, :active, false))
      assert_db_contains(PreStart.TicketStatus, actual_status)
      assert_db_count(PreStart.TicketStatus, 2)

      assert_db_contains(PreStart.Response, Map.drop(updated_response, [:ticket]))
      assert_db_count(PreStart.Response, 1)
    end

    test "valid (ticket old - not active)", %{status_types: status_types} = context do
      old_timestamp = ~N[2000-01-01 00:00:00]

      {response, ticket, ticket_status, submission} =
        create_response_with_ticket(context, old_timestamp)

      status_type = status_types["pending"]
      status_timestamp = NaiveDateTime.add(old_timestamp, -60)

      params = %{
        ticket_id: ticket.id,
        reference: "ref",
        details: "details",
        status_type_id: status_type,
        timestamp: status_timestamp
      }

      {:ok, actual_status, affected_submissions} =
        PreStartSubmissionAgent.update_ticket_status(params)

      # return
      # new status
      assert actual_status.id != ticket_status.id
      assert actual_status.ticket_id == ticket.id
      assert actual_status.reference == "ref"
      assert actual_status.details == "details"
      assert actual_status.active == false
      assert actual_status.created_by_dispatcher_id == nil
      assert actual_status.status_type_id == status_type
      assert NaiveDateTime.compare(actual_status.timestamp, status_timestamp) == :eq

      # changed submission
      assert affected_submissions == []

      # store
      assert PreStartSubmissionAgent.current() == [submission]
      assert PreStartSubmissionAgent.historic() == []

      # database
      assert_db_contains(PreStart.Ticket, Map.drop(ticket, [:active_status]))
      assert_db_count(PreStart.Ticket, 1)

      assert_db_contains(PreStart.TicketStatus, ticket_status)
      assert_db_contains(PreStart.TicketStatus, actual_status)
      assert_db_count(PreStart.TicketStatus, 2)

      assert_db_contains(PreStart.Response, Map.drop(response, [:ticket]))
      assert_db_count(PreStart.Response, 1)
    end

    test "invalid (invalid ticket id)" do
      error = PreStartSubmissionAgent.update_ticket_status(%{ticket_id: nil})
      assert error == {:error, :invalid_id}
    end
  end
end
