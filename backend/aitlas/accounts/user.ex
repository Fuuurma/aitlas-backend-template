defmodule Aitlas.Accounts.User do
  @moduledoc """
  User schema for Aitlas accounts.

  Users are created by the frontend (Better Auth) and synced here.
  The `id` is a string (cuid) from the auth provider.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:email_verified, :boolean, default: false)
    field(:image, :string)

    timestamps()
  end

  @doc """
  Changeset for user creation and updates.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :name, :email, :email_verified, :image])
    |> validate_required([:id, :name, :email])
    |> unique_constraint(:email)
  end
end
