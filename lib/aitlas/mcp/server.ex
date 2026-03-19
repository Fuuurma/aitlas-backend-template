defmodule Aitlas.MCP.Server do
  @moduledoc """
  Hermes MCP Server for Aitlas Backend Template.

  This is the reference MCP implementation for all Aitlas products.
  Uses Hermes' component-based architecture.

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

      defmodule Aitlas.MCP.Tools.Echo do
        @behaviour Hermes.Server.Behaviour.Tool

        @impl true
        def name, do: "echo"

        @impl true
        def description, do: "Echoes the input text"

        @impl true
        def input_schema do
          %{
            "type" => "object",
            "properties" => %{
              "text" => %{"type" => "string", "description" => "Text to echo"}
            },
            "required" => ["text"]
          }
        end

        @impl true
        def execute(%{"text" => text}, _frame) do
          {:ok, text}
        end
      end

  Then add it to this server:

      component Aitlas.MCP.Tools.Echo
  """

  use Hermes.Server,
    name: "Aitlas",
    version: "1.0.0",
    capabilities: [:tools]

  # Register tools as components
  component Aitlas.MCP.Tools.Echo
  # Add more tools here as you create them

  @impl true
  def init(client_info, frame) do
    # Initialize server state
    # Extract user context from client_info if provided
    user_id = get_in(client_info, ["_meta", "user_id"])

    frame = Hermes.Server.Frame.assign(frame, user_id: user_id)
    {:ok, frame}
  end
end