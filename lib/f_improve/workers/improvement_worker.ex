defmodule FImprove.Workers.ImprovementWorker do
  @moduledoc """
  Oban worker for running improvement loops.
  
  Like autoresearch running overnight, this worker
  iteratively improves code in the background.
  """
  
  use Oban.Worker, queue: :improvements, max_attempts: 1
  
  alias FImprove.{Jobs, Sandbox}
  
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"job_id" => job_id}}) do
    job = Jobs.get_job(job_id)
    
    # Run baseline
    {:ok, baseline} = Sandbox.execute(job.code, job.benchmark)
    
    # Run improvement loop
    result = FImprove.run_improvement_loop(job)
    
    # Update job with results
    Jobs.update_job(job, %{
      status: "completed",
      best_code: result.improved_code,
      improvement_percent: result.improvement_percent
    })
    
    :ok
  end
end