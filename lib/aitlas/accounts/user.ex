defmodule Aitlas.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "users" do
    field :name, :string
    field :email, :string
    field :email_verified, :boolean, default: false
    field :image, :string

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :name, :email, :email_verified, :image])
    |> validate_required([:id, :name, :email])
    |> unique_constraint(:email)
  end
end