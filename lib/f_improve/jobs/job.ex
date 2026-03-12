defmodule FImprove.Jobs.Job do
  @moduledoc """
  Job schema - one improvement run.
  
  Like autoresearch's branch `autoresearch/<tag>`, each job
  represents one autonomous improvement session.
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  
  schema "jobs" do
    field :user_id, :string
    field :tag, :string  # e.g., "mar12-fibonacci"
    field :code, :string
    field :benchmark, :string
    field :goal, :string  # performance | quality | coverage | bugs
    field :iterations, :integer, default: 10
    field :status, :string, default: "pending"  # pending | running | completed | failed
    field :best_code, :string
    field :improvement_percent, :float
    
    timestamps()
  end
  
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:user_id, :tag, :code, :benchmark, :goal, :iterations, :status, :best_code, :improvement_percent])
    |> validate_required([:user_id, :tag, :code, :benchmark, :goal])
    |> validate_inclusion(:goal, ~w(performance quality coverage bugs refactor))
  end
end