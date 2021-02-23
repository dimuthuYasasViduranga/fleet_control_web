defmodule Dispatch.Culling do
  alias Dispatch.Helper

  @doc """
  Add the given element(s) to the list and cull
  """
  @spec add(list, any | list, map) :: list
  def add(list, elements, opts) when is_list(elements) do
    cull(elements ++ list, opts)
  end

  def add(list, element, opts), do: add(list, [element], opts)

  @doc """
  Override element in list on function compare, or insert new element. Followed by cull
  """
  @spec override_or_add(list, any, fun, map) :: list
  def override_or_add(list, element, fun, opts) do
    case Enum.find_index(list, &fun.(&1)) do
      nil -> [element | list]
      index -> List.replace_at(list, index, element)
    end
    |> cull(opts)
  end

  @doc """
  Override element only on function match. Followed by cull on match
  """
  @spec override(list, any, fun, map) :: list
  def override(list, element, fun, opts) do
    case Enum.find_index(list, &fun.(&1)) do
      nil ->
        list

      index ->
        list
        |> List.replace_at(index, element)
        |> cull(opts)
    end
  end

  @spec cull(list, map | nil) :: list
  def cull(list, nil), do: list

  def cull(list, opts) do
    now = NaiveDateTime.utc_now()

    case opts[:group_key] do
      nil -> [{nil, list}]
      group_key -> Enum.group_by(list, & &1[group_key])
    end
    |> Enum.map(fn {_, elements} ->
      elements
      |> sort_desc(opts[:time_key])
      |> cull_by_age(opts, now)
      |> cull_by_size(opts[:max_group_size])
    end)
    |> List.flatten()
    |> sort_desc(opts[:time_key])
    |> cull_by_size(opts[:max_size])
  end

  defp cull_by_age(list, %{time_key: key, max_age: {max_age, keep_outside}}, now) do
    cull_by_age(list, key, max_age, keep_outside, now)
  end

  defp cull_by_age(list, %{time_key: key, max_age: max_age}, now) do
    cull_by_age(list, key, max_age, 0, now)
  end

  defp cull_by_age(list, _opts, _now), do: list

  defp cull_by_age(list, key, max_age, keep_offset, now) do
    min_timestamp = NaiveDateTime.add(now, -max_age, :second)

    first_lt_index =
      Enum.find_index(list, &(NaiveDateTime.compare(to_naive(&1[key]), min_timestamp) != :gt))

    to_take = (first_lt_index || length(list)) + keep_offset

    Enum.take(list, to_take)
  end

  defp cull_by_size(list, nil), do: list

  defp cull_by_size(list, quantitiy), do: Enum.take(list, quantitiy)

  defp to_naive(nil), do: Helper.to_naive(0)

  defp to_naive(timestamp), do: Helper.to_naive(timestamp, :millisecond)

  defp sort_desc(list, nil), do: list

  defp sort_desc(list, key) do
    Enum.sort(list, fn a, b ->
      t1 = to_naive(a[key])
      t2 = to_naive(b[key])
      NaiveDateTime.compare(t1, t2) == :gt
    end)
  end
end
