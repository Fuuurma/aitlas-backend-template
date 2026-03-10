defmodule Aitlas do
  @moduledoc """
  Aitlas backend template - the foundation for Aitlas services.

  This module serves as the main entry point for domain contexts.
  Business logic is organized into contexts under `lib/aitlas/`:

  ## Contexts

  - `Aitlas.Accounts` - User and session management
  - `Aitlas.Credits` - Credit ledger operations
  - `Aitlas.MCP` - Model Context Protocol tools
  - `Aitlas.Crypto` - API key encryption

  ## Workers

  Oban workers are in `lib/aitlas/workers/`.
  """
end
