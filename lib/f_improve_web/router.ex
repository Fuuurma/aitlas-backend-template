defmodule FImproveWeb.Router do
  @moduledoc """
  Router for f.improve API.
  """
  
  use FImproveWeb, :router
  
  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: ["http://localhost:3000", "https://improve.f.xyz"]
  end
  
  pipeline :authenticated do
    plug FImproveWeb.Plugs.Auth
  end
  
  scope "/api", FImproveWeb do
    pipe_through :api
    
    get "/health", HealthController, :index
    post "/mcp", MCPController, :handle
  end
  
  scope "/api", FImproveWeb do
    pipe_through [:api, :authenticated]
    
    # Jobs
    get "/jobs", JobsController, :index
    post "/jobs", JobsController, :create
    get "/jobs/:id", JobsController, :show
    get "/jobs/:id/experiments", JobsController, :experiments
    
    # Experiments (like results.tsv)
    get "/experiments/:job_id", ExperimentsController, :index
    get "/experiments/:job_id/tsv", ExperimentsController, :tsv
  end
end