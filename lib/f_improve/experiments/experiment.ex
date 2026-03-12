defmodule FImprove.Experiments.Experiment do
  @moduledoc """
  Experiment schema - one row per iteration.
  
  Like results.tsv in autoresearch:
  - commit: short hash identifying this version
  - val_bpb: primary metric (lower is better)
  - memory_gb: peak memory usage
  - status: keep | discard | crash
  - description: what this experiment tried
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  
  schema "experiments" do
    field :job_id, :string
    field :iteration, :integer
    field :commit, :string
    field :hypothesis, :string
    field :change, :string
    field :metric_value, :float
    field :memory_gb, :float
    field :status, :string  # keep | discard | crash
    field :description, :string
    field :code_snapshot, :string
    
    timestamps()
  end
  
  def changeset(experiment, attrs) do
    experiment
    |> cast(attrs, [:job_id, :iteration, :commit, :hypothesis, :change, :metric_value, :memory_gb, :status, :description, :code_snapshot])
    |> validate_required([:job_id, :iteration, :commit, :status])
  end
end