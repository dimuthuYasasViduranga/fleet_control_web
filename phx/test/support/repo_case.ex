defmodule DispatchWeb.RepoCase do
  use ExUnit.CaseTemplate
  alias HpsData.Repo

  using do
    quote do
      alias HpsData.Repo
      import DispatchWeb.RepoCase
    end
  end

  setup_all _ do
    start_supervised!(HpsData.Repo, [])
    start_supervised!(HpsData.Encryption.Vault, [])
    :ok
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HpsData.Repo)

    if tags[:async] == true do
      raise "Conn Case cannot use async"
    end

    Ecto.Adapters.SQL.Sandbox.mode(HpsData.Repo, {:shared, self()})

    :ok
  end

  def assert_ecto_error({:error, _name, %Ecto.Changeset{}, _}), do: true
  def assert_ecto_error({:error, %Ecto.Changeset{}}), do: true

  def assert_ecto_error(given) do
    raise ExUnit.AssertionError,
      message: "Given is not an ecto error",
      left: given
  end

  def assert_db_count(schema, count), do: assert(Repo.aggregate(schema, :count) == count)

  def assert_db_count(schema, key_false_count, key_true_count, key \\ :deleted) do
    entries = Repo.all(schema)
    key_false = Enum.reject(entries, &(Map.get(&1, key) == true))
    key_true = Enum.filter(entries, &(Map.get(&1, key) == true))

    assert length(key_false) == key_false_count
    assert length(key_true) == key_true_count
  end

  def assert_db_contains_ids(schema, ids) when is_list(ids) do
    db_ids =
      schema
      |> Repo.all()
      |> Enum.map(& &1.id)

    case Enum.all?(ids, &(&1 in db_ids)) do
      true ->
        true

      false ->
        raise ExUnit.AssertionError,
          message: "left (db) does not contain right ids",
          left: db_ids,
          right: ids
    end
  end

  def assert_db_contains(schema, element_or_elements, formatter \\ nil)

  def assert_db_contains(schema, elements, formatter) when is_list(elements) do
    records = get_records(schema, formatter)

    case Enum.all?(elements, &Enum.member?(records, &1)) do
      true ->
        true

      _ ->
        raise ExUnit.AssertionError,
          message: "left (db) does not contain right",
          left: records,
          right: elements
    end
  end

  def assert_db_contains(schema, element, formatter) do
    records = get_records(schema, formatter)

    case Enum.member?(records, element) do
      true ->
        true

      _ ->
        raise ExUnit.AssertionError,
          message: "left (db) does not contain right",
          left: records,
          right: element
    end
  end

  def refute_db_contains(schema, element_or_elements, formatter \\ nil)

  def refute_db_contains(schema, elements, formatter) when is_list(elements) do
    records = get_records(schema, formatter)

    case Enum.all?(elements, &Enum.member?(records, &1)) do
      false ->
        true

      _ ->
        raise ExUnit.AssertionError,
          message: "left (db) contains some of right",
          left: records,
          right: elements
    end
  end

  def refute_db_contains(schema, element, formatter) do
    records = get_records(schema, formatter)

    case Enum.member?(records, element) do
      false ->
        true

      _ ->
        raise ExUnit.AssertionError,
          message: "left (db) contains right",
          left: records,
          right: element
    end
  end

  defp get_records(schema, nil), do: get_records(schema, &apply(schema, :to_map, [&1]))

  defp get_records(schema, fun) do
    schema
    |> Repo.all()
    |> Enum.map(&fun.(&1))
  end
end
