defmodule AitlasWeb.HealthController do
  use AitlasWeb, :controller

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