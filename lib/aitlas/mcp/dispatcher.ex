defmodule Aitlas.MCP.Dispatcher do
  alias Aitlas.MCP.Tools

  def dispatch(%{"method" => "initialize"}, _assigns) do
    {:ok, %{
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
    {:error, %{code: -32601, message: "Method not found: #{method}"}}
  end

  def dispatch(_, _assigns) do
    {:error, %{code: -32600, message: "Invalid request"}}
  end
end