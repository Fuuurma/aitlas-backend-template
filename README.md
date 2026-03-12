# f.improve — Autonomous Code Improvement

> ⚠️ **Proprietary** — All Aitlas products are **closed source**. No open source license.

Inspired by [karpathy/autoresearch](https://github.com/karpathy/autoresearch) — AI agents that iteratively improve code by running experiments.

## Stack

- Elixir 1.18 + OTP 27
- Phoenix 1.7 (API mode)
- Oban 2.19 (job queue)
- Ecto + Postgrex (Neon Postgres)
- MCP Server (JSON-RPC 2.0)
- Docker/Firecracker (sandbox execution)

## Quick Start

```bash
# Setup
make setup

# Start server
make dev
```

Visit `http://localhost:4000/api/health`

## How It Works

Like autoresearch but for any code:

```
1. ANALYZE   - Read code, run baseline benchmark
2. HYPOTHESIZE - Agent proposes improvement
3. EXPERIMENT  - Apply change, run benchmark
4. MEASURE     - Compare metrics (keep/discard)
5. ITERATE     - Repeat until plateau
```

## The Autoresearch Pattern

| Component | Autoresearch | f.improve |
|-----------|--------------|-----------|
| **Instructions** | program.md | improvement_program.md |
| **Modifiable** | train.py | user's code |
| **Fixed utilities** | prepare.py | benchmark runner |
| **Metric** | val_bpb | user-defined (speed, quality, etc.) |
| **Time budget** | 5 minutes | 5 minutes (configurable) |
| **Log** | results.tsv | experiments table |

## API

### MCP Endpoint

```json
POST /api/mcp
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "improve_code",
    "arguments": {
      "code": "...",
      "benchmark": "...",
      "goal": "performance",
      "iterations": 10
    }
  }
}
```

### REST API

```bash
# Create improvement job
POST /api/jobs
{
  "code": "...",
  "benchmark": "npm test",
  "goal": "performance"
}

# Get job status
GET /api/jobs/:id

# Get experiment log
GET /api/jobs/:id/experiments
```

## Project Structure

```
lib/f_improve/
├── accounts/          # User and session schemas
├── experiments/       # Experiment management
├── sandbox/           # Docker/Firecracker execution
├── improvement/       # Improvement loop logic
├── mcp/               # MCP tools
├── workers/           # Oban workers
└── application.ex
```

## Commands

| Command | Description |
|---------|-------------|
| `make setup` | Install deps, setup DB |
| `make dev` | Start Phoenix server |
| `make test` | Run tests |
| `make sandbox` | Start Docker sandbox |