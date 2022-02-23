defmodule Dispatch.LiveQueue do
  @type position :: %{
          lat: float,
          lng: float
        }

  @type dig_unit :: %{
          optional(:opts) => Keyword.t(),
          id: integer,
          position: position,
          timestamp: NaiveDateTime.t(),
          haul_trucks: list[haul_truck]
        }

  @type haul_truck :: %{
          id: integer,
          position: position,
          timestamp: NaiveDateTime.t()
        }

  @type queue :: map()

  @default_opts [
    max_active: 1,
    chain_distance: 50,
    active_distance: 50
  ]

  @spec create(list(dig_unit), Keyword.t()) :: queue
  def create(dig_units, options \\ []) do
    Enum.reduce(dig_units, %{}, fn dig_unit, acc ->
      opts = merge_opts(options, dig_unit[:opts])

      haul_trucks = add_distance_to(dig_unit.position, dig_unit.haul_trucks)

      {active, queued, out_of_range} = classify_haul_trucks(haul_trucks, opts)

      last_visited = get_last_visited(%{active: active})

      info = %{
        id: dig_unit.id,
        last_visited: last_visited,
        active: active,
        queued: queued,
        out_of_range: out_of_range
      }

      Map.put(acc, dig_unit.id, info)
    end)
  end

  defp merge_opts(global, specific) do
    @default_opts
    |> Keyword.merge(global || [])
    |> Keyword.merge(specific || [])
  end

  @spec extend(queue, queue) :: queue
  def extend(new, old \\ %{}) do
    new
    |> Map.values()
    |> Enum.reduce(%{}, fn dig_unit, acc ->
      extended = extend_dig_unit(dig_unit, old[dig_unit.id])
      Map.put(acc, dig_unit.id, extended)
    end)
  end

  defp extend_dig_unit(dig_unit, nil), do: dig_unit

  defp extend_dig_unit(new, old) do
    last_visited = get_last_visited(new, old)

    %{
      id: new.id,
      last_visited: last_visited,
      active: extend_queue_info(new.active, old.active),
      queued: extend_queue_info(new.queued, old.queued),
      out_of_range: extend_queue_info(new.out_of_range, old.out_of_range)
    }
  end

  defp get_last_visited(new, old \\ nil) do
    new.active
    |> Map.values()
    |> Enum.map(& &1.last_updated)
    |> Enum.sort_by(& &1, {:desc, NaiveDateTime})
    |> case do
      [timestamp] -> timestamp
      _ -> old[:last_visited]
    end
  end

  defp extend_queue_info(new, old) do
    new
    |> Map.values()
    |> Enum.reduce(%{}, fn ht, acc ->
      extended = extend_haul_truck(ht, old[ht.id])
      Map.put(acc, ht.id, extended)
    end)
  end

  defp extend_haul_truck(haul_truck, nil), do: haul_truck

  defp extend_haul_truck(new, old) do
    %{
      id: new.id,
      started_at: old.started_at,
      last_updated: new.last_updated,
      distance_to_excavator: new.distance_to_excavator,
      chain_distance: new.chain_distance
    }
  end

  defp add_distance_to(position, haul_trucks) do
    pos = {position.lat, position.lng}

    haul_trucks =
      Enum.map(haul_trucks, fn ht ->
        ht_pos = {ht.position.lat, ht.position.lng}
        distance = Distance.GreatCircle.distance(pos, ht_pos)
        Map.put(ht, :distance_to_excavator, distance)
      end)
      |> Enum.sort_by(& &1.distance_to_excavator)

    [%{position: position} | haul_trucks]
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [prev, ht] ->
      prev_pos = {prev.position.lat, prev.position.lng}
      ht_pos = {ht.position.lat, ht.position.lng}
      distance = Distance.GreatCircle.distance(prev_pos, ht_pos)

      Map.put(ht, :chain_distance, distance)
    end)
  end

  defp classify_haul_trucks([], _opts), do: {%{}, %{}, %{}}

  defp classify_haul_trucks(haul_trucks, opts) do
    {active, remaining} = find_active(haul_trucks, opts)
    {queued, out_of_range} = find_queued(remaining, opts[:chain_distance])

    {
      format_haul_trucks(active),
      format_haul_trucks(queued),
      format_haul_trucks(out_of_range)
    }
  end

  defp format_haul_trucks([]), do: %{}

  defp format_haul_trucks(hts) do
    Enum.reduce(hts, %{}, fn ht, acc ->
      info = %{
        id: ht.id,
        started_at: ht.timestamp,
        last_updated: ht.timestamp,
        distance_to_excavator: ht.distance_to_excavator,
        chain_distance: ht.chain_distance
      }

      Map.put(acc, ht.id, info)
    end)
  end

  defp find_active(haul_trucks, opts) do
    active_distance = opts[:active_distance]
    limit = opts[:max_active]

    active =
      haul_trucks
      |> Enum.filter(&(&1.distance_to_excavator < active_distance))
      |> Enum.take(limit)

    remaining =
      haul_trucks
      |> Enum.split(length(active))
      |> elem(1)

    {active, remaining}
  end

  defp find_queued([], _), do: {[], []}

  defp find_queued(haul_trucks, chain_distance) do
    case Enum.find_index(haul_trucks, &(&1.chain_distance > chain_distance)) do
      nil -> {haul_trucks, []}
      index -> Enum.split(haul_trucks, index)
    end
  end
end
