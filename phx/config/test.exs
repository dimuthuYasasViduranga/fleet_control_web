import Config

config :ex_unit,
  assert_receive_timeout: 500

config :fleet_control_web, FleetControlWeb.Endpoint,
  http: [port: 4002],
  server: false

config :hps_data, HpsData.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "hpssql_dispatch_test"

config :hps_data, encryption_key: "UJFKYoTJwrYgkoKe9Q8L0MzslBramPigdgB3qnokD4U="
config :logger, level: :warn
