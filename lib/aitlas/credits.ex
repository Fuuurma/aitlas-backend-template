defmodule Aitlas.Credits do
  import Ecto.Query
  alias Aitlas.Repo
  alias Aitlas.Credits.LedgerEntry

  @doc """
  Get current balance for a user.
  Reads the most recent ledger balance snapshot.
  """
  def get_balance(user_id) do
    query =
      from l in LedgerEntry,
        where: l.user_id == ^user_id,
        order_by: [desc: l.inserted_at],
        limit: 1,
        select: l.balance

    Repo.one(query) || 0
  end

  @doc """
  Check if user has enough credits.
  """
  def has_credits?(user_id, amount) do
    get_balance(user_id) >= amount
  end

  @doc """
  Reserve credits (pre-check on task dispatch).
  Returns {:ok, reservation_id} or {:error, :insufficient_credits}
  """
  def reserve(user_id, amount, reference_id) do
    Repo.with_transaction(fn ->
      current = get_balance(user_id)

      if current < amount do
        {:error, :insufficient_credits}
      else
        append_entry(user_id, -amount, current - amount, "reserve", reference_id)
      end
    end)
  end

  @doc """
  Deduct credits after successful tool execution.
  """
  def deduct(user_id, amount, reason, reference_id) do
    Repo.with_transaction(fn ->
      current = get_balance(user_id)
      append_entry(user_id, -amount, current - amount, reason, reference_id)
    end)
  end

  @doc """
  Refund credits (failed task, unused reservation).
  """
  def refund(user_id, amount, reference_id) do
    Repo.with_transaction(fn ->
      current = get_balance(user_id)
      append_entry(user_id, amount, current + amount, "refund", reference_id)
    end)
  end

  @doc """
  Grant credits (subscription, purchase, promo).
  """
  def grant(user_id, amount, reason, reference_id \\ nil) do
    Repo.with_transaction(fn ->
      current = get_balance(user_id)
      append_entry(user_id, amount, current + amount, reason, reference_id)
    end)
  end

  defp append_entry(user_id, amount, new_balance, reason, reference_id) do
    %LedgerEntry{}
    |> LedgerEntry.changeset(%{
      user_id: user_id,
      amount: amount,
      balance: new_balance,
      reason: reason,
      reference_id: reference_id
    })
    |> Repo.insert()
  end
end