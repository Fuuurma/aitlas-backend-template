defmodule Aitlas.MCP.Server do
  @moduledoc """
  Hermes MCP Server for Aitlas Backend Template.

  This is the reference MCP implementation for all Aitlas products.
  Uses Hermes' component-based architecture.

  ## Authentication

  The server supports three authentication methods:

  1. **Internal** (`x-furma-internal` header) - Service-to-service
  2. **External** (`Authorization: Bearer <MCP_API_KEY>`) - Static API key
  3. **Better Auth** (`Authorization: Bearer <session_token>`) - OAuth for AI agents

  User context is extracted from Better Auth session tokens and made
  available to tools via `frame.assigns.user_id`.

  ## Usage

  Add to your application supervisor:

      children = [
        Hermes.Server.Registry,
        {Aitlas.MCP.Server, transport: :streamable_http}
      ]

  Add to your Phoenix router:

      forward "/api/mcp", Hermes.Server.Transport.StreamableHTTP.Plug,
        init_opts: [server: Aitlas.MCP.Server]

  ## Adding Tools

  Create a tool module in `lib/aitlas/mcp/tools/`:

      defmodule Aitlas.MCP.Tools.MyTool do
        use Hermes.Server.Component, type: :tool

        schema do
          field(:param, :string, required: true, description: "Parameter")
        end

        @impl true
        def execute(%{"param" => value}, frame) do
          user_id = frame.assigns[:user_id]
          {:ok, result}
        end
      end

  Then add it to this server:

      component Aitlas.MCP.Tools.MyTool
  """

  use Hermes.Server,
    name: "Aitlas",
    version: "1.0.0",
    capabilities: [:tools]

  alias Aitlas.Accounts.Session
  alias Aitlas.Repo

  # Register tools as components
  component Aitlas.MCP.Tools.Echo
  component Aitlas.MCP.Tools.GetCredits
  component Aitlas.MCP.Tools.GetUser
  # Add more tools here as you create them

  @impl true
  def init(client_info, frame) do
    # Extract user context from various sources
    user_id = get_user_context(client_info)

    frame = Hermes.Server.Frame.assign(frame, user_id: user_id)
    {:ok, frame}
  end

  # Extract user_id from Better Auth session token
  # This is passed via Authorization header, extracted by Plug
  defp get_user_context(client_info) do
    # From client_info meta (passed by frontend)
    get_in(client_info, ["_meta", "user_id"]) ||
      # From session token (passed via assigns)
      get_in(client_info, ["assigns", "user_id"])
  end
end