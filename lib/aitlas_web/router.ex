defmodule AitlasWeb.Router do
  use AitlasWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug CORSPlug,
      origin: [
        ~r/https:\/\/.*\.aitlas\.xyz/,
        ~r/https:\/\/.*\.f\.xyz/,
        "http://localhost:3000",
        "http://localhost:3001"
      ],
      methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      headers: ["Authorization", "Content-Type", "X-Furma-Internal"]
  end

  pipeline :authenticated do
    plug AitlasWeb.Plugs.Auth
  end

  pipeline :internal do
    plug AitlasWeb.Plugs.InternalAuth
  end

  pipeline :mcp_auth do
    plug AitlasWeb.Plugs.MCPAuth
  end

  # ── Health (public) ─────────────────────────────────────────
  scope "/api", AitlasWeb do
    pipe_through :api
    get "/health", HealthController, :index
  end

  # ── MCP (requires MCP_API_KEY or internal header) ───────────
  scope "/api", AitlasWeb do
    pipe_through [:api, :mcp_auth]
    post "/mcp", MCPController, :handle
  end

  # ── Internal API (Nexus → Action) ───────────────────────────
  scope "/internal", AitlasWeb do
    pipe_through [:api, :internal]
    # Add internal-only routes here
  end

  # ── Authenticated API (user session) ────────────────────────
  scope "/api", AitlasWeb do
    pipe_through [:api, :authenticated]
    # Add user-facing API routes here
  end
end