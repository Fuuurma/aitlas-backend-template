defmodule Aitlas.Credits.LedgerEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "credit_ledger" do
    field :user_id, :string
    field :amount, :integer
    field :balance, :integer
    field :reason, :string
    field :reference_id, :string

    timestamps(updated_at: false)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:user_id, :amount, :balance, :reason, :reference_id])
    |> validate_required([:user_id, :amount, :balance, :reason])
  end
end