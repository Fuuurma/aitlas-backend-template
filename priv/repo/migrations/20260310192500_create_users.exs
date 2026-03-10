defmodule Aitlas.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :email, :string, null: false
      add :email_verified, :boolean, default: false, null: false
      add :image, :string

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end