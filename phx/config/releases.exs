import Config

fetch_eval = fn env_name ->
  System.fetch_env!(env_name)
  |> Code.eval_string()
  |> elem(0)
end

# site config (not required)
dispatch = fetch_eval.("DISPATCH")
config :dispatch_web, dispatch

# :dispatch secrets
map_key = System.fetch_env!("MAP_KEY")
config :dispatch_web, g_map_key: map_key

# appsignal
appsignal_api = System.fetch_env!("APPSIGNAL_API")
site = System.fetch_env!("SITE")

config :appsignal, :config,
  name: "fleet-control-#{site}",
  push_api_key: appsignal_api

# hpssql database
hpssql_config = fetch_eval.("HPSSQL_CONNECTION")
config :hps_data, HpsData.Repo, hpssql_config

config :hps_data,
  encryption_key: System.fetch_env!("HPSSQL_ENCRYPTION_KEY")

# :gps_gate_rest
gps_gate_rest = fetch_eval.("GPS_GATE_REST")
config :gps_gate_rest, gps_gate_rest

# azure ad
azure_ad = fetch_eval.("AZURE_ACTIVE_DIRECTORY")
config :azure_ad_openid, AzureADOpenId, azure_ad

joken_secret = System.fetch_env!("DISPATCH_JOKEN_SECRET")
config :joken, default_signer: joken_secret

# url
url = System.fetch_env!("URL")
port = System.fetch_env!("PORT")

whitelist = fetch_eval.("ROUTE_WHITE_LIST")
auth_permissions = fetch_eval.("AUTH_PERMISSIONS")

config :dispatch_web, url: url

config :dispatch_web, DispatchWeb.Endpoint,
  url: [host: url],
  check_origin: [url],
  http: [port: port]
