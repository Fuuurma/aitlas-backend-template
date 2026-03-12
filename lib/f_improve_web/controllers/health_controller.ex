defmodule FImproveWeb.HealthController do
  @moduledoc """
  Health check endpoint.
  """
  
  use FImproveWeb, :controller
  
  def index(conn, _params) do
    json(conn, %{
      status: "ok",
      service: "f.improve",
      version: "1.0.0",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end
end