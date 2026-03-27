# lib/aitlas/mcp/tools/get_user.ex
defmodule Aitlas.MCP.Tools.GetUser do
  @moduledoc """
  MCP tool to get current user information.

  Returns user profile data including email, name, and plan tier.
  No credits consumed for this query.
  """

  use Hermes.Server.Component, type: :tool

  # ── Tool Schema ───────────────────────────────────────────────────────

  schema do
    # No parameters needed - uses authenticated user
  end

  # ── Execution ────────────────────────────────────────────────────────

  @impl true
  def execute(_args, frame) do
    user_id = frame.assigns[:user_id]

    if is_nil(user_id) do
      {:error, "User not authenticated"}
    else
      # Import User schema
      alias Aitlas.Accounts.User

      case Aitlas.Repo.get(User, user_id) do
        nil ->
          {:error, "User not found"}

        user ->
          {:ok, %{
            id: user.id,
            name: user.name,
            email: user.email,
            email_verified: user.email_verified,
            image: user.image
          }}
      end
    end
  end
end