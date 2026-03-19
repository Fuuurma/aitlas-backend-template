defmodule Aitlas.MCP.Tools.Echo do
  @moduledoc """
  Sample MCP tool that echoes input text.

  This serves as a reference implementation for creating MCP tools
  using Hermes' component architecture.

  ## Creating New Tools

  1. Create a new module in `lib/aitlas/mcp/tools/`
  2. Add `use Hermes.Server.Component, type: :tool`
  3. Define schema with `schema do ... end`
  4. Implement `execute/2` callback
  5. Add the component to `Aitlas.MCP.Server`
  """

  use Hermes.Server.Component, type: :tool

  # ── Tool Schema ───────────────────────────────────────────────────────

  schema do
    field(:text, :string, required: true, max: 1000, description: "The text to echo back")
  end

  # ── Execution ────────────────────────────────────────────────────────

  @impl true
  def execute(%{"text" => text}, frame) do
    # Can access frame assigns for user context
    _user_id = frame.assigns[:user_id]

    # Return {:ok, result} for success
    # Return {:error, message} for failure
    {:ok, text}
  end
end