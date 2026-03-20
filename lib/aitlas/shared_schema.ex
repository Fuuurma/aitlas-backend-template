# lib/aitlas/shared_schema.ex
defmodule Aitlas.SharedSchema do
  @moduledoc """
  Shared schema imports from nexus_schema package.

  This module provides convenience aliases for schemas from the shared
  nexus_schema package, ensuring consistency across all Aitlas services.

  ## Usage

      # Option 1: Use the convenience module
      use Aitlas.SharedSchema

      # Option 2: Direct alias
      alias Nexus.Schema.{User, Session, Task}

  ## Available Schemas

  | Schema | Table | Description |
  |--------|-------|-------------|
  | `User` | `users` | User accounts |
  | `Session` | `sessions` | Better Auth sessions |
  | `Account` | `accounts` | OAuth accounts |
  | `ApiKey` | `api_keys` | BYOK API keys |
  | `Task` | `tasks` | Agent tasks |
  | `CreditLedgerEntry` | `credit_ledger_entries` | Credit transactions |

  ## Why Shared Schemas?

  1. **Consistency**: Same schema definitions across all services
  2. **Type Safety**: Compile-time validation of schema changes
  3. **Better Auth**: Compatible with Better Auth session tokens
  4. **Single Source of Truth**: `aitlas-schema/elixir/`
  """

  # Convenience macro for use in other modules
  defmacro __using__(_opts) do
    quote do
      alias Nexus.Schema.{
        User,
        Session,
        Account,
        ApiKey,
        Task,
        CreditLedgerEntry
      }
    end
  end
end