# f.improve — Autonomous Code Improvement

> ⚠️ **Proprietary** — All Aitlas products are **closed source**. No open source license.

**Inspired by:** [karpathy/autoresearch](https://github.com/karpathy/autoresearch)

---

## Overview

f.improve is an autonomous code improvement system. Like autoresearch, it uses AI agents to iteratively improve code by running experiments and measuring results.

**The Loop:**
```
ANALYZE → HYPOTHESIZE → EXPERIMENT → MEASURE → ITERATE
```

---

## Repositories

| Component | Repo | Stack |
|-----------|------|-------|
| **Backend** | `f-improve` | Elixir + Phoenix + Oban |
| **Frontend** | `f-improve-frontend` | Next.js 16 + shadcn/ui |

---

## Backend Architecture

### Core Modules

```
lib/f_improve/
├── f_improve.ex              # Improvement loop
├── sandbox.ex                # Docker execution
├── jobs.ex + jobs/job.ex     # Job management
├── experiments.ex + experiments/experiment.ex  # Experiment tracking
├── mcp/tools.ex              # MCP endpoint
├── workers/improvement_worker.ex  # Oban worker
└── accounts/session.ex       # Auth

lib/f_improve_web/
├── router.ex                 # API routes
├── plugs/auth.ex             # Bearer token auth
├── controllers/
│   ├── jobs_controller.ex
│   └── experiments_controller.ex
```

### API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/health` | GET | No | Health check |
| `/api/mcp` | POST | No | MCP endpoint |
| `/api/jobs` | GET | Yes | List jobs |
| `/api/jobs` | POST | Yes | Create job |
| `/api/jobs/:id` | GET | Yes | Get job |
| `/api/jobs/:id/experiments` | GET | Yes | Get experiments |
| `/api/experiments/:job_id` | GET | Yes | List experiments |
| `/api/experiments/:job_id/tsv` | GET | Yes | Download TSV |

### MCP Tools

| Tool | Input | Output |
|------|-------|--------|
| `improve_code` | `{code, benchmark, goal, iterations}` | `{job_id, status}` |
| `quick_scan` | `{code, goal}` | `{suggestions}` |
| `get_experiments` | `{job_id}` | `{experiments}` |

---

## Frontend Architecture

### Components

```
src/
├── app/
│   └── improve/
│       └── page.tsx          # Main dashboard
├── components/
│   ├── improvement-form.tsx  # Code input form
│   └── experiment-log.tsx    # Real-time experiment viewer
└── lib/
    └── api.ts                # API client
```

### Features

- ✅ Code editor with syntax highlighting
- ✅ Benchmark command input
- ✅ Goal selection (performance, quality, coverage, bugs, refactor)
- ✅ Iteration count configuration
- ✅ Real-time experiment polling (2s interval)
- ✅ Status badges (keep/discard/crash)
- ✅ Metrics display (time, memory)
- ✅ TSV export (like autoresearch's results.tsv)

---

## The Autoresearch Pattern

| Autoresearch | f.improve |
|--------------|-----------|
| `program.md` | Task input + goal |
| `train.py` | User's code |
| `prepare.py` | Benchmark runner |
| `val_bpb` | User-defined metric |
| `results.tsv` | experiments table |
| 5-min time budget | 5-min sandbox execution |
| Git branches | Job tags |
| Commit hash | Experiment commit |

---

## Database Schema

### jobs
```sql
id: uuid (PK)
user_id: string
tag: string
code: text
benchmark: string
goal: string
iterations: integer
status: string
best_code: text
improvement_percent: float
created_at: timestamp
updated_at: timestamp
```

### experiments
```sql
id: uuid (PK)
job_id: uuid (FK)
iteration: integer
commit: string
hypothesis: text
change: text
metric_value: float
memory_gb: float
status: string (keep|discard|crash)
description: text
code_snapshot: text
created_at: timestamp
```

---

## Usage

### Start Backend
```bash
cd f-improve
make setup
make dev
# Server runs on localhost:4000
```

### Start Frontend
```bash
cd f-improve-frontend
npm install
npm run dev
# App runs on localhost:3000
```

### Create Improvement Job
```bash
curl -X POST http://localhost:4000/api/jobs \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "function fibonacci(n) { ... }",
    "benchmark": "node bench.js",
    "goal": "performance",
    "iterations": 10
  }'
```

---

## Next Steps

1. **Backend:**
   - [ ] Add Docker sandbox implementation
   - [ ] Add LLM integration for hypothesis generation
   - [ ] Add metrics parsing
   - [ ] Test MCP endpoint

2. **Frontend:**
   - [ ] Add code diff viewer
   - [ ] Add job history page
   - [ ] Add real-time SSE updates
   - [ ] Add results export

3. **Integration:**
   - [ ] Add to aitlas-docs
   - [ ] Create action spec
   - [ ] Deploy to production

---

## Credits

| Operation | Credits |
|-----------|---------|
| `improve_code` | 10 |
| `quick_scan` | 5 |
| `get_experiments` | 0 |

---

*Created: March 12, 2026*