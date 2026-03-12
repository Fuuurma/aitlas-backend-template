defmodule FImprove do
  @moduledoc """
  f.improve — Autonomous Code Improvement

  Inspired by karpathy/autoresearch — AI agents that iteratively
  improve code by running experiments and measuring results.

  ## The Loop

  1. ANALYZE   — Read code, run baseline benchmark
  2. HYPOTHESIZE — Agent proposes improvement
  3. EXPERIMENT  — Apply change, run benchmark
  4. MEASURE     — Compare metrics (keep/discard)
  5. ITERATE     — Repeat until plateau

  ## Example

      job = FImprove.create_job(%{
        code: "function sort(arr) { ... }",
        benchmark: "node bench.js",
        goal: "performance",
        iterations: 10
      })

      {:ok, result} = FImprove.run_improvement_loop(job)
      # result.improved_code
      # result.baseline_metrics
      # result.final_metrics
      # result.improvement_percent
  """

  alias FImprove.{Experiments, Sandbox, Jobs}
  alias FImprove.Experiments.Experiment

  @doc """
  Create a new improvement job.
  """
  def create_job(attrs) do
    Jobs.create_job(attrs)
  end

  @doc """
  Run the improvement loop.

  This is the core autoresearch-style loop:
  1. Run baseline benchmark
  2. For each iteration:
     - Agent proposes change
     - Run benchmark
     - Compare metrics
     - Keep or discard
  3. Return best code found
  """
  def run_improvement_loop(job) do
    # Initialize results log (like results.tsv in autoresearch)
    {:ok, baseline} = run_benchmark(job.code, job.benchmark)

    experiments = []
    current_code = job.code
    best_metrics = baseline
    best_code = job.code
    iterations_without_improvement = 0

    # Run improvement loop
    result =
      Enum.reduce_while(1..job.iterations, {current_code, best_code, best_metrics, experiments}, fn i, {code, best, metrics, log} ->
        # 1. Generate hypothesis (agent proposes change)
        {:ok, hypothesis} = generate_hypothesis(code, job.goal, metrics, log)

        # 2. Apply change
        modified_code = apply_change(code, hypothesis.change)

        # 3. Run benchmark
        {:ok, new_metrics} = run_benchmark(modified_code, job.benchmark)

        # 4. Check if improvement
        is_improvement = check_improvement(new_metrics, metrics, job.goal)

        # 5. Log experiment
        experiment = %{
          iteration: i,
          hypothesis: hypothesis.description,
          change: hypothesis.change,
          metrics: new_metrics,
          kept: is_improvement,
          commit: generate_commit_hash()
        }

        log = log ++ [experiment]

        # 6. Update best if improved
        if is_improvement do
          {:cont, {modified_code, modified_code, new_metrics, log}}
        else
          {:cont, {code, best, metrics, log}}
        end
      end)

    {final_code, best_code, best_metrics, experiments} = result

    # Save experiments to DB
    Enum.each(experiments, &Experiments.create_experiment/1)

    {:ok, %{
      improved_code: best_code,
      baseline_metrics: baseline,
      final_metrics: best_metrics,
      improvement_percent: calculate_improvement(baseline, best_metrics, job.goal),
      iterations_used: length(experiments),
      experiments: experiments
    }}
  end

  @doc """
  Run a single benchmark in sandbox.
  """
  def run_benchmark(code, benchmark_cmd) do
    Sandbox.execute(code, benchmark_cmd)
  end

  # Private helpers

  defp generate_hypothesis(code, goal, best_metrics, log) do
    # In production, this calls the LLM via MCP
    # For now, return a placeholder
    {:ok, %{
      description: "Propose optimization for #{goal}",
      change: "// Placeholder change",
      reasoning: "Based on previous experiments"
    }}
  end

  defp apply_change(code, change) do
    # Apply the proposed change to the code
    # In production, this uses proper code manipulation
    code <> "\n" <> change
  end

  defp check_improvement(new_metrics, old_metrics, "performance") do
    # Lower is better for execution time
    new_metrics.time_ms < old_metrics.time_ms
  end

  defp check_improvement(new_metrics, old_metrics, "quality") do
    # Higher is better for quality score
    new_metrics.quality_score > old_metrics.quality_score
  end

  defp check_improvement(new_metrics, old_metrics, "coverage") do
    # Higher is better for coverage
    new_metrics.coverage_percent > old_metrics.coverage_percent
  end

  defp calculate_improvement(baseline, final, "performance") do
    ((baseline.time_ms - final.time_ms) / baseline.time_ms * 100)
    |> Float.round(1)
  end

  defp calculate_improvement(baseline, final, _goal) do
    ((final.primary_metric - baseline.primary_metric) / baseline.primary_metric * 100)
    |> Float.round(1)
  end

  defp generate_commit_hash do
    :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
  end
end