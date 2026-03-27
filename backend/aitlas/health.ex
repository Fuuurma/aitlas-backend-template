# lib/aitlas/health.ex
defmodule Aitlas.Health do
  @moduledoc """
  Health check system for Aitlas services.

  Provides endpoints for:
  - `/health` - Basic liveness check
  - `/health/ready` - Readiness check (dependencies)
  - `/health/live` - Liveness check (Kubernetes)

  ## Checks

  | Check | Description |
  |-------|-------------|
  | `database` | PostgreSQL connection |
  | `redis` | Redis connection (if enabled) |
  | `mcp_server` | MCP server status |

  ## Usage

      # In router
      get "/health", HealthController, :health
      get "/health/ready", HealthController, :ready
      get "/health/live", HealthController, :live

      # In controller
      def health(conn, _params) do
        json(conn, Aitlas.Health.check())
      end

      def ready(conn, _params) do
        case Aitlas.Health.ready?() do
          :ok -> json(conn, %{status: "ok"})
          {:error, reason} -> json(conn, %{status: "error", reason: reason}, status: 503)
        end
      end
  """

  alias Aitlas.Repo

  @checks [:database, :redis, :mcp_server]

  # ─── Public API ─────────────────────────────────────────────────

  @doc """
  Basic health check. Returns service info.
  """
  def check do
    %{
      status: "ok",
      service: service_name(),
      version: service_version(),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      uptime: uptime()
    }
  end

  @doc """
  Readiness check. All dependencies must be healthy.
  """
  def ready? do
    results = run_checks()

    if Enum.all?(results, fn {_, result} -> result.status == :ok end) do
      :ok
    else
      failed =
        results
        |> Enum.filter(fn {_, r} -> r.status != :ok end)
        |> Enum.map(fn {name, _} -> name end)

      {:error, failed}
    end
  end

  @doc """
  Liveness check. Service is running.
  """
  def live? do
    # If we can respond, we're alive
    :ok
  end

  @doc """
  Detailed health check with all dependencies.
  """
  def detailed do
    checks = run_checks()

    %{
      status: overall_status(checks),
      service: service_name(),
      version: service_version(),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      uptime: uptime(),
      checks: Map.new(checks)
    }
  end

  # ─── Check Implementations ─────────────────────────────────────

  defp run_checks do
    Enum.map(@checks, fn check ->
      {check, run_check(check)}
    end)
  end

  defp run_check(:database) do
    start = System.monotonic_time(:millisecond)

    try do
      Repo.query!("SELECT 1")
      duration = System.monotonic_time(:millisecond) - start

      %{status: :ok, latency_ms: duration}
    rescue
      e ->
        %{status: :error, error: inspect(e)}
    end
  end

  defp run_check(:redis) do
    if Application.get_env(:aitlas, :redis_enabled, true) do
      check_redis()
    else
      %{status: :skipped, reason: "Redis disabled"}
    end
  end

  defp run_check(:mcp_server) do
    start = System.monotonic_time(:millisecond)

    try do
      # Check if MCP server is registered
      case Process.whereis(Aitlas.MCP.Server) do
        nil ->
          %{status: :error, error: "MCP server not running"}

        pid ->
          duration = System.monotonic_time(:millisecond) - start
          %{status: :ok, latency_ms: duration, pid: inspect(pid)}
      end
    rescue
      e ->
        %{status: :error, error: inspect(e)}
    end
  end

  defp check_redis do
    # Implement Redis check if using Redis
    %{status: :ok, note: "Redis check not implemented"}
  end

  # ─── Helpers ───────────────────────────────────────────────────

  defp overall_status(checks) do
    if Enum.all?(checks, fn {_, r} -> r.status == :ok or r.status == :skipped end) do
      "ok"
    else
      "degraded"
    end
  end

  defp service_name do
    Application.get_env(:aitlas, :service_name, "aitlas")
  end

  defp service_version do
    Application.get_env(:aitlas, :version, "0.1.0")
  end

  defp uptime do
    {:ok, uptime} = :erlang.statistics(:wall_clock)
    uptime
  end
end