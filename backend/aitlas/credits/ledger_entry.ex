defmodule Aitlas.Credits.LedgerEntry do
  @moduledoc """
  Credit ledger entry schema.

  Append-only ledger for tracking user credit balances.
  Each entry records:
  - `amount` - Credit change (positive = credit, negative = debit)
  - `balance` - Snapshot of balance after this entry
  - `reason` - Why the credit changed (e.g., "purchase", "tool_call")
  - `reference_id` - Optional reference (task_id, stripe_id, etc.)
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "credit_ledger" do
    field :user_id, :string
    field :amount, :integer
    field :balance, :integer
    field :reason, :string
    field :reference_id, :string

    timestamps(updated_at: false)
  end

  @doc """
  Changeset for ledger entry creation.
  """
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:user_id, :amount, :balance, :reason, :reference_id])
    |> validate_required([:user_id, :amount, :balance, :reason])
  end
end
