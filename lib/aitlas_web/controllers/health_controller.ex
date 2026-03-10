defmodule AitlasWeb.HealthController do
  @moduledoc """
  Health check controller for monitoring and load balancers.

  GET /api/health returns service status and database connectivity.
  """

  use AitlasWeb, :controller

  @doc """
  GET /api/health
  Returns service health status.
  """
  def index(conn, _params) do
    case Aitlas.Repo.query("SELECT 1") do
      {:ok, _} ->
        json(conn, %{
          status: "ok",
          db: "connected",
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
        })

      {:error, _} ->
        conn
        |> put_status(503)
        |> json(%{status: "error", db: "disconnected"})
    end
  end
end
