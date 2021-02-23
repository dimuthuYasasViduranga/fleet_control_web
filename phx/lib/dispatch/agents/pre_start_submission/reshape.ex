defmodule Dispatch.PreStartSubmissionAgent.Reshape do
  @type submission :: map()
  @type form :: map()
  @type section :: map()
  @type control :: map()
  @type response :: map()

  @spec to_submission_tree(submission, list(form), list(section), list(control), list(response)) ::
          map()
  def to_submission_tree(submission, forms, sections, controls, responses) do
    responses = Enum.filter(responses, &(&1.submission_id == submission.id))

    form =
      forms
      |> Enum.find(&(&1.id == submission.form_id))
      |> to_form(sections, controls, responses)

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

  defp to_form(form, sections, controls, responses) do
    sections =
      sections
      |> Enum.filter(&(&1.form_id == form.id))
      |> Enum.map(&to_section(&1, controls, responses))
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

  defp to_section(section, controls, responses) do
    controls =
      controls
      |> Enum.filter(&(&1.section_id == section.id))
      |> Enum.map(&to_controls(&1, responses))
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

  defp to_controls(control, responses) do
    response = Enum.find(responses, %{}, &(&1.control_id == control.id))

    %{
      id: control.id,
      order: control.order,
      response_id: response.id,
      section_id: control.section_id,
      label: control.label,
      answer: response.answer,
      comment: response.comment
    }
  end
end
