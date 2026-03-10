defmodule Aitlas.Repo do
  use Ecto.Repo,
    otp_app: :aitlas,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Execute a function inside a transaction.
  Use this for ALL credit mutations.
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