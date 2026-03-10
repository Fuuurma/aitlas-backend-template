defmodule Aitlas.Repo.Migrations.CreateApiKeysAndCredits do
  use Ecto.Migration

  def change do
    create table(:api_keys) do
      add :user_id, references(:users, type: :string, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :encrypted_key, :text, null: false
      add :iv, :string, null: false
      add :hint, :string

      timestamps()
    end

    create index(:api_keys, [:user_id, :provider])

    create table(:credit_ledger) do
      add :user_id, references(:users, type: :string, on_delete: :delete_all), null: false
      add :amount, :integer, null: false
      add :balance, :integer, null: false
      add :reason, :string, null: false
      add :reference_id, :string

      timestamps(updated_at: false)
    end

    create index(:credit_ledger, [:user_id, :inserted_at])
  end
end
