defmodule Aitlas.Repo do
  @moduledoc """
  Ecto repository for Aitlas with Neon Postgres.

  Provides database access and transaction management.
  Use `with_transaction/1` for all multi-step mutations to ensure
  atomicity and proper error handling.
  """

  use Ecto.Repo,
    otp_app: :aitlas,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Execute a function inside a transaction.

  Automatically rolls back if the function returns `{:error, reason}`.
  Use this for ALL credit mutations and multi-step database operations.

  ## Examples

      Repo.with_transaction(fn ->
        with {:ok, user} <- create_user(attrs),
             {:ok, session} <- create_session(user) do
          {:ok, %{user: user, session: session}}
        end
      end)
  """
  def with_transaction(fun) do
    transaction(fn ->
      case fun.() do
        {:error, reason} -> rollback(reason)
        result -> result
      end
    end)
  end
end
