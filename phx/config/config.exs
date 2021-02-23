import Config

config :hps_data, HpsData.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 5,
  database: "hpssql",
  username: "postgres",
  password: "",
  hostname: "localhost",
  timeout: 60_000,
  handshake_timeout: 60_000,
  queue_target: 60_000,
  queue_interval: 60_000,
  connect_timeout: 60_000,
  parameters: [
    {:application_name, "fleet-control"}
  ]

config :appsignal, :config,
  opt_app: :dispatch_web,
  name: "fleet-control-test",
  env: Mix.env()

config :dispatch_web,
  g_map_key: nil,
  map_center: %{
    latitude: -32.847896,
    longitude: 116.0596581,
    zoom: 15
  },
  map_tile_endpoint: nil,
  track_method: :gps_gate,
  bypass_auth: false,
  location_update_interval: 3600,
  secondary_types: %{
    "Excavator" => "Dig Unit",
    "Loader" => "Dig Unit"
  },
  route_white_list: %{
    default: [
      "/asset_assignment",
      "/location_assignment",
      "/mine_map",
      "/asset_progress_line",
      "/operators",
      "/device_assignment",
      "/asset_status",
      "/time_allocation",
      "/time_allocation_report",
      "/time_code_editor",
      "/message_editor",
      "/cycle_tally",
      "/activity_log",
      "/operator_messages",
      "/dispatcher_messages",
      "/dispatch_history",
      "/assignments",
      "/engine_hours",
      "/task_history",
      "/debug",
      "/agents",
      "/route_map",
      "/pre_start_editor",
      "/pre_start_submissions"
    ]
  }

# Configures the endpoint
config :dispatch_web, DispatchWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "8aeLYvJ4LClH+2/UpLwQzpZd+XYUydl/FXJlZ90IGnvaR3HxEa1Rs5iP0dSA88xw",
  render_errors: [view: DispatchWeb.ErrorView, accepts: ~w(json)],
  pubsub_server: DispatchWeb.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  compile_time_purge_matching: [
    [application: :gps_gate_rest, level_lower_than: :info]
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# authentication
config :azure_ad_openid, AzureADOpenId,
  tenant: "a8180769-6e40-4a3c-a14a-e1e69ff1da11",
  client_id: "3a97a4f4-4e3a-4525-9c2a-7c44cbf1d76b"

config :dispatch_web, DispatchWeb.Guardian, issuer: "dispatch_web"

config :joken,
  default_signer: "a;lwnsev;lahselkansekbjbklsdfa;khwes"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
if File.exists?("config/config.secret.exs") && Mix.env() != :test do
  import_config "config.secret.exs"
end

import_config "#{Mix.env()}.exs"