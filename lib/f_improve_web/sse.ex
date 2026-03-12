defmodule FImproveWeb.SSE do
  @moduledoc """
  Server-Sent Events for real-time job updates.
  
  Like autoresearch's live logs, clients can watch
  experiments appear in real-time.
  """
  
  alias FImprove.Repo
  alias FImprove.Experiments.Experiment
  
  def subscribe(job_id) do
    # Subscribe to job updates
    Phoenix.PubSub.subscribe(FImprove.PubSub, "job:#{job_id}")
  end
  
  def broadcast_experiment(experiment) do
    Phoenix.PubSub.broadcast(
      FImprove.PubSub,
      "job:#{experiment.job_id}",
      {:experiment, experiment}
    )
  end
  
  def stream(job_id, callback) do
    # Initial state
    callback.(:init, %{job_id: job_id})
    
    # Subscribe to updates
    subscribe(job_id)
    
    receive_loop(callback)
  end
  
  defp receive_loop(callback) do
    receive do
      {:experiment, experiment} ->
        callback.(:experiment, format_experiment(experiment))
        receive_loop(callback)
        
      {:job_completed, job} ->
        callback.(:completed, job)
        
      {:job_failed, error} ->
        callback.(:error, error)
        
      after 300_000 ->
        # 5 minute timeout
        callback.(:timeout, %{})
    end
  end
  
  defp format_experiment(experiment) do
    %{
      id: experiment.id,
      iteration: experiment.iteration,
      commit: experiment.commit,
      hypothesis: experiment.hypothesis,
      metric_value: experiment.metric_value,
      status: experiment.status,
      description: experiment.description,
      inserted_at: experiment.inserted_at
    }
  end
end