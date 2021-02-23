defmodule DispatchWeb do
  @moduledoc """
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: DispatchWeb

      import Plug.Conn
      import DispatchWeb.Gettext
      alias DispatchWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/dispatch_server_web/templates",
        namespace: DispatchWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      import DispatchWeb.ErrorHelpers
      import DispatchWeb.Gettext
      alias DispatchWeb.Router.Helpers, as: Routes
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import DispatchWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
