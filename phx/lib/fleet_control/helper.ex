defmodule FleetControl.Helper do
  @type valid_datetime :: integer | String.t() | NaiveDateTime.t()
  @type range :: %{start_time: valid_datetime, end_time: valid_datetime}

  @spec timestamp() :: integer
  def timestamp(scale \\ :millisecond) do
    DateTime.utc_now()
    |> DateTime.to_unix(scale)
  end

  @spec naive_timestamp() :: NaiveDateTime.t()
  def naive_timestamp(), do: NaiveDateTime.utc_now() |> naive_to_usec()

  @spec to_naive(valid_datetime) :: NaiveDateTime.t() | nil
  def to_naive(unix_naive_or_int, scale \\ :millisecond) do
    cond do
      is_nil(unix_naive_or_int) ->
        nil

      is_integer(unix_naive_or_int) ->
        unix_naive_or_int
        |> DateTime.from_unix!(scale)
        |> DateTime.to_naive()
        |> naive_to_usec()

      is_binary(unix_naive_or_int) ->
        unix_naive_or_int
        |> NaiveDateTime.from_iso8601!()
        |> naive_to_usec()

      true ->
        naive_to_usec(unix_naive_or_int)
    end
  end

  @spec to_unix(valid_datetime) :: integer | nil
  def to_unix(unix_naive_or_int, scale \\ :millisecond) do
    cond do
      is_nil(unix_naive_or_int) ->
        nil

      is_integer(unix_naive_or_int) ->
        unix_naive_or_int

      is_binary(unix_naive_or_int) ->
        unix_naive_or_int
        |> DateTime.from_iso8601()
        |> elem(1)
        |> DateTime.to_unix(scale)

      true ->
        unix_naive_or_int
        |> DateTime.from_naive!("Etc/UTC")
        |> DateTime.to_unix(scale)
    end
  end

  @spec to_atom_map!(map) :: map
  def to_atom_map!(map) do
    map
    |> Enum.map(&to_atom_map_row/1)
    |> Enum.into(%{})
  end

  defp to_atom_map_row({key, value}) when is_atom(key), do: {key, value}

  defp to_atom_map_row({key, value}), do: {String.to_existing_atom(key), value}

  @spec naive_to_usec(NaiveDateTime.t()) :: NaiveDateTime.t()
  def naive_to_usec(naive) do
    %NaiveDateTime{naive | microsecond: {elem(naive.microsecond, 0), 6}}
  end

  @doc """
  Used to return nil if any value is nil (prevents error throwing)
  """
  @spec get_by_or_nil(module, Ecto.Queryable.t(), map, Keyword.t()) :: Ecto.Schema.t() | nil
  def get_by_or_nil(repo, queryable, clauses, opts \\ []) do
    clauses
    |> Enum.any?(fn {_, value} -> is_nil(value) end)
    |> case do
      true -> nil
      _ -> apply(repo, :get_by, [queryable, clauses, opts])
    end
  end

  @doc """
  Returns a 'x' b where 'x' defines the coverage of a on b
  """
  @spec coverage(range, range) ::
          :unknown | :equals | :covers | :within | :end_within | :start_within | :no_overlap
  def coverage(a, b) do
    a_start = to_unix(a.start_time)
    a_end = to_unix(a.end_time)
    b_start = to_unix(b.start_time)
    b_end = to_unix(b.end_time)

    cond do
      Enum.any?([a_start, a_end, b_start, b_end], &is_nil/1) -> :unknown
      a_start == b_start && a_end == b_end -> :equals
      a_start <= b_start && a_end >= b_end -> :covers
      a_start >= b_start && a_end <= b_end -> :within
      a_end > b_start && a_end < b_end -> :end_within
      a_start > b_start && a_start < b_end -> :start_within
      true -> :no_overlap
    end
  end
end

defmodule FleetControl.Helper.Tracer do
  @doc "This is Saša Jurić code for tracing a module"
  use GenServer

  def start(modules), do: GenServer.start(__MODULE__, modules)

  def init(modules) do
    :erlang.trace(:all, true, [:call])

    for module <- modules do
      :erlang.trace_pattern({module, :_, :_}, [{:_, [], [{:return_trace}]}])
    end

    {:ok, nil}
  end

  def handle_info({:trace, _, :call, {mod, fun, args}}, state) do
    args_string = Enum.map_join(args, ",", &inspect/1)
    IO.puts("called #{mod}.#{fun}(#{args_string})")
    {:noreply, state}
  end

  def handle_info({:trace, _, :return_from, {mod, fun, arity}, res}, state) do
    IO.puts("#{mod}.#{fun}/#{arity} returned #{res}")
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}
end
