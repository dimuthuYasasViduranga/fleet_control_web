defmodule Dispatch.PreStartSubmissionAgent do
  @moduledoc """
  Used to hold all current pre-start submission data
  """

  use Agent
  alias Dispatch.{Helper, AgentHelper}
  require Logger

  alias HpsData.Schemas.Dispatch.PreStart
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]
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
    {:ok, {submissions, forms, sections, controls}} =
      Repo.transaction(fn ->
        submissions =
          from(s in PreStart.Submission,
            distinct: s.asset_id,
            order_by: [desc: s.timestamp]
          )
          |> Repo.all()

        submission_ids = Enum.map(submissions, & &1.id)

        responses =
          from(r in PreStart.Response,
            where: r.submission_id in ^submission_ids
          )
          |> Repo.all()

        form_ids = Enum.map(submissions, & &1.form_id)

        forms =
          from(f in PreStart.Form,
            where: f.id in ^form_ids
          )
          |> Repo.all()

        sections =
          from(s in PreStart.Section,
            where: s.form_id in ^form_ids
          )
          |> Repo.all()

        section_ids = Enum.map(sections, & &1.id)

        controls =
          from(c in PreStart.Control,
            where: c.section_id in ^section_ids
          )
          |> Repo.all()
          |> Enum.map(fn c ->
            r = Enum.find(responses, %{}, &(&1.control_id == c.id))

            %{
              id: c.id,
              order: c.order,
              response_id: r.id,
              section_id: c.section_id,
              label: c.label,
              answer: r.answer,
              comment: r.comment
            }
          end)

        {submissions, forms, sections, controls}
      end)

    Enum.map(submissions, &to_submission_tree(&1, forms, sections, controls))
  end

  defp pull_submission(submission_id) do
    {:ok, {submission, forms, sections, controls}} =
      Repo.transaction(fn ->
        submission = Repo.get_by!(PreStart.Submission, %{id: submission_id})

        responses =
          from(r in PreStart.Response,
            where: r.submission_id == ^submission.id
          )
          |> Repo.all()

        forms =
          from(f in PreStart.Form,
            where: f.id == ^submission.form_id
          )
          |> Repo.all()

        sections =
          from(s in PreStart.Section,
            where: s.form_id == ^submission.form_id
          )
          |> Repo.all()

        section_ids = Enum.map(sections, & &1.id)

        controls =
          from(c in PreStart.Control,
            where: c.section_id in ^section_ids
          )
          |> Repo.all()
          |> Enum.map(fn c ->
            r = Enum.find(responses, %{}, &(&1.control_id == c.id))

            %{
              id: c.id,
              order: c.order,
              response_id: r.id,
              section_id: c.section_id,
              label: c.label,
              answer: r.answer,
              comment: r.comment
            }
          end)

        {submission, forms, sections, controls}
      end)

    to_submission_tree(submission, forms, sections, controls)
  end

  defp to_submission_tree(submission, forms, sections, controls) do
    form =
      forms
      |> Enum.find(&(&1.id == submission.form_id))
      |> to_form(sections, controls)

    %{
      id: submission.id,
      form_id: submission.form_id,
      asset_id: submission.asset_id,
      operator_id: submission.operator_id,
      employee_id: submission.employee_id,
      comment: submission.comment,
      form: form,
      timestamp: submission.timestamp,
      server_timestamp: submission.server_timestamp
    }
  end

  defp to_form(form, sections, controls) do
    sections =
      sections
      |> Enum.filter(&(&1.form_id == form.id))
      |> Enum.map(&to_section(&1, controls))
      |> Enum.sort_by(& &1.order)

    %{
      id: form.id,
      asset_type_id: form.asset_type_id,
      dispatcher_id: form.dispatcher_id,
      sections: sections,
      timestamp: form.timestamp,
      server_timestamp: form.server_timestamp
    }
  end

  defp to_section(section, controls) do
    controls =
      controls
      |> Enum.filter(&(&1.section_id == section.id))
      |> Enum.sort_by(& &1.order)

    %{
      id: section.id,
      form_id: section.form_id,
      order: section.order,
      title: section.title,
      details: section.details,
      controls: controls
    }
  end

  @spec refresh!() :: :ok
  def refresh!(), do: AgentHelper.set(__MODULE__, &init/0)

  @spec all() :: list(submission)
  def all(), do: Agent.get(__MODULE__, & &1[:current])

  @spec add(map) :: {:ok, map} | {:error, term}
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
