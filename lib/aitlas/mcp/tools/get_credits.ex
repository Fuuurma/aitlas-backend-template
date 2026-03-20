# lib/aitlas/mcp/tools/get_credits.ex
defmodule Aitlas.MCP.Tools.GetCredits do
  @moduledoc """
  MCP tool to check user's credit balance.

  Returns current balance and recent transactions.
  No credits consumed for this query.
  """

  use Hermes.Server.Component, type: :tool

  # ── Tool Schema ───────────────────────────────────────────────────────

  schema do
    field(:limit, :integer, default: 10, min: 1, max: 50, 
      description: "Number of recent transactions to return")
  end

  # ── Execution ────────────────────────────────────────────────────────

  @impl true
  def execute(%{"limit" => limit}, frame) do
    user_id = frame.assigns[:user_id]

    if is_nil(user_id) do
      {:error, "User not authenticated"}
    else
      balance = Aitlas.Credits.get_balance(user_id)

      # Return balance info
      {:ok, %{
        balance: balance,
        message: "Your current credit balance is #{balance}"
      }}
    end
  end
end