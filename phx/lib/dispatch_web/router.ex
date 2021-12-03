defmodule DispatchWeb.Router do
  use DispatchWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session

    plug :put_secure_browser_headers,
         %{"content-security-policy" => "default-src 'self'; script-src 'self'"}
  end

  pipeline :authorized do
    case Application.get_env(:dispatch_web, :bypass_auth, false) do
      true ->
        plug DispatchWeb.Authorization.Plug.LoadAuthPermissions, full_access: true

      _ ->
        plug Guardian.Plug.Pipeline,
          module: DispatchWeb.Guardian,
          error_handler: DispatchWeb.AuthErrorHandler

        plug Guardian.Plug.VerifySession
        plug Guardian.Plug.LoadResource
        plug Guardian.Plug.EnsureAuthenticated

        plug DispatchWeb.Authorization.Plug.LoadAuthPermissions
        plug DispatchWeb.Authorization.Plug.EnsureAuthorized
    end
  end

  scope "/fleet-control", DispatchWeb do
    pipe_through :api
    pipe_through :authorized

    get "/api/static_data", PageController, :static_data
  end

  scope "/fleet-control", DispatchWeb do
    pipe_through :api

    get "/", PageController, :index
  end

  scope "/fleet-control/auth", DispatchWeb do
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
end
