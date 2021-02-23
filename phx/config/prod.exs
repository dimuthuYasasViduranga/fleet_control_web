import Config

random_string = fn size ->
  size
  |> :crypto.strong_rand_bytes()
  |> Base.encode64()
  |> binary_part(0, size)
end

config :dispatch_web,
  bypass_auth: false

config :appsignal, :config, active: true

config :dispatch_web, DispatchWeb.Endpoint,
  secret_key_base: random_string.(64),
  load_from_system_env: true,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  # TODO
  root: ".",
  version: Application.spec(:phoenix_app, :vsn)

config :dispatch_web, DispatchWeb.Guardian, secret_key: random_string.(64)

# Do not print debug messages in production
config :logger, level: :info
