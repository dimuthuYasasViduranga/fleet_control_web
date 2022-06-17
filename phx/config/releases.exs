import Config

fetch_eval = fn env_name ->
  System.fetch_env!(env_name)
  |> Code.eval_string()
  |> elem(0)
end

dispatch = fetch_eval.("DISPATCH")
config :dispatch_web, dispatch
config :dispatch_web, g_map_key: System.fetch_env!("MAP_KEY")

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
  check_origin: [url_base <> ".haultrax.digital", url],
  secret_key_base: System.fetch_env!("COOKIE_SECRET_KEY")

config :dispatch_web, DispatchWeb.Guardian, secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

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
    {~r/\#(PID|Reference)\<(\d|\.)+\>/, "#\\1\<\>"}
  ],
  ignore: [
    "Postgrex.Protocol (#PID<>) disconnected: ** (DBConnection.ConnectionError) ssl recv (idle): closed"
  ]
