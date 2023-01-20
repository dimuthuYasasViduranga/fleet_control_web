defmodule FleetControlWeb.Router do
  use FleetControlWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session

    plug :put_secure_browser_headers,
         %{"content-security-policy" => "default-src 'self'; script-src 'self'"}
  end

  pipeline :authorized do
    case Application.get_env(:fleet_control_web, :bypass_auth, false) do
      true ->
        plug FleetControlWeb.Authorization.Plug.LoadAuthPermissions, full_access: true

      _ ->
        plug Guardian.Plug.Pipeline,
          module: FleetControlWeb.Guardian,
          error_handler: FleetControlWeb.AuthErrorHandler

        plug Guardian.Plug.VerifySession
        plug Guardian.Plug.LoadResource
        plug Guardian.Plug.EnsureAuthenticated

        plug FleetControlWeb.Authorization.Plug.LoadAuthPermissions
    end
  end

  scope "/fleet-control", FleetControlWeb do
    pipe_through :api
    pipe_through :authorized

    get "/api/static_data", PageController, :static_data
    get "/api/haul", HaulController, :recent
  end

  scope "/fleet-control", FleetControlWeb do
    pipe_through :api

    get "/", PageController, :index
  end

  scope "/fleet-control/auth", FleetControlWeb do
    pipe_through :api

    # dispatcher login
    get "/login", AuthController, :login
    post "/callback", AuthController, :callback
    get "/logout", AuthController, :logout

    # operator login
    post "/operator_login", AuthController, :operator_login

    # initial request for authorization
    post "/request_device_auth", DeviceAuthController, :request_device_auth
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/fleet-control" do
    pipe_through [:browser, :authorized]
    live_dashboard "/dashboard", live_socket_path: "/fleet-control/live"
  end
end
