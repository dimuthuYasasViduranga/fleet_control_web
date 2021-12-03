defmodule DispatchWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :dispatch_web
  use Appsignal.Phoenix

  mix_env =
    if Code.ensure_compiled(Mix) do
      Mix.env()
    else
      :prod
    end

  secure_headers = %{
    "x-frame-options" => "sameorigin",
    "x-content-type-options" => "nosniff",
    "strict-transport-security" => "max-age=31536000; includesubdomains",
    "x-xss-protection" => "1; mode=block"
  }

  socket "/fleet-control/operator-socket", DispatchWeb.OperatorSocket,
    websocket: true,
    longpoll: false

  socket "/fleet-control/dispatcher-socket", DispatchWeb.DispatcherSocket,
    websocket: true,
    longpoll: false

  socket "/fleet-control/device-auth-socket", DispatchWeb.DeviceAuthSocket,
    websocket: true,
    longpoll: false

  plug Plug.Static,
    at: "/fleet-control",
    from: {:dispatch_web, "priv/static"},
    gzip: mix_env == :prod,
    only: ~w(css fonts images index.html js media favicon.ico robots.txt),
    headers: secure_headers

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  origins =
    if mix_env == :prod do
      [
        ~r{^https://.*haultrax.digital},
        "https://login.microsoftonline.com"
      ]
    else
      [
        ~r{^http://},
        "https://login.microsoftonline.com"
      ]
    end

  plug Corsica,
    origins: origins,
    allow_methods: :all,
    allow_headers: :all,
    allow_credentials: true,
    log: [rejected: :warn, invalid: :debug, accepted: :debug]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_dispatch_server_key",
    signing_salt: "Qx/lVhwj"

  plug :put_headers, secure_headers

  def put_headers(conn, key_values) do
    Enum.reduce(key_values, conn, fn {k, v}, conn ->
      Plug.Conn.put_resp_header(conn, to_string(k), v)
    end)
  end

  plug DispatchWeb.Router
end
