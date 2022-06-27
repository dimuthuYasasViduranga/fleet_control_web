import Config

config :phoenix, :json_library, Jason

config :appsignal, :config,
  opt_app: :fleet_control_web,
  name: "fleet-control-test",
  env: Mix.env(),
  active: false

# General application configuration
config :fleet_control_web,
  ecto_repos: [HpsData.Repo],
  map_center: %{
    latitude: -32.847896,
    longitude: 116.0596581,
    zoom: 15
  },
  track_interval: 10_000,
  track_method: :gps_gate,
  settings: [
    use_device_gps: false,
    prompt_exception_on_logout: true,
    prompt_engine_hours_on_login: false,
    prompt_engine_hours_on_logout: false,
    prompt_pre_starts_on_login: false,
    use_live_queue: false
  ],
  location_update_interval: 3600,
  secondary_types: %{
    "Excavator" => "Dig Unit",
    "Loader" => "Dig Unit"
  },
  location_assignment_layout: [
    orientation: "horizontal",
    asset_order: "normal",
    vertical: %{
      order_by: "location",
      columns: 2
    },
    horizontal: %{
      order_by: "location"
    }
  ],
  route_white_list: %{
    default: [
      "/asset_assignment",
      "/location_assignment",
      "/mine_map",
      "/asset_progress_line",
      "/operators",
      "/asset_roster",
      "/device_assignment",
      "/asset_status",
      "/time_allocation",
      "/operator_time_allocation",
      "/time_allocation_report",
      "/time_code_editor",
      "/message_editor",
      "/engine_hours",
      "/debug",
      "/agents",
      "/route_map",
      "/pre_start_editor",
      "/pre_start_submissions",
      "/asset_overview"
    ]
  }

# hpsdata
config :hps_data, HpsData.Repo,
  adapter: Ecto.Adapters.Postgres,
  ssl_opts: [log_level: :error],
  pool_size: 10,
  parameters: [
    {:application_name, "fleet-control"}
  ],
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

# Configures the endpoint
config :fleet_control_web, FleetControlWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: FleetControlWeb.ErrorView, accepts: ~w(json)],
  pubsub_server: FleetControlWeb.PubSub,
  secret_key_base: "8aeLYvJ4LClH+2/UpLwQzpZd+XYUydl/FXJlZ90IGnvaR3HxEa1Rs5iP0dSA88xw"

# Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  compile_time_purge_matching: [
    [application: :gps_gate_rest, level_lower_than: :info]
  ]

# authentication
config :azure_ad_openid, AzureADOpenId, tenant: "a8180769-6e40-4a3c-a14a-e1e69ff1da11"
config :fleet_control_web, FleetControlWeb.Guardian, issuer: "dispatch_web"
config :joken, default_signer: "a;lwnsev;lahselkansekbjbklsdfa;khwes"

import_config "#{Mix.env()}.exs"
