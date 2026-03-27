defmodule AitlasWeb.MCPController do
  @moduledoc """
  MCP (Model Context Protocol) controller.

  Handles JSON-RPC 2.0 requests at POST /api/mcp.
  Dispatches to `Aitlas.MCP.Dispatcher` for method handling.
  """

  use AitlasWeb, :controller

  alias Aitlas.MCP.Dispatcher

  @doc """
  POST /api/mcp
  JSON-RPC 2.0 entry point for all tool calls.
  """
  def handle(conn, params) do
    case Dispatcher.dispatch(params, conn.assigns) do
      {:ok, result} ->
        json(conn, %{
          jsonrpc: "2.0",
          id: params["id"],
          result: result
        })

      {:error, %{code: code, message: message}} ->
        json(conn, %{
          jsonrpc: "2.0",
          id: params["id"],
          error: %{code: code, message: message}
        })
    end
  end
end
