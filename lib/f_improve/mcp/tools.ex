defmodule FImprove.MCP.Tools do
  @moduledoc """
  MCP tools for f.improve.
  
  Exposed via JSON-RPC 2.0 at /api/mcp
  """
  
  alias FImprove.{Jobs, Experiments}
  
  @tools [
    %{
      name: "improve_code",
      description: "Autonomously improve code by running benchmarks and measuring results",
      inputSchema: %{
        type: "object",
        properties: %{
          code: %{type: "string", description: "Code to improve"},
          benchmark: %{type: "string", description: "Benchmark command (e.g., 'node bench.js')"},
          goal: %{type: "string", enum: ~w(performance quality coverage bugs refactor)},
          iterations: %{type: "integer", default: 10}
        },
        required: ["code", "benchmark", "goal"]
      }
    },
    %{
      name: "quick_scan",
      description: "One-shot code analysis with improvement suggestions",
      inputSchema: %{
        type: "object",
        properties: %{
          code: %{type: "string"},
          goal: %{type: "string", enum: ~w(performance quality coverage bugs)}
        },
        required: ["code", "goal"]
      }
    },
    %{
      name: "get_experiments",
      description: "Get experiment log for a job",
      inputSchema: %{
        type: "object",
        properties: %{
          job_id: %{type: "string"}
        },
        required: ["job_id"]
      }
    }
  ]
  
  def list_tools, do: @tools
  
  def call("improve_code", params) do
    job = Jobs.create_job(%{
      user_id: params["user_id"] || "anonymous",
      tag: generate_tag(),
      code: params["code"],
      benchmark: params["benchmark"],
      goal: params["goal"],
      iterations: params["iterations"] || 10,
      status: "running"
    })
    
    # Dispatch to Oban worker
    %{job_id: job.id}
    |> FImprove.Workers.ImprovementWorker.new()
    |> Oban.insert()
    
    %{success: true, job_id: job.id, status: "started"}
  end
  
  def call("quick_scan", params) do
    # One-shot analysis
    suggestions = analyze_code(params["code"], params["goal"])
    %{suggestions: suggestions}
  end
  
  def call("get_experiments", params) do
    experiments = Experiments.list_experiments(params["job_id"])
    %{experiments: experiments}
  end
  
  defp generate_tag do
    date = Date.utc_today() |> Calendar.strftime("%b%d" |> String.downcase())
    rand = :crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)
    "#{date}-#{rand}"
  end
  
  defp analyze_code(code, goal) do
    # Placeholder - would call LLM
    [
      %{type: "optimization", description: "Consider using Map for O(1) lookups", line: 5},
      %{type: "refactor", description: "Extract repeated logic into function", line: 12}
    ]
  end
end