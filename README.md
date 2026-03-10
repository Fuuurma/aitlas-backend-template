# Aitlas Backend Template

Base template for Aitlas backend services: Nexus, Agents Store, and Actions.

## Stack

- Elixir 1.18 + OTP 27
- Phoenix 1.7 (API mode)
- Oban 2.19 (job queue)
- Ecto + Postgrex (Neon Postgres)
- MCP Server (JSON-RPC 2.0)

## Quick Start

```bash
# Setup
make setup

# Start server
make dev
```

Visit `http://localhost:4000/api/health`

## Commands

| Command | Description |
|---------|-------------|
| `make setup` | Install deps, setup DB |
| `make dev` | Start Phoenix server |
| `make test` | Run tests |
| `mix test test/path/test.exs:42` | Run single test |
| `make lint` | Run Credo |
| `make type-check` | Run Dialyzer |
| `make security` | Run Sobelow |
| `make migrate` | Run migrations |

## Project Structure

```
lib/aitlas/
├── accounts/          # User and session schemas
├── credits/           # Credit ledger
├── mcp/               # MCP tools and dispatcher
├── workers/           # Oban workers
├── application.ex     # Supervisor
├── crypto.ex          # AES-256-GCM encryption
├── credits.ex         # Credit operations
├── injection_guard.ex # Tool validation
├── logger_redactor.ex # Secrets redaction
└── repo.ex            # Ecto repo

lib/aitlas_web/
├── controllers/       # HTTP controllers
├── plugs/             # Auth plugs
├── router.ex          # Routes
└── endpoint.ex        # Phoenix endpoint
```

## Key Features

- **MCP Server**: JSON-RPC 2.0 endpoint at POST `/api/mcp`
- **Auth**: Session-based (Better Auth) + internal service auth
- **Credits**: Append-only ledger with reserve/deduct/refund
- **Encryption**: AES-256-GCM for BYOK API keys
- **Injection Guard**: Validates tool calls for prompt injection

## Environment Variables

See `.env.example` for required configuration.

## Documentation

- `AGENTS.md` - AI coding context
- `aitlas-elixir-template-guide.md` - Full setup guide

---

Proprietary - All Aitlas products are closed source.