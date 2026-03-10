defmodule Aitlas.Accounts.Session do
  @moduledoc """
  Session schema for user authentication.

  Sessions are created by the frontend (Better Auth) and validated
  by `AitlasWeb.Plugs.Auth`. The `token` is used for Bearer auth.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "sessions" do
    field(:expires_at, :utc_datetime)
    field(:token, :string)
    field(:ip_address, :string)
    field(:user_agent, :string)
    field(:user_id, :string)

    timestamps()
  end

  @doc """
  Changeset for session creation and updates.
  """
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:id, :expires_at, :token, :ip_address, :user_agent, :user_id])
    |> validate_required([:id, :expires_at, :token, :user_id])
    |> unique_constraint(:token)
  end
end
