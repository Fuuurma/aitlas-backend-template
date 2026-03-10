defmodule AitlasWeb.Router do
  @moduledoc """
  Phoenix router for Aitlas API.

  ## Pipelines

  - `:api` - Base API pipeline (CORS, JSON, session)
  - `:authenticated` - User session validation
  - `:internal` - Service-to-service auth
  - `:mcp_auth` - MCP endpoint auth

  ## Routes

  - GET /api/health - Health check (public)
  - POST /api/mcp - MCP endpoint (MCP auth)
  - /internal/* - Internal API (internal auth)
  - /api/* - User API (session auth)
  """

  use AitlasWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)

    plug(CORSPlug,
      origin: [
        ~r/https:\/\/.*\.aitlas\.xyz/,
        ~r/https:\/\/.*\.f\.xyz/,
        "http://localhost:3000",
        "http://localhost:3001"
      ],
      methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      headers: ["Authorization", "Content-Type", "X-Furma-Internal"]
    )
  end

  pipeline :authenticated do
    plug(AitlasWeb.Plugs.Auth)
  end

  pipeline :internal do
    plug(AitlasWeb.Plugs.InternalAuth)
  end

  pipeline :mcp_auth do
    plug(AitlasWeb.Plugs.MCPAuth)
  end

  scope "/api", AitlasWeb do
    pipe_through(:api)
    get("/health", HealthController, :index)
  end

  scope "/api", AitlasWeb do
    pipe_through([:api, :mcp_auth])
    post("/mcp", MCPController, :handle)
  end

  scope "/internal", AitlasWeb do
    pipe_through([:api, :internal])
  end

  scope "/api", AitlasWeb do
    pipe_through([:api, :authenticated])
  end
end
