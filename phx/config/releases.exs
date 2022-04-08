import Config

fetch_eval = fn env_name ->
  System.fetch_env!(env_name)
  |> Code.eval_string()
  |> elem(0)
end

maybe_fetch_eval = fn env, default ->
  case System.fetch_env(env) do
    {:ok, val} ->
      val
      |> Code.eval_string()
      |> elem(0)

    _ ->
      default
  end
end

random_string = fn size ->
  size
  |> :crypto.strong_rand_bytes()
  |> Base.encode64()
  |> binary_part(0, size)
end

dispatch = fetch_eval.("DISPATCH")
config :dispatch_web, dispatch

# :dispatch secrets
map_key = System.fetch_env!("MAP_KEY")
config :dispatch_web, g_map_key: map_key

# appsignal
appsignal_api = System.fetch_env!("APPSIGNAL_API")
config :appsignal, :config, push_api_key: appsignal_api

# azure ad
azure_ad = fetch_eval.("AZURE_ACTIVE_DIRECTORY")
config :azure_ad_openid, AzureADOpenId, azure_ad

# hpssql database
hpssql_config = fetch_eval.("HPSSQL_CONNECTION")
hpssql_encryption_key = System.fetch_env!("HPSSQL_ENCRYPTION_KEY")

config :hps_data, HpsData.Repo, hpssql_config
config :hps_data, encryption_key: hpssql_encryption_key

# :gps_gate_rest
gps_gate_rest = fetch_eval.("GPS_GATE_REST")
config :gps_gate_rest, gps_gate_rest

joken_secret = System.fetch_env!("DISPATCH_JOKEN_SECRET")
config :joken, default_signer: joken_secret

# url
url = System.fetch_env!("URL")

url_base =
  url
  |> String.trim_leading("https:")
  |> String.split(".")
  |> List.first()

config :dispatch_web, url: url

config :dispatch_web, DispatchWeb.Endpoint,
  url: [host: url],
  check_origin: [url_base <> ".haultrax.digital", url]

# conditionally set secret_key_base, if desired
config :dispatch_web, DispatchWeb.Endpoint,
  secret_key_base: maybe_fetch_eval.("DISPATCH_SECRET_KEY_BASE", random_string.(64))

# slack error logs
config :logger, backends: [:console, SlackLoggerBackend.Logger]

tag = System.fetch_env!("GIT_VERSION")
app_name = System.fetch_env!("APPSIGNAL_APP_NAME")
deployment_name = app_name <> ":" <> tag

config :slack_logger_backend,
  debounce_seconds: 120,
  deployment_name: deployment_name,
  scrubber: [
      {~r/(password|token|secret)(:\s+\")(.+?)(\")/, "\\1\\2--redacted--\\4"},
      {~r/(^\w+\s+\|\s+)/, ""},
    ]
