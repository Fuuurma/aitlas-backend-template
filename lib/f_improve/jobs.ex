defmodule FImprove.Jobs do
  @moduledoc """
  Job management for improvement tasks.
  
  Like autoresearch's run tag (e.g., `mar5`), each job is an
  isolated improvement run with its own experiments.
  """
  
  alias FImprove.Repo
  alias FImprove.Jobs.Job
  
  def create_job(attrs) do
    %Job{}
    |> Job.changeset(attrs)
    |> Repo.insert()
  end
  
  def get_job(id), do: Repo.get(Job, id)
  
  def update_job(job, attrs) do
    job
    |> Job.changeset(attrs)
    |> Repo.update()
  end
  
  def list_jobs(user_id) do
    import Ecto.Query
    from(j in Job, where: j.user_id == ^user_id, order_by: [desc: j.inserted_at])
    |> Repo.all()
  end
end