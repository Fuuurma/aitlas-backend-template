# lib/aitlas_web/plugs/cors.ex
defmodule AitlasWeb.Plugs.CORS do
  @moduledoc """
  CORS configuration for API endpoints.

  Allows requests from:
  - *.aitlas.xyz domains
  - *.f.xyz domains
  - Localhost development servers

  ## Headers Set

  - `Access-Control-Allow-Origin` - Allowed origins
  - `Access-Control-Allow-Methods` - GET, POST, PUT, DELETE, OPTIONS
  - `Access-Control-Allow-Headers` - Authorization, Content-Type, X-*
  - `Access-Control-Allow-Credentials` - true
  - `Access-Control-Max-Age` - 86400 (24 hours)

  ## Usage

      pipeline :api do
        plug AitlasWeb.Plugs.CORS
      end
  """

  import Plug.Conn

  @allowed_origins [
    ~r/https:\/\/[\w-]+\.aitlas\.xyz$/,
    ~r/https:\/\/[\w-]+\.f\.xyz$/,
    ~r/http:\/\/localhost:\d+$/,
    ~r/http:\/\/127\.0\.0\.1:\d+$/
  ]

  @allowed_methods ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]

  @allowed_headers [
    "authorization",
    "content-type",
    "x-request-id",
    "x-furma-internal",
    "x-correlation-id"
  ]

  @exposed_headers [
    "x-request-id",
    "x-ratelimit-limit",
    "x-ratelimit-remaining",
    "x-ratelimit-reset"
  ]

  @max_age 86_400

  def init(opts), do: opts

  def call(conn, _opts) do
    origin = get_req_header(conn, "origin") |> List.first()

    cond do
      is_nil(origin) ->
        conn

      allowed_origin?(origin) ->
        conn
        |> put_resp_header("access-control-allow-origin", origin)
        |> put_resp_header("access-control-allow-methods", Enum.join(@allowed_methods, ", "))
        |> put_resp_header("access-control-allow-headers", Enum.join(@allowed_headers, ", "))
        |> put_resp_header("access-control-allow-credentials", "true")
        |> put_resp_header("access-control-expose-headers", Enum.join(@exposed_headers, ", "))
        |> put_resp_header("access-control-max-age", Integer.to_string(@max_age))
        |> maybe_handle_preflight()

      true ->
        conn
    end
  end

  defp allowed_origin?(origin) do
    Enum.any?(@allowed_origins, fn pattern ->
      Regex.match?(pattern, origin)
    end)
  end

  defp maybe_handle_preflight(conn) do
    if conn.method == "OPTIONS" do
      conn
      |> send_resp(204, "")
      |> halt()
    else
      conn
    end
  end
end