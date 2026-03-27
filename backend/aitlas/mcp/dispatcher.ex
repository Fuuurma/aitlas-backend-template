defmodule Aitlas.MCP.Dispatcher do
  @moduledoc """
  JSON-RPC 2.0 dispatcher for MCP (Model Context Protocol) requests.

  Handles:
  - `initialize` - Protocol handshake
  - `ping` - Health check
  - `tools/list` - List available tools
  - `tools/call` - Execute a tool
  """

  alias Aitlas.MCP.Tools

  @doc """
  Dispatch a JSON-RPC request to the appropriate handler.
  """
  def dispatch(%{"method" => "initialize"}, _assigns) do
    {:ok,
     %{
       protocolVersion: "2024-11-05",
       serverInfo: %{name: "aitlas", version: "1.0.0"},
       capabilities: %{tools: %{}}
     }}
  end

  def dispatch(%{"method" => "ping"}, _assigns) do
    {:ok, %{}}
  end

  def dispatch(%{"method" => "tools/list"}, _assigns) do
    {:ok, %{tools: Tools.list()}}
  end

  def dispatch(%{"method" => "tools/call", "params" => params}, assigns) do
    tool_name = params["name"]
    arguments = params["arguments"] || %{}

    Tools.call(tool_name, arguments, assigns)
  end

  def dispatch(%{"method" => method}, _assigns) do
    {:error, %{code: -32_601, message: "Method not found: #{method}"}}
  end

  def dispatch(_, _assigns) do
    {:error, %{code: -32_600, message: "Invalid request"}}
  end
end
