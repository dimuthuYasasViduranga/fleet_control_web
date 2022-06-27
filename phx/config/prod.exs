import Config

config :dispatch_web, FleetControlWeb.Endpoint,
  load_from_system_env: true,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:phoenix_app, :vsn),
  http: [port: 4001]

# Do not print debug messages in production
config :logger,
  level: :info,
  compile_time_purge_matching: [
    [application: :gps_gate_rest, level_lower_than: :info],
    [application: :db_connection],
    [module: DBConnection.Connection]
  ]

config :appsignal, :config, active: true, env: :prod
