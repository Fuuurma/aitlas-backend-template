defmodule FImprove.Repo.Migrations.CreateJobs do
  use Ecto.Migration
  
  def change do
    create table(:jobs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, :string, null: false
      add :tag, :string, null: false
      add :code, :text, null: false
      add :benchmark, :string, null: false
      add :goal, :string, null: false
      add :iterations, :integer, default: 10
      add :status, :string, default: "pending"
      add :best_code, :text
      add :improvement_percent, :float
      
      timestamps()
    end
    
    create index(:jobs, [:user_id])
    create index(:jobs, [:tag])
  end
end