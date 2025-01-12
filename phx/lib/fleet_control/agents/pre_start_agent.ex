defmodule FleetControl.PreStartAgent do
  @moduledoc """
  Used to hold all current pre-start definitions
  """

  use Agent
  alias FleetControl.AgentHelper
  require Logger

  alias HpsData.Schemas.Dispatch.PreStart
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi

  @type control :: %{
          id: integer,
          section_id: integer,
          order: integer,
          label: String.t(),
          requires_comment: boolean(),
          category_id: integer | nil
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
          timestamp: NaiveDateTime.t(),
          server_timestamp: NaiveDateTime.t(),
          sections: list(section)
        }

  @type category :: %{
          id: integer,
          name: String.t(),
          order: integer,
          action: String.t() | nil
        }

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    %{
      current: pull_latest_forms(),
      categories: pull_categories()
    }
  end

  defp pull_categories() do
    from(c in PreStart.ControlCategory,
      select: %{
        id: c.id,
        name: c.name,
        order: c.order,
        action: c.action
      },
      order_by: [asc: c.order]
    )
    |> Repo.all()
  end

  defp pull_latest_forms() do
    {:ok, {forms, sections, controls}} =
      Repo.transaction(fn ->
        forms =
          from(f in PreStart.Form,
            distinct: f.asset_type_id,
            order_by: [desc: f.timestamp]
          )
          |> Repo.all()

        form_ids = Enum.map(forms, & &1.id)

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

        {forms, sections, controls}
      end)

    Enum.map(forms, &to_form_tree(&1, sections, controls))
  end

  defp to_form_tree(form, sections, controls) do
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
      |> Enum.map(fn c ->
        %{
          id: c.id,
          section_id: c.section_id,
          order: c.order,
          label: c.label,
          requires_comment: c.requires_comment || false,
          category_id: c.category_id
        }
      end)
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

  @spec all() :: list(form)
  def all(), do: Agent.get(__MODULE__, & &1[:current])

  @spec categories() :: list(category)
  def categories(), do: Agent.get(__MODULE__, & &1[:categories])

  @spec update_categories(list(map)) ::
          {:ok, list(category)} | {:error, :invalid_ids | term}
  def update_categories(cats) do
    new_cats =
      cats
      |> Enum.filter(&is_nil(&1[:id]))
      |> Enum.map(&Map.drop(&1, [:id]))

    updated_cats = Enum.reject(cats, &is_nil(&1[:id]))

    Agent.get_and_update(__MODULE__, fn state ->
      pending_ids = Enum.map(updated_cats, & &1[:id]) |> Enum.sort()
      given_ids = Enum.map(state.categories, & &1[:id]) |> Enum.sort()

      case pending_ids == given_ids do
        true ->
          Multi.new()
          |> Multi.insert_all(:new, PreStart.ControlCategory, new_cats, returning: true)
          |> Multi.insert_all(:updated, PreStart.ControlCategory, updated_cats,
            on_conflict: {:replace_all_except, [:id]},
            conflict_target: [:id],
            returning: true
          )
          |> Repo.transaction()
          |> case do
            {:ok, %{new: {_, new}, updated: {_, updated}}} ->
              new_categories =
                (new ++ updated)
                |> Enum.map(&PreStart.ControlCategory.to_map/1)
                |> Enum.sort_by(& &1.order)

              state = Map.put(state, :categories, new_categories)
              {{:ok, new_categories}, state}

            error ->
              {error, state}
          end

        _ ->
          {{:error, :invalid_ids}, state}
      end
    end)
  end

  @spec get(integer) :: form | nil
  def get(asset_type_id) do
    Agent.get(__MODULE__, fn state ->
      Enum.find(state.current, &(&1.asset_type_id == asset_type_id))
    end)
  end

  @spec add(integer, integer, list(map), NaiveDateTime.t()) ::
          {:ok, form} | {:error, :invalid_asset_type | :missing_sections | term}
  def add(nil, _dispatcher_id, _secionts, _timestamp), do: {:error, :invalid_asset_type}

  def add(_asset_type_id, _dispatcher_id, [], _timestamp), do: {:error, :missing_sections}

  def add(asset_type_id, dispatcher_id, sections, timestamp) when is_list(sections) do
    case validate_sections(sections) do
      {:ok, {sections, controls}} ->
        Agent.get_and_update(__MODULE__, fn state ->
          insert_form(asset_type_id, dispatcher_id, sections, controls, timestamp)
          |> case do
            {:ok, data} ->
              new_form = to_form_tree(data.form, data.sections, data.controls)

              state =
                case can_store_form?(state.current, asset_type_id, new_form.timestamp) do
                  true ->
                    AgentHelper.override_or_add(
                      state,
                      :current,
                      new_form,
                      &(&1.asset_type_id == asset_type_id),
                      nil
                    )

                  false ->
                    state
                end

              {{:ok, new_form}, state}

            error ->
              {error, state}
          end
        end)

      error ->
        error
    end
  end

  defp validate_sections(sections) do
    sections
    |> Enum.with_index()
    |> Enum.map(&validate_section/1)
    |> Enum.reduce(%{sections: [], controls: [], errors: []}, &split_sections/2)
    |> case do
      %{errors: []} = groups -> {:ok, {groups.sections, groups.controls}}
      %{errors: errors} -> {:error, List.first(errors)}
    end
  end

  defp split_sections({:ok, section}, acc) do
    updated_section = Map.delete(section, :controls)
    acc = Map.update!(acc, :sections, &[updated_section | &1])

    Enum.reduce(section.controls, acc, fn validation, acc ->
      case validation do
        {:ok, control} -> Map.update!(acc, :controls, &[control | &1])
        {:error, reason} -> Map.update!(acc, :errors, &[reason | &1])
      end
    end)
  end

  defp split_sections({:error, reason}, acc), do: Map.update!(acc, :errors, &[reason | &1])

  defp validate_section({section, index}) do
    section_ref = "#{index}"
    title = section["title"]
    details = section["details"]

    controls =
      (section["controls"] || [])
      |> Enum.with_index()
      |> Enum.map(&validate_control(&1, section_ref))

    case {!!title, length(controls) > 0} do
      {true, true} ->
        {:ok,
         %{ref: section_ref, title: title, details: details, order: index, controls: controls}}

      {false, _} ->
        {:error, :missing_section_title}

      {_, false} ->
        {:error, :missing_section_controls}
    end
  end

  defp validate_control({control, index}, section_ref) do
    label = control["label"]
    requires_comment = control["requires_comment"] || false
    category_id = control["category_id"]

    case !!label do
      true ->
        {:ok,
         %{
           section_ref: section_ref,
           label: label,
           requires_comment: requires_comment,
           category_id: category_id,
           order: index
         }}

      _ ->
        {:error, :missing_control_label}
    end
  end

  defp insert_form(asset_type_id, dispatcher_id, raw_sections, raw_controls, timestamp) do
    form =
      PreStart.Form.new(%{
        asset_type_id: asset_type_id,
        dispatcher_id: dispatcher_id,
        timestamp: timestamp
      })

    Multi.new()
    |> Multi.insert(:form, form)
    |> Multi.run(:sections, fn repo, %{form: form} ->
      ecto_sections =
        Enum.map(raw_sections, fn s ->
          %{
            form_id: form.id,
            order: s.order,
            title: s.title,
            details: s.details
          }
        end)

      repo.insert_all(PreStart.Section, ecto_sections, returning: true)
      |> case do
        {0, _} -> {:error, :failed_sections_to_form}
        {_, sections} -> {:ok, sections}
      end
    end)
    |> Multi.run(:controls, fn repo, %{sections: sections} ->
      section_ids = Enum.map(sections, & &1.id)

      section_lookup =
        Enum.map(raw_sections, & &1.ref)
        |> Enum.zip(section_ids)
        |> Enum.into(%{})

      ecto_controls =
        Enum.map(raw_controls, fn c ->
          %{
            section_id: section_lookup[c.section_ref],
            order: c.order,
            label: c.label,
            requires_comment: c[:requires_comment] || false,
            category_id: c[:category_id]
          }
        end)

      repo.insert_all(PreStart.Control, ecto_controls, returning: true)
      |> case do
        {0, _} -> {:error, :failed_controls_to_section}
        {_, controls} -> {:ok, controls}
      end
    end)
    |> Repo.transaction()
  end

  defp can_store_form?(pre_starts, asset_type_id, new_timestamp) do
    pre_starts
    |> Enum.find(&(&1.asset_type_id == asset_type_id))
    |> case do
      %{timestamp: current_timestamp} ->
        NaiveDateTime.compare(new_timestamp, current_timestamp) == :gt

      _ ->
        true
    end
  end
end
