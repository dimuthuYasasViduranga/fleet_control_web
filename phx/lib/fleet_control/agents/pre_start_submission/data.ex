defmodule FleetControl.PreStartSubmissionAgent.Data do
  alias HpsData.Schemas.Dispatch.PreStart
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]

  @type submission :: map()
  @type ticket_status_type :: %{
          id: integer,
          name: String.t(),
          alias: String.t() | nil
        }

  @preloads [
    [form: [sections: [:controls]]],
    [responses: [ticket: [:active_status]]]
  ]

  @spec preload_and_destruct(list(Ecto.Schema.t()) | Ecto.Schema.t(), repo :: atom) ::
          list(submission) | submission
  def preload_and_destruct(schema_or_schemas, repo \\ Repo) do
    schema_or_schemas
    |> repo.preload(@preloads)
    |> remove_ecto_structs()
  end

  @spec pull_latest_submissions() :: list(submission)
  def pull_latest_submissions(repo \\ Repo) do
    from(s in PreStart.Submission,
      distinct: s.asset_id,
      order_by: [desc: s.timestamp]
    )
    |> repo.all()
    |> preload_and_destruct(repo)
  end

  @spec pull_submission(id :: integer) :: submission | nil
  def pull_submission(id, repo \\ Repo)

  def pull_submission(nil, _repo), do: nil

  def pull_submission(id, repo) do
    from(
      s in PreStart.Submission,
      where: s.id == ^id
    )
    |> repo.one()
    |> preload_and_destruct(repo)
  end

  @spec pull_submissions(list | integer, repo :: atom) :: list(submission) | submission | nil
  def pull_submissions(id_list, repo \\ Repo) when is_list(id_list) do
    from(
      s in PreStart.Submission,
      where: s.id in ^id_list
    )
    |> repo.all()
    |> preload_and_destruct(repo)
  end

  @spec pull_submissions_between(NaiveDateTime.t(), NaiveDateTime.t(), repo :: atom) ::
          list(submission)
  def pull_submissions_between(start_time, end_time, repo \\ Repo) do
    from(s in PreStart.Submission,
      where: s.timestamp >= ^start_time and s.timestamp < ^end_time
    )
    |> repo.all()
    |> preload_and_destruct(repo)
  end

  @spec pull_submissions_with_ticket(integer, repo :: atom) :: list(submission)
  def pull_submissions_with_ticket(ticket_id, repo \\ Repo)
  def pull_submissions_with_ticket(nil, _repo), do: []

  def pull_submissions_with_ticket(ticket_id, repo) do
    from(s in PreStart.Submission,
      join: r in PreStart.Response,
      on: [submission_id: s.id],
      join: t in PreStart.Ticket,
      on: [id: r.ticket_id],
      where: t.id == ^ticket_id,
      select: s
    )
    |> repo.all()
    |> preload_and_destruct(repo)
  end

  defp remove_ecto_structs(list) when is_list(list), do: Enum.map(list, &remove_ecto_structs/1)

  defp remove_ecto_structs(%_{__meta__: _meta} = struct) do
    struct
    |> Map.from_struct()
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      case value do
        %Ecto.Schema.Metadata{} ->
          acc

        %Ecto.Association.NotLoaded{} ->
          acc

        %_{__meta__: _meta} ->
          Map.put(acc, key, remove_ecto_structs(value))

        v when is_list(v) ->
          Map.put(acc, key, Enum.map(v, &remove_ecto_structs/1))

        _ ->
          Map.put(acc, key, value)
      end
    end)
  end

  defp remove_ecto_structs(value), do: value

  @spec pull_ticket_status_types(repo :: atom) :: list(ticket_status_type)
  def pull_ticket_status_types(repo \\ Repo) do
    from(tst in PreStart.TicketStatusType,
      select: %{
        id: tst.id,
        name: tst.name,
        alias: tst.alias
      }
    )
    |> repo.all()
  end
end
