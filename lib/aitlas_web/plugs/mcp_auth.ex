defmodule AitlasWeb.Plugs.MCPAuth do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

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
        |> json(%{error: "unauthorized", code: -32002})
        |> halt()
    end
  end
end