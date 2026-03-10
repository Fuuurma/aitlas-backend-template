defmodule Aitlas.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add :id, :string, primary_key: true
      add :expires_at, :utc_datetime, null: false
      add :token, :string, null: false
      add :ip_address, :string
      add :user_agent, :string
      add :user_id, references(:users, type: :string, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:sessions, [:token])
    create index(:sessions, [:user_id])
  end
end