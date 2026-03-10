defmodule AitlasWeb.Plugs.MCPAuth do
  @moduledoc """
  MCP endpoint authentication plug.

  Supports two authentication methods:
  - Internal: `x-furma-internal` header (service-to-service)
  - External: `Authorization: Bearer <MCP_API_KEY>` (external clients)

  On success, assigns `:mcp_caller` as `:internal` or `:external`.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, _opts) do
    internal_secret = Application.get_env(:aitlas, :furma_internal_secret)
    mcp_api_key = Application.get_env(:aitlas, :mcp_api_key)

    internal_header = get_req_header(conn, "x-furma-internal")
    auth_header = get_req_header(conn, "authorization")

    cond do
      internal_header == [internal_secret] ->
        assign(conn, :mcp_caller, :internal)

      auth_header == ["Bearer #{mcp_api_key}"] ->
        assign(conn, :mcp_caller, :external)

      true ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "unauthorized", code: -32_002})
        |> halt()
    end
  end
end
