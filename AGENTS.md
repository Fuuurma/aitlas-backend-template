# AGENTS.md — aitlas-backend-template

## Stack
- Elixir 1.18 + OTP 27, Phoenix 1.7 (API mode), Oban 2.19, Ecto + Postgrex (Neon)
- MCP server (JSON-RPC 2.0 at POST /api/mcp)

## Build / Lint / Test Commands

```bash
make setup          # mix deps.get + mix ecto.setup
make dev            # mix phx.server (live reload)
make test           # Run all tests
make test.watch     # Run tests with file watching
mix test test/path/test.exs:42  # Run single test at line 42
make lint           # mix credo --strict
make type-check     # mix dialyzer
make security       # mix sobelow --config
make migrate        # Run pending migrations
make migrate.rollback
make gen.migration name=create_something
```

## Code Style

### Naming
- Modules: `Aitlas.ModuleName` (CamelCase, singular)
- Functions/vars: `snake_case`
- Tables: plural snake_case (`users`, `ledger_entries`)
- Routes: kebab-case (`/api/agents/:id`)
- Tests: `*_test.exs`, describe uses sentence case

### Module Order
1. `use` statements
2. `alias`/`import`/`require` (grouped, blank line between)
3. Module attrs (`@type`, `@doc`, `@impl`)
4. Public functions (with `@doc`)
5. Private functions (`defp`)

### Typespecs & Docs
- Use `@doc` and `@spec` for public functions
- Use `@impl` for callbacks
```elixir
@doc "Gets current balance for a user."
@spec get_balance(String.t()) :: integer()
def get_balance(user_id), do: # ...
```

### Error Handling
- Return `{:ok, result}` or `{:error, reason}`
- Use atoms for errors (`:insufficient_credits`, `:not_found`)
- Pattern match in function heads

### Ecto
- Use `Repo.with_transaction/1` for multi-step DB mutations
- Use changesets for validation
- Always include `user_id` in WHERE (tenant isolation)
- Use `import Ecto.Query` for composing queries

### Controllers
- Use `use AitlasWeb, :controller`
- Return proper HTTP status codes
- Validate input with changesets

### Oban Workers
- Use `@impl Oban.Worker`
- Define queue and max_attempts
- Return `:ok` on success, error tuple on failure

### Security (non-negotiable)
- NEVER assign `Crypto.decrypt/2` to variable, use inline only
- Use `Repo.with_transaction/1` for ALL DB mutations
- Validate ALL inputs with Ecto changesets
- Include `user_id` in ALL DB queries
- Deduct credits ONLY after successful execution
- Use `Aitlas.LoggerRedactor` for sanitizing logs

### Formatting
- Run `mix format` before committing
- 2-space indentation, max 98 chars/line

### Testing
- Use ExUnit with Ecto.Sandbox
- Test files: `*_test.exs`
- Use `describe` blocks and `test` macro

### Import Order
1. `use` 2. `alias` 3. `import` 4. `require`

## Key Files
- `config/runtime.exs` — runtime env vars
- `lib/aitlas/repo.ex` — Ecto repo + with_transaction/1
- `lib/aitlas/crypto.ex` — AES-256-GCM encryption
- `lib/aitlas/credits.ex` — credit ledger
- `lib/aitlas/injection_guard.ex` — tool validation
- `lib/aitlas/logger_redactor.ex` — secrets redaction
- `lib/aitlas_web/plugs/` — auth plugs
- `lib/aitlas/mcp/tools.ex` — MCP tools
- `lib/aitlas/workers/` — Oban workers

## Queues
- `:default` (pool:10), `:agents` (pool:20), `:tools` (pool:30), `:memory` (pool:5), `:files` (pool:5)

## Neon Database
- `DATABASE_URL_UNPOOLED` for migrations, `DATABASE_URL` (pooled) for runtime

## Adding Components

### Oban Worker
1. Create `lib/aitlas/workers/my_worker.ex`
2. `use Oban.Worker, queue: :your_queue, max_attempts: 3`
3. Implement `perform/1`
4. Enqueue: `MyWorker.new(args) |> Oban.insert()`

### MCP Tool
1. Add to `MCP.Tools.list/0`
2. Add `call/3` clause
3. Add credit cost
4. Document input schema

### API Route
1. Add to `router.ex` in correct pipeline
2. Create controller in `lib/aitlas_web/controllers/`
3. Validate session in action
4. Validate input with changeset
