import Config

config :fleet_control_web,
  url: "http://localhost:4010",
  bypass_auth: true

config :fleet_control_web, FleetControlWeb.Endpoint,
  http: [port: 4010],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :fleet_control_web, FleetControlWeb.Guardian,
  secret_key: "b3hUyiE8zqDP7blaDGZSjKfoNqEmtP1wd3qTYIxBVvIh/ZjSgDoeNioxUA39nR7"

config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

if File.exists?("config/config.secret.exs") do
  import_config "config.secret.exs"
end
