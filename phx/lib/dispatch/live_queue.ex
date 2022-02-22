defmodule Dispatch.LiveQueue do
  @type track :: map()

  @type target :: %{
          name: String.t(),
          lat: integer,
          lng: integer,
          opts: [
            active_limit: integer | nil,
            active_distance: integer | nil,
            chain_distance: integer | nil,
            max_distance: integer | nil
          ]
        }

  @type dump :: %{
          name: String.t(),
          latitude: integer,
          longitude: integer
        }

  @type active_asset :: %{
          name: String.t(),
          at: String.t() | nil,
          start_time: NaiveDateTime.t(),
          timestamp: NaiveDateTime.t()
        }

  @type queue :: %{
          name: String.t(),
          last_visited: NaiveDateTime.t(),
          active: list(active_asset),
          queued: list(active_asset)
        }

  def create(dig_unit, opts \\ []) do
    max_active = 1
    step_distance = 25
    max_distance = 400

    # give a distance value to each haul truck
    # sort by distance
    # tag all assets with :active, :queuing, :out_of_range
    # group by tags (ensure assets are still ordered by distance)

    # # create structure of
    # %{
    #   dig_unit_id: "dig_unit_id",
    #   last_visited: "a timestamp equal to the latest of active",
    #   active: [],
    #   queued: [],
    #   out_of_range: [],
    # }

    # # each haul truck has the following structure
    # %{
    #   asset_id: "haul_truck_id",
    #   started_at: "a timestamp",
    #   last_updated: "a timestamp"
    # }

    haul_trucks = add_distance_to(dig_unit.position, dig_unit.haul_trucks)

    {active, queued, out_of_range} =
      classify_haul_trucks(haul_trucks, active_distance, step_distance)
  end

  def extend(new, old) do
  end

  defp add_distance_to(position, haul_trucks) do
    pos = {position.lat, position.lng}

    haul_trucks
    |> Enum.map(fn ht ->
      ht_pos = {ht.position.lat, ht.position.lng}
      distance = Distance.GreatCircle.distance(pos, ht_pos)
      Map.put(ht, :distance, distance)
    end)
    |> Enum.sort_by(& &1.distance)
  end

  defp classify_haul_trucks([], _, _), do: {nil, [], []}

  defp classify_haul_trucks(haul_trucks, active_distance, chain_distance) do
    # first I think we will need to calculate the chaining distance between all haul trucks,
    # before doing the analysis
    {active, remaining} = find_active(haul_trucks, active_distance)
    {queued, out_of_range} = find_queued(remaining, chain_distance)
    {active, queued, out_of_range}
  end

  defp find_active([%{distance: distance} = first | rest], active_distance)
       when distance < active_distance do
    {first, rest}
  end

  defp find_active(haul_trucks, _), do: {nil, haul_trucks}

  defp find_queued([], _), do: {[], []}

  defp find_queued(haul_trucks, chain_distance) do
    # may need the position of the active asset, and or the position
    # loop through all haul trucks until the chain distance is > distance
    # use Enum.reduce_while()
  end

  @spec create_dig_unit_queues(list(track), list(track), Keyword.t()) :: list(queue)
  def create_dig_unit_queues(dig_unit_tracks, queueable_tracks, opts \\ []) do
    targets =
      Enum.map(dig_unit_tracks, fn track ->
        opts = get_dig_unit_opts(opts, track.type)

        %{
          name: track.name,
          location: track[:location][:name],
          lat: track.position.lat,
          lng: track.position.lng,
          opts: opts
        }
      end)

    create_queues(targets, queueable_tracks)
  end

  defp get_dig_unit_opts(opts, "Excavator") do
    Keyword.merge(opts[:dig_unit], opts[:excavator] || [])
  end

  defp get_dig_unit_opts(opts, "Loader") do
    Keyword.merge(opts[:dig_unit], opts[:loader] || [])
  end

  defp get_dig_unit_opts(opts, _), do: opts[:dig_unit]

  @spec create_dump_queues(list(dump), list(track), Keyword.t()) :: list(queue)
  def create_dump_queues(dumps, queueable_tracks, opts \\ []) do
    targets =
      Enum.map(dumps, fn dump ->
        specific_opts =
          dump
          |> Map.take([:active_limit, :active_distance, :chain_distance, :max_distance])
          |> Enum.into([])

        specific_opts = Keyword.merge(opts, specific_opts)

        %{
          name: dump.name,
          lat: dump.latitude,
          lng: dump.longitude,
          location: nil,
          opts: specific_opts
        }
      end)

    create_queues(targets, queueable_tracks)
  end

  @spec create_queues(list(target), list(track)) :: list(queue)
  def create_queues(targets, queueable_tracks) do
    Enum.map(targets, &create_queue(&1, queueable_tracks))
  end

  defp create_queue(target, queueable_tracks) do
    opts = target[:opts] || []
    max_active = opts[:active_limit]
    step_distance = opts[:chain_distance] || 25
    max_distance = opts[:max_distance]

    active_tracks =
      target
      |> get_all_within_ordered(queueable_tracks, opts[:active_distance])
      |> take_only(max_active)

    remaining_tracks = Enum.reject(queueable_tracks, &Enum.member?(active_tracks, &1))

    active_track_positions =
      Enum.map(active_tracks, &%{lat: &1.position.lat, lng: &1.position.lng})

    queued_tracks =
      [target | active_track_positions]
      |> Enum.map(&chain_from(&1, remaining_tracks, step_distance, max_distance))
      |> List.flatten()
      |> Enum.uniq()

    active_assets = Enum.map(active_tracks, &to_active_asset(&1, target.name))
    queued_assets = Enum.map(queued_tracks, &to_active_asset(&1, target.name))

    last_visited =
      (active_tracks ++ queued_tracks)
      |> Enum.map(& &1.timestamp)
      |> Enum.sort_by(& &1, {:desc, NaiveDateTime})
      |> List.first()

    %{
      name: target.name,
      location: target.location,
      last_visited: last_visited,
      active: active_assets,
      queued: queued_assets
    }
  end

  defp to_active_asset(track, at) do
    %{
      name: track.name,
      at: at,
      start_time: track.timestamp,
      timestamp: track.timestamp
    }
  end

  @spec extend_queue(queue, list(queue)) :: queue
  def extend_queue(new_queue, old_queues) do
    old_queues
    |> Enum.find(&(&1.name == new_queue.name))
    |> case do
      %{} = old_queue ->
        queued_assets = extend_active_assets(new_queue.queued, old_queue.queued)
        active_assets = extend_active_assets(new_queue.active, old_queue.active)

        new_queue
        |> Map.put(:queued, queued_assets)
        |> Map.put(:active, active_assets)
        |> Map.put(:last_visited, new_queue[:last_visited] || old_queue.last_visited)

      _ ->
        new_queue
    end
  end

  defp extend_active_assets(new_assets, old_assets) do
    Enum.map(new_assets, fn asset ->
      old_assets
      |> Enum.find(&(&1.name == asset.name))
      |> case do
        %{start_time: start_time} -> Map.put(asset, :start_time, start_time)
        _ -> asset
      end
    end)
  end

  @spec chain_from(%{lat: integer, lng: integer}, list(track), integer, integer | :infinity) ::
          list(track)
  def chain_from(position, tracks, step_distance, max_total_distance \\ :infinity) do
    chain(position, tracks, 0, step: step_distance, max_total: max_total_distance)
  end

  defp chain(position, tracks, total_distance, opts) do
    %{track: track, distance: distance} = get_closest(position, tracks)

    case !is_nil(track) && distance < opts[:step] do
      true ->
        total_distance = total_distance + distance

        case total_distance <= opts[:max_total] do
          true ->
            available_tracks = Enum.filter(tracks, &(&1 !== track))
            [track | chain(track.position, available_tracks, total_distance + distance, opts)]

          _ ->
            []
        end

      _ ->
        []
    end
  end

  defp get_closest(position, tracks) do
    pos = {position.lat, position.lng}

    Enum.reduce(tracks, %{track: nil, distance: :infinity}, fn track, acc ->
      distance = Distance.GreatCircle.distance(pos, {track.position.lat, track.position.lng})

      case distance < acc.distance do
        true -> %{track: track, distance: distance}
        false -> acc
      end
    end)
  end

  defp get_all_within_ordered(_position, _tracks, nil), do: []

  defp get_all_within_ordered(position, tracks, max_distance) do
    pos = {position.lat, position.lng}

    tracks
    |> Enum.map(&{&1, Distance.GreatCircle.distance(pos, {&1.position.lat, &1.position.lng})})
    |> Enum.reject(fn {_track, distance} -> distance > max_distance end)
    |> Enum.sort_by(&elem(&1, 1))
    |> Enum.map(&elem(&1, 0))
  end

  defp take_only(list, nil), do: list
  defp take_only(list, count), do: Enum.take(list, count)
end
