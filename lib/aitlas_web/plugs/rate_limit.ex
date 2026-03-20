# lib/aitlas_web/plugs/rate_limit.ex
defmodule AitlasWeb.Plugs.RateLimit do
  @moduledoc """
  Rate limiting plug using Hammer.

  Protects API endpoints from abuse with configurable limits.

  ## Configuration

      config :aitlas, :rate_limit,
        default: {100, 60_000},      # 100 req/min
        auth: {10, 60_000},          # 10 auth attempts/min
        api: {300, 60_000},          # 300 API calls/min
        mcp: {1000, 60_000}          # 1000 MCP calls/min

  ## Usage

      # In router
      pipeline :api do
        plug AitlasWeb.Plugs.RateLimit, limit: :api
      end

      # Custom limit
      plug AitlasWeb.Plugs.RateLimit, max: 50, window_ms: 60_000

      # By user ID
      plug AitlasWeb.Plugs.RateLimit, key: :user_id

  ## Response Headers

  - `x-ratelimit-limit` - Maximum requests per window
  - `x-ratelimit-remaining` - Remaining requests
  - `x-ratelimit-reset` - Unix timestamp when window resets
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias Hammer

  @default_limit {100, 60_000} # 100 req/min

  def init(opts) do
    limit = Keyword.get(opts, :limit)
    max = Keyword.get(opts, :max)
    window_ms = Keyword.get(opts, :window_ms, 60_000)
    key = Keyword.get(opts, :key, :ip)

    config =
      if limit do
        Application.get_env(:aitlas, :rate_limit, [])
        |> Keyword.get(limit, @default_limit)
      else
        {max || elem(@default_limit, 0), window_ms}
      end

    %{
      max: elem(config, 0),
      window_ms: elem(config, 1),
      key_type: key
    }
  end

  def call(conn, %{max: max, window_ms: window_ms, key_type: key_type}) do
    key = get_rate_limit_key(conn, key_type)

    case Hammer.check_rate("plug:#{key}", window_ms, max) do
      {:allow, count} ->
        remaining = max - count
        reset = get_reset_timestamp(window_ms)

        conn
        |> put_resp_header("x-ratelimit-limit", Integer.to_string(max))
        |> put_resp_header("x-ratelimit-remaining", Integer.to_string(remaining))
        |> put_resp_header("x-ratelimit-reset", Integer.to_string(reset))

      {:deny, _limit} ->
        reset = get_reset_timestamp(window_ms)

        conn
        |> put_resp_header("x-ratelimit-limit", Integer.to_string(max))
        |> put_resp_header("x-ratelimit-remaining", "0")
        |> put_resp_header("x-ratelimit-reset", Integer.to_string(reset))
        |> put_status(:too_many_requests)
        |> json(%{
          error: "Rate limit exceeded",
          code: "rate_limited",
          retry_after: div(window_ms, 1000)
        })
        |> halt()
    end
  end

  # ─── Key Generation ─────────────────────────────────────────────

  defp get_rate_limit_key(conn, :ip) do
    conn.remote_ip
    |> :inet.ntoa()
    |> to_string()
  end

  defp get_rate_limit_key(conn, :user_id) do
    case conn.assigns[:current_user_id] do
      nil -> get_rate_limit_key(conn, :ip)
      user_id -> "user:#{user_id}"
    end
  end

  defp get_rate_limit_key(conn, :session) do
    case conn.assigns[:current_session] do
      nil -> get_rate_limit_key(conn, :ip)
      session -> "session:#{session.id}"
    end
  end

  defp get_rate_limit_key(conn, :api_key) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> "token:#{:erlang.phash2(token)}"
      _ -> get_rate_limit_key(conn, :ip)
    end
  end

  defp get_rate_limit_key(conn, custom) when is_function(custom, 1) do
    custom.(conn)
  end

  # ─── Helpers ────────────────────────────────────────────────────

  defp get_reset_timestamp(window_ms) do
    now = System.system_time(:second)
    window_seconds = div(window_ms, 1000)
    now + window_seconds
  end
end