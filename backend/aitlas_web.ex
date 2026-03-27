defmodule AitlasWeb do
  @moduledoc """
  Web interface module for Aitlas.

  Provides:
  - `use AitlasWeb, :controller` - Phoenix controller setup
  - `use AitlasWeb, :router` - Phoenix router setup
  - `use AitlasWeb, :channel` - Phoenix channel setup
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: AitlasWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: AitlasWeb.Endpoint,
        router: AitlasWeb.Router,
        statics: AitlasWeb.static_paths()
    end
  end

  @doc false
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
