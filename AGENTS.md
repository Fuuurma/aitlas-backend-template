# AGENTS.md — aitlas-backend-template

## Stack
- Elixir 1.18 + OTP 27
- Phoenix 1.7 (API mode — no HTML, no LiveView)
- Oban 2.19 (Postgres-backed job queue)
- Ecto + Postgrex (Neon Postgres)
- MCP server (JSON-RPC 2.0 at POST /api/mcp)

## Key Files
- `config/runtime.exs` — all runtime env vars (validate at boot)
- `lib/aitlas/repo.ex` — Ecto repo + with_transaction/1 helper
- `lib/aitlas/crypto.ex` — AES-256-GCM for BYOK key encryption
- `lib/aitlas/credits.ex` — append-only credit ledger
- `lib/aitlas/injection_guard.ex` — tool call validation
- `lib/aitlas/logger_redactor.ex` — secrets redaction
- `lib/aitlas_web/plugs/auth.ex` — session validation
- `lib/aitlas_web/plugs/internal_auth.ex` — service-to-service auth
- `lib/aitlas_web/plugs/mcp_auth.ex` — MCP endpoint auth
- `lib/aitlas/mcp/tools.ex` — add new MCP tools here
- `lib/aitlas/workers/` — Oban workers go here

## Conventions

### Security (non-negotiable)
- `Crypto.decrypt/2` result: NEVER assign to variable, NEVER log, use inline only
- ALL DB mutations: use `Repo.with_transaction/1`
- ALL user inputs: validate with Ecto changesets
- user_id: present in ALL DB queries — no cross-tenant access
- Credits: deduct ONLY after successful execution

### Adding a new Oban worker
1. Create `lib/aitlas/workers/my_worker.ex`
2. `use Oban.Worker, queue: :your_queue, max_attempts: 3`
3. Implement `perform/1`
4. Enqueue: `MyWorker.new(args) |> Oban.insert()`

### Adding a new MCP tool
1. Add tool definition to `MCP.Tools.list/0`
2. Add `call/3` clause matching tool name
3. Add credit cost to tool definition
4. Document input schema in JSON Schema format

### Adding a new API route
1. Add route to `router.ex` in correct pipeline scope
2. Create controller in `lib/aitlas_web/controllers/`
3. Validate session in controller action
4. Validate input with Ecto changeset or custom validation

### DB migrations
- `make gen.migration name=create_something`
- Use `DATABASE_URL_UNPOOLED` for migration runs
- Always add indexes for foreign keys and common query patterns

## Queue Reference
- `:default` — general tasks (pool: 10)
- `:agents` — agent loops (pool: 20)
- `:tools` — tool execution (pool: 30)
- `:memory` — memory extraction (pool: 5)
- `:files` — file indexing (pool: 5)

## Neon Database
- Use `DATABASE_URL_UNPOOLED` for migrations (no PgBouncer)
- Use `DATABASE_URL` (pooled) for runtime
- **This is the #1 Neon gotcha with Ecto**