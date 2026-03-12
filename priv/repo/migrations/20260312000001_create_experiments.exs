defmodule FImprove.Repo.Migrations.CreateExperiments do
  use Ecto.Migration
  
  def change do
    create table(:experiments, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :job_id, references(:jobs, type: :uuid, on_delete: :delete_all), null: false
      add :iteration, :integer, null: false
      add :commit, :string, null: false
      add :hypothesis, :text
      add :change, :text
      add :metric_value, :float
      add :memory_gb, :float
      add :status, :string, null: false
      add :description, :text
      add :code_snapshot, :text
      
      timestamps()
    end
    
    create index(:experiments, [:job_id])
    create index(:experiments, [:job_id, :iteration])
  end
end