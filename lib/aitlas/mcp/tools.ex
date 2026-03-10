defmodule Aitlas.MCP.Tools do
  @moduledoc """
  MCP Tools registry and execution.

  Add tool definitions to `list/0` and implement them in `call/3`.
  Each tool has:
  - `name` - Unique identifier
  - `description` - Human-readable description
  - `inputSchema` - JSON Schema for arguments
  - `creditCost` - Credits consumed per call
  """

  @doc """
  Return the list of tools this action exposes.
  """
  def list do
    [
      %{
        name: "execute_agent",
        description: "Execute an AI agent with a task",
        inputSchema: %{
          type: "object",
          properties: %{
            agent_id: %{type: "string", description: "The agent to execute"},
            task: %{type: "string", description: "The task description"},
            context: %{type: "object", description: "Additional context"}
          },
          required: ["agent_id", "task"]
        },
        creditCost: 10
      },
      %{
        name: "get_task_status",
        description: "Get the status of a running task",
        inputSchema: %{
          type: "object",
          properties: %{
            task_id: %{type: "string", description: "The task ID"}
          },
          required: ["task_id"]
        },
        creditCost: 0
      }
    ]
  end

  @doc """
  Execute a tool by name.
  Pattern match to add new tools.
  """
  def call("execute_agent", %{"agent_id" => agent_id, "task" => task} = args, assigns) do
    _context = Map.get(args, "context", %{})
    user_id = Map.get(assigns, :current_user_id)

    {:ok,
     %{
       content: [%{type: "text", text: "Agent #{agent_id} executing: #{task}"}],
       task_id: "task_#{:erlang.unique_integer([:positive])}",
       user_id: user_id
     }}
  end

  def call("get_task_status", %{"task_id" => task_id}, _assigns) do
    {:ok,
     %{
       content: [%{type: "text", text: "Task #{task_id} status: running"}]
     }}
  end

  def call(name, _arguments, _assigns) do
    {:error, %{code: -32_601, message: "Tool not found: #{name}"}}
  end
end
