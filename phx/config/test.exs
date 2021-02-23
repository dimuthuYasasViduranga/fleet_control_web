use Mix.Config

config :ex_unit,
  assert_receive_timeout: 500

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :dispatch_web, DispatchWeb.Endpoint,
  http: [port: 4002],
  server: false,
  pubsub_server: DispatchWeb.PubSub

# Print only warnings and errors during test
config :logger, level: :warn

# database
database_config = [
  pool_size: 10,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "hpssql_dispatch_test",
  username: "postgres",
  password: "",
  hostname: "localhost"
]

config :dispatch_web, :ecto_repos, [HpsData.Repo]

config :hps_data, HpsData.Repo, database_config

# encryption_key = 32 |> :crypto.strong_rand_bytes() |> Base.encode64()
config :hps_data,
  encryption_key: "UJFKYoTJwrYgkoKe9Q8L0MzslBramPigdgB3qnokD4U="
