defmodule FImprove do
  @moduledoc """
  f.improve — Autonomous code improvement.
  
  Like Karpathy's autoresearch, this runs an iterative improvement loop:
  
      ANALYZE → HYPOTHESIZE → EXPERIMENT → MEASURE → ITERATE
  
  Each iteration:
    1. LLM analyzes code and proposes improvement
    2. Change is applied
    3. Benchmark runs in Docker sandbox
    4. Metric is captured
    5. If improved, keep. Otherwise discard.
    6. Repeat until plateau or iterations exhausted
  """
  
  alias FImprove.{Jobs, Experiments, Sandbox, LLM, Metrics}
  
  @doc """
  Run improvement loop for a job.
  
  This is the main entry point, called by the Oban worker.
  """
  def run_improvement_loop(job) do
    # Run baseline
    {:ok, baseline_result} = Sandbox.execute(job.code, job.benchmark)
    baseline_metric = Metrics.parse(baseline_result.output)
    
    # Log baseline experiment
    create_experiment(job.id, 0, "baseline", job.code, baseline_metric, baseline_result, "keep")
    
    # Run improvement iterations
    result = run_iterations(job, job.code, baseline_metric, 1, job.iterations)
    
    result
  end
  
  defp run_iterations(job, current_code, current_metric, iteration, max_iterations) 
       when iteration > max_iterations do
    # Done - return best result
    %{
      improved_code: current_code,
      improvement_percent: 0.0,
      iterations: max_iterations
    }
  end
  
  defp run_iterations(job, current_code, current_metric, iteration, max_iterations) do
    # Generate hypothesis
    case LLM.generate_hypothesis(job.user_id, current_code, job.goal, current_metric) do
      {:ok, hypothesis} ->
        # Run experiment
        case Sandbox.execute(hypothesis.modified_code, job.benchmark) do
          {:ok, result} ->
            new_metric = Metrics.parse(result.output)
            improvement = Metrics.compare(current_metric, new_metric)
            
            # Determine status
            status = if improvement > 0, do: "keep", else: "discard"
            
            # Log experiment
            create_experiment(
              job.id,
              iteration,
              hypothesis.hypothesis,
              hypothesis.modified_code,
              new_metric,
              result,
              status
            )
            
            # Continue with best code
            next_code = if improvement > 0, do: hypothesis.modified_code, else: current_code
            next_metric = if improvement > 0, do: new_metric, else: current_metric
            
            run_iterations(job, next_code, next_metric, iteration + 1, max_iterations)
            
          {:error, reason} ->
            # Experiment crashed
            create_experiment(job.id, iteration, hypothesis.hypothesis, hypothesis.modified_code, nil, nil, "crash")
            run_iterations(job, current_code, current_metric, iteration + 1, max_iterations)
        end
        
      {:error, reason} ->
        # LLM failed - skip iteration
        run_iterations(job, current_code, current_metric, iteration + 1, max_iterations)
    end
  end
  
  defp create_experiment(job_id, iteration, hypothesis, code, metric, result, status) do
    Experiments.create_experiment(%{
      job_id: job_id,
      iteration: iteration,
      commit: generate_commit_hash(),
      hypothesis: hypothesis,
      change: "",
      metric_value: metric,
      memory_gb: if(result, do: result.memory_mb / 1024, else: 0.0),
      status: status,
      description: hypothesis,
      code_snapshot: code
    })
  end
  
  defp generate_commit_hash do
    :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
  end
end