defmodule FImproveWeb.JobsController do
  @moduledoc """
  Jobs API controller.
  """
  
  use FImproveWeb, :controller
  
  alias FImprove.{Jobs, Experiments}
  
  def index(conn, _params) do
    user_id = conn.assigns[:current_user_id]
    jobs = Jobs.list_jobs(user_id)
    json(conn, %{jobs: jobs})
  end
  
  def create(conn, params) do
    user_id = conn.assigns[:current_user_id]
    
    attrs = %{
      user_id: user_id,
      tag: generate_tag(),
      code: params["code"],
      benchmark: params["benchmark"],
      goal: params["goal"],
      iterations: params["iterations"] || 10,
      status: "pending"
    }
    
    case Jobs.create_job(attrs) do
      {:ok, job} ->
        # Dispatch to worker
        %{job_id: job.id}
        |> FImprove.Workers.ImprovementWorker.new()
        |> Oban.insert()
        
        conn
        |> put_status(:created)
        |> json(%{job_id: job.id, status: "started"})
        
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end
  
  def show(conn, %{"id" => id}) do
    case Jobs.get_job(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "not_found"})
        
      job ->
        json(conn, %{job: job})
    end
  end
  
  def experiments(conn, %{"id" => id}) do
    experiments = Experiments.list_experiments(id)
    json(conn, %{experiments: experiments})
  end
  
  defp generate_tag do
    date = Date.utc_today() |> Calendar.strftime("%b%d" |> String.downcase())
    rand = :crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)
    "#{date}-#{rand}"
  end
  
  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end