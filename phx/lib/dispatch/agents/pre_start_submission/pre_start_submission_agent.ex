defmodule Dispatch.PreStartSubmissionAgent do
  @moduledoc """
  Used to hold all current pre-start submission data
  """

  use Agent
  alias Dispatch.{Helper, AgentHelper}
  require Logger

  alias __MODULE__.{Data, Reshape}
  alias HpsData.Schemas.Dispatch.PreStart
  alias HpsData.Repo

  alias Ecto.Multi

  @type control :: %{
          id: integer,
          response_id: integer,
          section_id: integer,
          order: integer,
          label: String.t(),
          answer: boolean | nil,
          comment: String.t() | nil
        }

  @type section :: %{
          id: integer,
          form_id: integer,
          order: integer,
          title: String.t(),
          details: String.t() | nil,
          controls: list(control)
        }

  @type form :: %{
          id: integer,
          dispatcher_id: integer,
          asset_type_id: integer,
          sections: list(section),
          timestamp: NaiveDateTime.t(),
          server_timestamp: NaiveDateTime.t()
        }

  @type submission :: %{
          id: integer,
          form_id: integer,
          asset_id: integer,
          operator_id: integer | nil,
          employee_id: String.t() | nil,
          comment: String.t() | nil,
          form: form,
          timestamp: NaiveDateTime.t(),
          server_timestamp: NaiveDateTime.t()
        }

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init(), do: %{current: pull_latest_submissions()}

  defp pull_latest_submissions() do
    {submissions, forms, sections, controls, responses} = Data.get_latest_submissions()
    Enum.map(submissions, &Reshape.to_submission_tree(&1, forms, sections, controls, responses))
  end

  defp pull_submission(submission_id) do
    {submission, forms, sections, controls, responses} = Data.get_submission(submission_id)
    Reshape.to_submission_tree(submission, forms, sections, controls, responses)
  end

  @spec refresh!() :: :ok
  def refresh!(), do: AgentHelper.set(__MODULE__, &init/0)

  @spec all() :: list(submission)
  def all(), do: Agent.get(__MODULE__, & &1[:current])

  @spec get_between(NaiveDateTime.t(), NaiveDateTime.t()) :: list(submission)
  def get_between(start_time, end_time) do
    {submissions, forms, sections, controls, responses} =
      Data.get_submissions_between(start_time, end_time)

    Enum.map(submissions, &Reshape.to_submission_tree(&1, forms, sections, controls, responses))
  end

  @spec add(map) :: {:ok, submission} | {:error, term}
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

  def add(raw_submission) do
    Agent.get_and_update(__MODULE__, fn state ->
      raw_submission
      |> insert_submission()
      |> case do
        {:ok, %{submission: submission}} ->
          complete_submission = pull_submission(submission.id)

          state =
            case can_store_submission?(
                   state.current,
                   complete_submission.asset_id,
                   complete_submission.timestamp
                 ) do
              true ->
                AgentHelper.override_or_add(
                  state,
                  :current,
                  complete_submission,
                  &(&1.asset_id == complete_submission.asset_id),
                  nil
                )

              false ->
                state
            end

          {{:ok, complete_submission}, state}

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
        comment: raw_sub.comment,
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
        NaiveDateTime.compare(new_timestamp, current_timestamp) == :gt

      _ ->
        true
    end
  end
end
