defmodule FImprove.Experiments do
  @moduledoc """
  Experiment tracking - like results.tsv in autoresearch.
  
  Every experiment is logged with:
  - commit hash
  - val_bpb (or equivalent metric)
  - memory_gb
  - status (keep/discard/crash)
  - description
  """
  
  alias FImprove.Repo
  alias FImprove.Experiments.Experiment
  
  def create_experiment(attrs) do
    %Experiment{}
    |> Experiment.changeset(attrs)
    |> Repo.insert()
  end
  
  def list_experiments(job_id) do
    import Ecto.Query
    from(e in Experiment, where: e.job_id == ^job_id, order_by: [desc: e.inserted_at])
    |> Repo.all()
  end
  
  def get_best_experiment(job_id) do
    import Ecto.Query
    from(e in Experiment, where: e.job_id == ^job_id and e.status == "keep", order_by: [asc: e.metric_value], limit: 1)
    |> Repo.one()
  end
  
  def format_tsv(experiments) do
    header = "commit\tval_bpb\tmemory_gb\tstatus\tdescription\n"
    rows = Enum.map(experiments, fn e ->
      "#{e.commit}\t#{e.metric_value}\t#{e.memory_gb}\t#{e.status}\t#{e.description}"
    end)
    header <> Enum.join(rows, "\n")
  end
end