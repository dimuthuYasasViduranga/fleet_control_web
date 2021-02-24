defmodule Dispatch.PreStartSubmissionAgent.Data do
  alias HpsData.Schemas.Dispatch.PreStart
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]

  @type submission :: map()
  @type form :: map()
  @type section :: map()
  @type control :: map()
  @type response :: map()

  @spec get_latest_submissions() ::
          {list(submission), list(form), list(section), list(control), list(response)}
  def get_latest_submissions() do
    {:ok, return} =
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

        {submissions, forms, sections, controls, responses}
      end)

    return
  end

  @spec get_submission(integer) ::
          {submission, list(form), list(section), list(control), list(response)}
  def get_submission(submission_id) do
    {:ok, return} =
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

        {submission, forms, sections, controls, responses}
      end)

    return
  end

  @spec get_submissions_between(NaiveDateTime.t(), NaiveDateTime.t()) ::
          {list(submission), list(form), list(section), list(control), list(response)}
  def get_submissions_between(start_time, end_time) do
    {:ok, return} =
      Repo.transaction(fn ->
        submissions =
          from(s in PreStart.Submission,
            where: s.timestamp >= ^start_time and s.timestamp < ^end_time
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

        {submissions, forms, sections, controls, responses}
      end)

    return
  end
end
