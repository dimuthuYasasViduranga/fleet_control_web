defmodule Dispatch.PreStartSubmissionAgent do
  @moduledoc """
  Used to hold all current pre-start submission data
  """

  use Agent
  alias Dispatch.{Helper, AgentHelper}
  require Logger

  alias __MODULE__.Data
  alias HpsData.Schemas.Dispatch.PreStart
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi

  @type ticket_status_type :: %{
          id: integer,
          name: String.t(),
          alias: String.t() | nil
        }

  @type submission :: %{
          id: integer,
          form_id: integer,
          form: form,
          asset_id: integer,
          operator_id: integer | nil,
          employee_id: String.t() | nil,
          comment: String.t(),
          responses: list(response),
          timestamp: NaiveDateTime.t(),
          server_timestamp: NaiveDateTime.t()
        }

  @type form :: %{
          id: integer,
          asset_type_id: integer,
          dispatcher_id: integer,
          sections: list(section),
          timestamp: NaiveDateTime.t(),
          server_timestamp: NaiveDateTime.t()
        }

  @type section :: %{
          id: integer,
          form_id: integer,
          order: integer,
          title: String.t(),
          details: String.t(),
          controls: list(control)
        }

  @type control :: %{
          id: integer,
          section_id: integer,
          order: integer,
          label: String.t()
        }

  @type response :: %{
          id: integer,
          submission_id: integer,
          control_id: integer,
          answer: boolean | nil,
          comment: String.t(),
          ticket_id: integer,
          ticket: ticket | nil
        }

  @type ticket :: %{
          id: integer,
          asset_id: integer,
          created_by_dispatcher_id: integer,
          active_status: ticket_status,
          timestamp: NaiveDateTime.t(),
          server_timestamp: NaiveDateTime.t()
        }

  @type ticket_status :: %{
          id: integer,
          ticket_id: integer,
          reference: String.t(),
          details: String.t(),
          created_by_dispatcher_id: integer | nil,
          status_type_id: integer,
          active: true,
          timestamp: NaiveDateTime.t(),
          server_timestamp: NaiveDateTime.t()
        }

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  def init() do
    %{
      current: Data.pull_latest_submissions(),
      ticket_status_types: Data.pull_ticket_status_types()
    }
  end

  @spec refresh!() :: :ok
  def refresh!(), do: AgentHelper.set(__MODULE__, &init/0)

  @spec current() :: list()
  def current(), do: Agent.get(__MODULE__, & &1[:current])

  @spec ticket_status_types() :: list(ticket_status_type)
  def ticket_status_types(), do: Agent.get(__MODULE__, & &1[:ticket_status_types])

  @spec get_between(NaiveDateTime.t(), NaiveDateTime.t()) :: list()
  def get_between(start_time, end_time), do: Data.pull_submissions_between(start_time, end_time)

  @spec add(map) :: {:ok, submission} | {:error, :missing_responess | term}
  def add(%{"form_id" => _} = submission) do
    %{
      form_id: submission["form_id"],
      asset_id: submission["asset_id"],
      operator_id: submission["operator_id"],
      employee_id: submission["employee_id"],
      comment: submission["comment"],
      responses:
        Enum.map(submission["responses"] || [], fn r ->
          %{
            control_id: r["control_id"],
            answer: r["answer"],
            comment: r["comment"]
          }
        end),
      timestamp: Helper.to_naive(submission["timestamp"])
    }
    |> add()
  end

  def add(%{responses: []}), do: {:error, :missing_responses}

  def add(raw_submission) do
    Agent.get_and_update(__MODULE__, fn
      state ->
        raw_submission
        |> insert_submission()
        |> case do
          {:ok, %{submission: submission}} ->
            submission = Data.pull_submission(submission.id)

            state =
              case can_store_submission?(state.current, submission.asset_id, submission.timestamp) do
                true ->
                  AgentHelper.override_or_add(
                    state,
                    :current,
                    submission,
                    &(&1.asset_id == submission.asset_id),
                    nil
                  )

                _ ->
                  state
              end

            {{:ok, submission}, state}

          error ->
            {error, state}
        end
    end)
  end

  defp insert_submission(raw_sub) do
    ecto_submission =
      PreStart.Submission.new(%{
        form_id: raw_sub.form_id,
        asset_id: raw_sub.asset_id,
        operator_id: raw_sub.operator_id,
        employee_id: raw_sub[:employee_id],
        comment: raw_sub[:comment],
        timestamp: raw_sub.timestamp
      })

    Multi.new()
    |> Multi.insert(:submission, ecto_submission)
    |> Multi.run(:responses, fn repo, %{submission: submission} ->
      ecto_responses =
        Enum.map(raw_sub.responses, fn r ->
          %{
            submission_id: submission.id,
            control_id: r.control_id,
            answer: r.answer,
            comment: r.comment
          }
        end)

      repo.insert_all(PreStart.Response, ecto_responses, returning: true)
      |> case do
        {0, _} -> {:error, :failed_responses_to_submission}
        {_, responses} -> {:ok, responses}
      end
    end)
    |> Repo.transaction()
  end

  defp can_store_submission?(submissions, asset_id, new_timestamp) do
    submissions
    |> Enum.find(&(&1.asset_id == asset_id))
    |> case do
      %{timestamp: current_timestamp} ->
        NaiveDateTime.compare(new_timestamp, current_timestamp) != :lt

      _ ->
        true
    end
  end

  @spec add_ticket(map) :: {:ok, ticket, submission} | {:error, :invalid_id | term}
  def add_ticket(raw_params) do
    params = Helper.to_atom_map!(raw_params)

    Helper.get_by_or_nil(Repo, PreStart.Response, %{id: raw_params[:response_id]})
    |> case do
      nil ->
        {:error, :invalid_id}

      response ->
        Agent.get_and_update(__MODULE__, fn state ->
          case insert_ticket(response.id, params) do
            {:ok, _data} ->
              submission = Data.pull_submission(response.submission_id)

              state =
                case can_store_submission?(
                       state.current,
                       submission.asset_id,
                       submission.timestamp
                     ) do
                  true ->
                    AgentHelper.override_or_add(
                      state,
                      :current,
                      submission,
                      &(&1.asset_id == submission.asset_id),
                      nil
                    )

                  _ ->
                    state
                end

              # get ticket
              ticket = Enum.find(submission.response, &(&1.id == response.id))

              {{:ok, ticket, submission}, state}

            error ->
              {error, state}
          end
        end)
    end
  end

  defp insert_ticket(response_id, params) do
    now = NaiveDateTime.utc_now()

    ecto_ticket =
      %{
        asset_id: params.asset_id,
        created_by_dispatcher_id: params[:dispatcher_id],
        timestamp: params.timestamp,
        server_timestamp: now
      }
      |> PreStart.Ticket.new()

    Multi.new()
    |> Multi.insert(:ticket, ecto_ticket)
    |> Multi.run(:status, fn repo, %{ticket: ticket} ->
      from(ts in PreStart.TicketStatus, where: ts.ticket_id == ^ticket.id)
      |> repo.update_all(set: [active: false])

      %{
        ticket_id: ticket.id,
        reference: params[:reference],
        details: params[:details],
        created_by_dispatcher_id: params[:dispatcher_id],
        status_type_id: params[:status_type_id],
        active: true,
        timestamp: params.timestamp,
        server_timestamp: now
      }
      |> PreStart.TicketStatus.new()
      |> repo.insert()
    end)
    |> Multi.run(:update_response, fn repo, %{ticket: ticket} ->
      repo.get(response_id)
      |> PreStart.Response.changeset(%{ticket_id: ticket.id})
      |> repo.update()
    end)
    |> Repo.transaction()
  end

  @spec update_ticket(map) :: {:ok, ticket, submission} | {:error, :invalid_id | term}
  def update_ticket(raw_params) do
    params = Helper.to_atom_map!(raw_params)
  end
end
