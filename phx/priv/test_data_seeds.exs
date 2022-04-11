alias HpsData.Repo
alias HpsData.{Asset, AssetType, Dim}

Repo.start_link()

# assets
asset_types =
  AssetType
  |> Repo.all()
  |> Enum.map(&{&1.type, &1.id})
  |> Enum.into(%{})

assets = [
  %{name: "DT 01", asset_type_id: asset_types["Haul Truck"]},
  %{name: "DT 02", asset_type_id: asset_types["Haul Truck"]},
  %{name: "SCRAPER 01", asset_type_id: asset_types["Scraper"]},
  %{name: "SCRAPER 02", asset_type_id: asset_types["Scraper"]},
  %{name: "SCRATCHY 01", asset_type_id: asset_types["Scratchy"]},
  %{name: "SCRATCHY 02", asset_type_id: asset_types["Scratchy"]},
  %{name: "WC 01", asset_type_id: asset_types["Watercart"]},
  %{name: "WC 02", asset_type_id: asset_types["Watercart"]},
  %{name: "GD 01", asset_type_id: asset_types["Grader"]},
  %{name: "GD 02", asset_type_id: asset_types["Grader"]},
  %{name: "DZ 01", asset_type_id: asset_types["Dozer"]},
  %{name: "DZ 02", asset_type_id: asset_types["Dozer"]},
  %{name: "EX 01", asset_type_id: asset_types["Excavator"]},
  %{name: "EX 02", asset_type_id: asset_types["Excavator"]},
  %{name: "LD 01", asset_type_id: asset_types["Loader"]},
  %{name: "LD 02", asset_type_id: asset_types["Loader"]},
  %{name: "LV 01", asset_type_id: asset_types["Light Vehicle"]},
  %{name: "LV 02", asset_type_id: asset_types["Light Vehicle"]},
  %{name: "LP 01", asset_type_id: asset_types["Lighting Plant"]},
  %{name: "LP 02", asset_type_id: asset_types["Lighting Plant"]},
  %{name: "SV 01", asset_type_id: asset_types["Service Vehicle"]},
  %{name: "SV 02", asset_type_id: asset_types["Service Vehicle"]}
]

{_count, assets} = Repo.insert_all(Asset, assets, returning: true)

haul_trucks =
  assets
  |> Enum.filter(&(&1.asset_type_id == asset_types["Haul Truck"]))
  |> Enum.map(&%{asset_name: &1.name, user_id: &1.id, asset_id: &1.id, nominal_payload: 150})

Repo.insert_all(Dim.HaulTruck, haul_trucks)

# calendar, shift types and timezone
Repo.transaction(fn ->
  %{id: timezone_id} = Repo.insert!(%Dim.Timezone{tz: "Australia/West"})

  %{id: day_shift_id} =
    Repo.insert!(%Dim.ShiftType{
      timezone_id: timezone_id,
      shift_start_local: "06:00:00",
      shift_name: "Day Shift"
    })

  %{id: night_shift_id} =
    Repo.insert!(%Dim.ShiftType{
      timezone_id: timezone_id,
      shift_start_local: "18:00:00",
      shift_name: "Night Shift"
    })

  # create heaps and heaps
  calendar_start_utc = ~N[2019-12-31 22:00:00.000000]

  calendars =
    Enum.map(0..3000, fn index ->
      shift_start_utc = NaiveDateTime.add(calendar_start_utc, 12 * 3600 * index, :second)
      shift_end_utc = NaiveDateTime.add(shift_start_utc, 12 * 3600, :second)

      shift_type_id =
        case rem(index, 2) do
          0 -> day_shift_id
          _ -> night_shift_id
        end

      %{
        year: -1,
        quarter: -1,
        month: -1,
        day_of_month: -1,
        day_of_week: -1,
        week_of_year: -1,
        shift_type_id: shift_type_id,
        shift_start_utc: shift_start_utc,
        shift_end_utc: shift_end_utc
      }
    end)

  Repo.insert_all(Dim.Calendar, calendars)
end)

# locations
to_loc_history = fn types, locations, {south, north, east, west}, name, type ->
  geofence =
    "#{north},#{east}|#{north},#{west}|#{south},#{west}|#{south},#{east}|#{north},#{east}"

  timestamp = ~N[2020-01-01 00:00:00.000000]

  %{
    lat_min: south,
    lat_max: north,
    lon_min: east,
    lon_max: west,
    start_time: timestamp,
    timestamp: timestamp,
    geofence: geofence,
    location_id: locations[name],
    location_type_id: types[type],
    name: name,
    type: type
  }
end

Repo.transaction(fn ->
  location_types =
    Repo.insert_all(
      Dim.LocationType,
      [
        %{type: "closed"},
        %{type: "dump"},
        %{type: "maintenance"},
        %{type: "parkup"},
        %{type: "load"},
        %{type: "load|dump"},
        %{type: "fuel_bay"},
        %{type: "changeover_bay"}
      ],
      returning: true
    )
    |> elem(1)
    |> Enum.map(&{&1.type, &1.id})
    |> Enum.into(%{})

  locations =
    Repo.insert_all(
      Dim.Location,
      [
        %{name: "Crusher"},
        %{name: "WD 01"},
        %{name: "WD 02"},
        %{name: "Stock 01"},
        %{name: "Parkup"}
      ],
      returning: true
    )
    |> elem(1)
    |> Enum.map(&{&1.name, &1.id})
    |> Enum.into(%{})

  Repo.insert_all(Dim.LocationHistory, [
    to_loc_history.(location_types, locations, {32.0, 32.1, 116.0, 116.1}, "Crusher", "dump"),
    to_loc_history.(location_types, locations, {32.1, 32.2, 116.1, 116.2}, "WD 01", "load"),
    to_loc_history.(location_types, locations, {32.2, 32.3, 116.2, 116.3}, "WD 02", "load"),
    to_loc_history.(
      location_types,
      locations,
      {32.3, 32.4, 116.3, 116.4},
      "Stock 01",
      "load|dump"
    ),
    to_loc_history.(location_types, locations, {32.4, 32.5, 116.4, 116.5}, "Parkup", "parkup")
  ])
end)
