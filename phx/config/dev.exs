use Mix.Config

# config :appsignal, :config, active: true

config :dispatch_web,
  url: "http://localhost:4010",
  bypass_auth: true

# For development, we disable any cache and enable
# debugging and code reloading.
config :dispatch_web, DispatchWeb.Endpoint,
  http: [port: 4010],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :dispatch_web, DispatchWeb.Guardian,
  secret_key: "b3hUyiE8zqDP7blaDGZSjKfoNqEmtP1wd3qTYIxBVvIh/ZjSgDoeNioxUA39nR7"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
