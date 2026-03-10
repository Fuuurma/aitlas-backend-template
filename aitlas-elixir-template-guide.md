# aitlas-elixir-template — Build Guide
**Stack:** Elixir · Phoenix · Oban · Ecto · Neon Postgres · MCP Server  
**Status:** Canonical V1 | Supersedes all prior versions

> This is the base template for: Nexus runtime, Agents Store BE, all Actions BE.  
> Follow this guide exactly. Do not deviate. Every section is tested.

---

## What You Get Out of the Box

- ✅ Elixir + Phoenix 1.7 — JSON API mode (no LiveView, no HTML)
- ✅ Oban — durable job queue (Postgres-backed)
- ✅ Ecto — Neon Postgres with connection pool
- ✅ MCP server skeleton — JSON-RPC 2.0 endpoint ready
- ✅ Auth middleware — session validation + internal service header
- ✅ Credit middleware — pre-check + deduct hook
- ✅ Injection guard — tool call validation
- ✅ Secrets redaction — auto-redact in Logger
- ✅ Health check (`GET /api/health`)
- ✅ CORS configured for `*.aitlas.xyz` + `*.f.xyz`
- ✅ Rate limiting skeleton (Hammer)
- ✅ `.env` template ready to fill
- ✅ `AGENTS.md` for AI coding context

---

## Prerequisites

```bash
# Install Elixir via asdf (recommended)
asdf plugin add erlang
asdf plugin add elixir

# Install latest stable versions
asdf install erlang 27.2
asdf install elixir 1.18.2-otp-27

# Set globally
asdf global erlang 27.2
asdf global elixir 1.18.2-otp-27

# Verify
elixir --version
# Erlang/OTP 27 [erts-15.x] | Elixir 1.18.x (compiled with Erlang/OTP 27)

# Install Hex and Phoenix
mix local.hex --force
mix local.rebar --force
mix archive.install hex phx_new --force
```

---

## Step 1 — Scaffold the Project

```bash
mix phx.new aitlas_elixir_template \
  --no-html \
  --no-assets \
  --no-live \
  --no-mailer \
  --binary-id \
  --database postgres

cd aitlas_elixir_template
```

Flags explained:
- `--no-html` — API only, no views
- `--no-assets` — no JS/CSS pipeline
- `--no-live` — no LiveView
- `--no-mailer` — add separately if needed
- `--binary-id` — UUIDs as primary keys (not integer)
- `--database postgres` — Ecto + Postgrex

---

## Step 2 — Dependencies

Edit `mix.exs`. Replace the `deps` function:

```elixir
# mix.exs
defp deps do
  [
    # Phoenix
    {:phoenix, "~> 1.7"},
    {:phoenix_ecto, "~> 4.6"},
    {:ecto_sql, "~> 3.12"},
    {:postgrex, "~> 0.19"},
    {:plug_cowboy, "~> 2.7"},
    {:jason, "~> 1.4"},
    {:bandit, "~> 1.6"},

    # Job queue
    {:oban, "~> 2.19"},

    # HTTP client (for MCP tool calls)
    {:req, "~> 0.5"},

    # CORS
    {:cors_plug, "~> 3.0"},

    # Rate limiting
    {:hammer, "~> 7.0"},
    {:hammer_plug, "~> 3.0"},

    # JWT / token validation
    {:joken, "~> 2.6"},

    # Crypto (AES-256-GCM for BYOK key encryption)
    # Built into Erlang :crypto — no extra dep needed

    # Telemetry / observability
    {:telemetry_metrics, "~> 1.0"},
    {:telemetry_poller, "~> 1.1"},

    # Dev / test
    {:ex_machina, "~> 2.8", only: [:dev, :test]},
    {:faker, "~> 0.18", only: [:dev, :test]},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
    {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
  ]
end
```

```bash
mix deps.get
```

---

## Step 3 — Environment Variables

Create `.env` (loaded by `config/runtime.exs`):

```bash
# ─── Database (Neon) ───────────────────────────────────────────
# Pooled URL — runtime connections
DATABASE_URL="postgresql://username:password@ep-xxx.eu-west-2.aws.neon.tech/aitlas?sslmode=require"
# Direct URL — migrations only
DATABASE_URL_UNPOOLED="postgresql://username:password@ep-xxx.eu-west-2.aws.neon.tech/aitlas?sslmode=require"

# ─── Auth ──────────────────────────────────────────────────────
BETTER_AUTH_SECRET="your-64-char-hex-secret-here"

# ─── Internal service auth ─────────────────────────────────────
FURMA_INTERNAL_SECRET="your-internal-secret-here"

# ─── BYOK encryption ───────────────────────────────────────────
# Generate: mix run -e "IO.puts(:crypto.strong_rand_bytes(32) |> Base.encode16(case: :lower))"
ENCRYPTION_KEY="your-64-char-hex-key-here"

# ─── App ───────────────────────────────────────────────────────
PHX_HOST="localhost"
PORT="4000"
SECRET_KEY_BASE="your-phoenix-secret-key-base"
# Generate: mix phx.gen.secret

# ─── MCP ───────────────────────────────────────────────────────
MCP_API_KEY="your-mcp-api-key-for-external-access"

# ─── Nexus (only for Actions that call back to Nexus) ──────────
# NEXUS_API_URL="http://localhost:4000"

# ─── Environment ───────────────────────────────────────────────
MIX_ENV="dev"
```

Create `.env.example` (committed):

```bash
DATABASE_URL=""
DATABASE_URL_UNPOOLED=""
BETTER_AUTH_SECRET=""
FURMA_INTERNAL_SECRET=""
ENCRYPTION_KEY=""
PHX_HOST="localhost"
PORT="4000"
SECRET_KEY_BASE=""
MCP_API_KEY=""
MIX_ENV="dev"
```

Add `.env` to `.gitignore`:

```bash
echo ".env" >> .gitignore
```

---

## Step 4 — Config Files

### 4a. `config/config.exs`

```elixir
# config/config.exs
import Config

config :aitlas_elixir_template,
  ecto_repos: [AitlasElixirTemplate.Repo]

config :phoenix, :json_library, Jason

# Oban
config :aitlas_elixir_template, Oban,
  engine: Oban.Engines.Basic,
  queues: [
    default: 10,
    agents: 20,
    tools: 30,
    memory: 5,
    files: 5
  ],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},     # prune after 7 days
    {Oban.Plugins.Stager, interval: 1_000},
    {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(5)}
  ]

import_config "#{config_env()}.exs"
```

### 4b. `config/dev.exs`

```elixir
# config/dev.exs
import Config

config :aitlas_elixir_template, AitlasElixirTemplate.Repo,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 5

config :aitlas_elixir_template, AitlasElixirTemplateWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_secret_key_base_not_for_production_at_least_64_chars_long_1234"

config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:request_id, :user_id, :task_id]

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
```

### 4c. `config/test.exs`

```elixir
# config/test.exs
import Config

config :aitlas_elixir_template, AitlasElixirTemplate.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5

config :aitlas_elixir_template, AitlasElixirTemplateWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_not_for_production_at_least_64_chars_1234"

config :aitlas_elixir_template, Oban, testing: :inline

config :logger, level: :warning
```

### 4d. `config/runtime.exs`

```elixir
# config/runtime.exs
import Config

# Load .env file in dev/test
if config_env() in [:dev, :test] do
  if File.exists?(".env") do
    for line <- File.read!(".env") |> String.split("\n", trim: true),
        not String.starts_with?(line, "#"),
        [key, val] <- [String.split(line, "=", parts: 2)] do
      System.put_env(key, val)
    end
  end
end

database_url =
  System.get_env("DATABASE_URL") ||
    raise "DATABASE_URL environment variable is missing"

config :aitlas_elixir_template, AitlasElixirTemplate.Repo,
  url: database_url,
  ssl: [verify: :verify_none],
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  socket_options: [:inet6]

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise "SECRET_KEY_BASE environment variable is missing"

host = System.get_env("PHX_HOST") || "localhost"
port = String.to_integer(System.get_env("PORT") || "4000")

config :aitlas_elixir_template, AitlasElixirTemplateWeb.Endpoint,
  url: [host: host, port: 443, scheme: "https"],
  http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
  secret_key_base: secret_key_base

config :aitlas_elixir_template,
  better_auth_secret: System.get_env("BETTER_AUTH_SECRET") ||
    raise("BETTER_AUTH_SECRET is missing"),
  furma_internal_secret: System.get_env("FURMA_INTERNAL_SECRET") ||
    raise("FURMA_INTERNAL_SECRET is missing"),
  encryption_key: System.get_env("ENCRYPTION_KEY") ||
    raise("ENCRYPTION_KEY is missing"),
  mcp_api_key: System.get_env("MCP_API_KEY") ||
    raise("MCP_API_KEY is missing")
```

---

## Step 5 — Repo (Neon-Optimized)

Edit `lib/aitlas_elixir_template/repo.ex`:

```elixir
# lib/aitlas_elixir_template/repo.ex
defmodule AitlasElixirTemplate.Repo do
  use Ecto.Repo,
    otp_app: :aitlas_elixir_template,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Execute a function inside a transaction.
  Use this for ALL credit mutations.
  """
  def transact(fun) do
    transaction(fn ->
      case fun.() do
        {:error, reason} -> rollback(reason)
        result -> result
      end
    end)
  end
end
```

---

## Step 6 — Base Schema / Migrations

### 6a. Users table migration

```bash
mix ecto.gen.migration create_users
```

Edit `priv/repo/migrations/YYYYMMDDHHMMSS_create_users.exs`:

```elixir
defmodule AitlasElixirTemplate.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :email, :string, null: false
      add :email_verified, :boolean, default: false, null: false
      add :image, :string

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
```

### 6b. Sessions migration

```bash
mix ecto.gen.migration create_sessions
```

```elixir
defmodule AitlasElixirTemplate.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add :id, :string, primary_key: true
      add :expires_at, :utc_datetime, null: false
      add :token, :string, null: false
      add :ip_address, :string
      add :user_agent, :string
      add :user_id, references(:users, type: :string, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:sessions, [:token])
    create index(:sessions, [:user_id])
  end
end
```

### 6c. API keys + credit ledger

```bash
mix ecto.gen.migration create_api_keys_and_credits
```

```elixir
defmodule AitlasElixirTemplate.Repo.Migrations.CreateApiKeysAndCredits do
  use Ecto.Migration

  def change do
    create table(:api_keys) do
      add :user_id, references(:users, type: :string, on_delete: :delete_all), null: false
      add :provider, :string, null: false     # openai | anthropic | gemini
      add :encrypted_key, :text, null: false
      add :iv, :string, null: false
      add :hint, :string                       # last 4 chars for display

      timestamps()
    end

    create index(:api_keys, [:user_id, :provider])

    create table(:credit_ledger) do
      add :user_id, references(:users, type: :string, on_delete: :delete_all), null: false
      add :amount, :integer, null: false       # positive = credit, negative = debit
      add :balance, :integer, null: false      # snapshot after this entry
      add :reason, :string, null: false
      add :reference_id, :string               # task_id, stripe_id, etc.

      timestamps(updated_at: false)
    end

    create index(:credit_ledger, [:user_id, :inserted_at])
  end
end
```

### 6d. Run migrations

```bash
# Against Neon (use unpooled URL for migrations)
DATABASE_URL=$DATABASE_URL_UNPOOLED mix ecto.create
DATABASE_URL=$DATABASE_URL_UNPOOLED mix ecto.migrate
```

---

## Step 7 — Auth Middleware

### 7a. Session validation plug

Create `lib/aitlas_elixir_template_web/plugs/auth.ex`:

```elixir
# lib/aitlas_elixir_template_web/plugs/auth.ex
defmodule AitlasElixirTemplateWeb.Plugs.Auth do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias AitlasElixirTemplate.Repo
  alias AitlasElixirTemplate.Accounts.Session

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, token} <- extract_token(conn),
         {:ok, session} <- validate_session(token) do
      conn
      |> assign(:current_user_id, session.user_id)
      |> assign(:current_session, session)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "unauthorized"})
        |> halt()
    end
  end

  defp extract_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, token}
      _ -> :error
    end
  end

  defp validate_session(token) do
    case Repo.get_by(Session, token: token) do
      nil -> :error
      session ->
        if DateTime.compare(session.expires_at, DateTime.utc_now()) == :gt do
          {:ok, session}
        else
          :error
        end
    end
  end
end
```

### 7b. Internal service plug

Create `lib/aitlas_elixir_template_web/plugs/internal_auth.ex`:

```elixir
# lib/aitlas_elixir_template_web/plugs/internal_auth.ex
defmodule AitlasElixirTemplateWeb.Plugs.InternalAuth do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, _opts) do
    expected = Application.get_env(:aitlas_elixir_template, :furma_internal_secret)

    case get_req_header(conn, "x-furma-internal") do
      [^expected] ->
        assign(conn, :internal_call, true)

      _ ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "forbidden"})
        |> halt()
    end
  end
end
```

### 7c. Secrets redaction

Create `lib/aitlas_elixir_template/logger_redactor.ex`:

```elixir
# lib/aitlas_elixir_template/logger_redactor.ex
defmodule AitlasElixirTemplate.LoggerRedactor do
  @redact_patterns [
    ~r/(api[_-]?key|authorization|password|secret|token|bearer)[=:\s"']+\S+/i,
    ~r/sk-[a-zA-Z0-9]{20,}/,
    ~r/Bearer [a-zA-Z0-9\-_.]+/
  ]

  def redact(message) when is_binary(message) do
    Enum.reduce(@redact_patterns, message, fn pattern, msg ->
      Regex.replace(pattern, msg, fn full_match ->
        key_part = String.split(full_match, ~r/[=:\s"']+/) |> List.first()
        "#{key_part}=[REDACTED]"
      end)
    end)
  end

  def redact(message), do: message
end
```

Configure in `config/config.exs`:

```elixir
config :logger, :console,
  format: {AitlasElixirTemplate.LoggerRedactor, :redact},
  metadata: [:request_id, :user_id, :task_id]
```

---

## Step 8 — Credit System

Create `lib/aitlas_elixir_template/credits.ex`:

```elixir
# lib/aitlas_elixir_template/credits.ex
defmodule AitlasElixirTemplate.Credits do
  import Ecto.Query
  alias AitlasElixirTemplate.Repo
  alias AitlasElixirTemplate.Credits.LedgerEntry

  @doc """
  Get current balance for a user.
  Reads the most recent ledger balance snapshot.
  """
  def get_balance(user_id) do
    query =
      from l in LedgerEntry,
        where: l.user_id == ^user_id,
        order_by: [desc: l.inserted_at],
        limit: 1,
        select: l.balance

    Repo.one(query) || 0
  end

  @doc """
  Check if user has enough credits.
  """
  def has_credits?(user_id, amount) do
    get_balance(user_id) >= amount
  end

  @doc """
  Reserve credits (pre-check on task dispatch).
  Returns {:ok, reservation_id} or {:error, :insufficient_credits}
  """
  def reserve(user_id, amount, reference_id) do
    Repo.transact(fn ->
      current = get_balance(user_id)

      if current < amount do
        {:error, :insufficient_credits}
      else
        append_entry(user_id, -amount, current - amount, "reserve", reference_id)
      end
    end)
  end

  @doc """
  Deduct credits after successful tool execution.
  """
  def deduct(user_id, amount, reason, reference_id) do
    Repo.transact(fn ->
      current = get_balance(user_id)
      append_entry(user_id, -amount, current - amount, reason, reference_id)
    end)
  end

  @doc """
  Refund credits (failed task, unused reservation).
  """
  def refund(user_id, amount, reference_id) do
    Repo.transact(fn ->
      current = get_balance(user_id)
      append_entry(user_id, amount, current + amount, "refund", reference_id)
    end)
  end

  @doc """
  Grant credits (subscription, purchase, promo).
  """
  def grant(user_id, amount, reason, reference_id \\ nil) do
    Repo.transact(fn ->
      current = get_balance(user_id)
      append_entry(user_id, amount, current + amount, reason, reference_id)
    end)
  end

  defp append_entry(user_id, amount, new_balance, reason, reference_id) do
    %LedgerEntry{}
    |> LedgerEntry.changeset(%{
      user_id: user_id,
      amount: amount,
      balance: new_balance,
      reason: reason,
      reference_id: reference_id
    })
    |> Repo.insert()
  end
end
```

Create the schema `lib/aitlas_elixir_template/credits/ledger_entry.ex`:

```elixir
defmodule AitlasElixirTemplate.Credits.LedgerEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "credit_ledger" do
    field :user_id, :string
    field :amount, :integer
    field :balance, :integer
    field :reason, :string
    field :reference_id, :string

    timestamps(updated_at: false)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:user_id, :amount, :balance, :reason, :reference_id])
    |> validate_required([:user_id, :amount, :balance, :reason])
  end
end
```

---

## Step 9 — BYOK Encryption

Create `lib/aitlas_elixir_template/crypto.ex`:

```elixir
# lib/aitlas_elixir_template/crypto.ex
defmodule AitlasElixirTemplate.Crypto do
  @aad "aitlas-api-key-v1"

  @doc """
  Encrypt an API key with AES-256-GCM.
  Returns {ciphertext_base64, iv_base64}.

  IMPORTANT: Never assign the result to a named variable in logs.
  Always use inline in DB insert.
  """
  def encrypt(plaintext) when is_binary(plaintext) do
    key = get_key()
    iv = :crypto.strong_rand_bytes(12)

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, @aad, true)

    encrypted = Base.encode64(ciphertext <> tag)
    iv_b64 = Base.encode64(iv)

    {encrypted, iv_b64}
  end

  @doc """
  Decrypt an API key.
  Returns the plaintext string.

  IMPORTANT: Never log the return value. Use immediately and discard.
  """
  def decrypt(encrypted_b64, iv_b64) when is_binary(encrypted_b64) and is_binary(iv_b64) do
    key = get_key()
    iv = Base.decode64!(iv_b64)

    combined = Base.decode64!(encrypted_b64)
    # Last 16 bytes are the auth tag
    ciphertext_len = byte_size(combined) - 16
    <<ciphertext::binary-size(ciphertext_len), tag::binary-size(16)>> = combined

    :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ciphertext, @aad, tag, false)
  end

  defp get_key do
    :aitlas_elixir_template
    |> Application.get_env(:encryption_key)
    |> Base.decode16!(case: :mixed)
  end
end
```

---

## Step 10 — Injection Guard

Create `lib/aitlas_elixir_template/injection_guard.ex`:

```elixir
# lib/aitlas_elixir_template/injection_guard.ex
defmodule AitlasElixirTemplate.InjectionGuard do
  @suspicious_patterns [
    ~r/ignore (previous|all) instructions/i,
    ~r/exfiltrate/i,
    ~r/reveal (api|secret|key)/i,
    ~r/execute (system|shell|bash)/i,
    ~r/call (tool|function) .+ instead/i,
    ~r/system prompt/i,
    ~r/jailbreak/i
  ]

  @doc """
  Validate a tool call against an agent's allowlist and injection patterns.
  Returns :ok or {:error, reason}
  """
  def validate(tool_name, arguments, allowlist) do
    cond do
      tool_name not in allowlist ->
        {:error, :tool_not_in_allowlist}

      contains_injection?(arguments) ->
        {:error, :injection_detected}

      true ->
        :ok
    end
  end

  defp contains_injection?(arguments) when is_map(arguments) do
    arguments
    |> Map.values()
    |> Enum.any(fn
      v when is_binary(v) -> matches_suspicious?(v)
      _ -> false
    end)
  end

  defp contains_injection?(_), do: false

  defp matches_suspicious?(text) do
    Enum.any?(@suspicious_patterns, &Regex.match?(&1, text))
  end
end
```

---

## Step 11 — MCP Server

### 11a. MCP controller

Create `lib/aitlas_elixir_template_web/controllers/mcp_controller.ex`:

```elixir
# lib/aitlas_elixir_template_web/controllers/mcp_controller.ex
defmodule AitlasElixirTemplateWeb.MCPController do
  use AitlasElixirTemplateWeb, :controller

  alias AitlasElixirTemplate.MCP.Dispatcher

  @doc """
  POST /api/mcp
  JSON-RPC 2.0 entry point for all tool calls.
  """
  def handle(conn, params) do
    case Dispatcher.dispatch(params, conn.assigns) do
      {:ok, result} ->
        json(conn, %{
          jsonrpc: "2.0",
          id: params["id"],
          result: result
        })

      {:error, %{code: code, message: message}} ->
        json(conn, %{
          jsonrpc: "2.0",
          id: params["id"],
          error: %{code: code, message: message}
        })
    end
  end
end
```

### 11b. MCP dispatcher

Create `lib/aitlas_elixir_template/mcp/dispatcher.ex`:

```elixir
# lib/aitlas_elixir_template/mcp/dispatcher.ex
defmodule AitlasElixirTemplate.MCP.Dispatcher do
  alias AitlasElixirTemplate.MCP.Tools

  def dispatch(%{"method" => "initialize"}, _assigns) do
    {:ok, %{
      protocolVersion: "2024-11-05",
      serverInfo: %{name: "aitlas-action", version: "1.0.0"},
      capabilities: %{tools: %{}}
    }}
  end

  def dispatch(%{"method" => "ping"}, _assigns) do
    {:ok, %{}}
  end

  def dispatch(%{"method" => "tools/list"}, _assigns) do
    {:ok, %{tools: Tools.list()}}
  end

  def dispatch(%{"method" => "tools/call", "params" => params}, assigns) do
    tool_name = params["name"]
    arguments = params["arguments"] || %{}

    Tools.call(tool_name, arguments, assigns)
  end

  def dispatch(%{"method" => method}, _assigns) do
    {:error, %{code: -32601, message: "Method not found: #{method}"}}
  end

  def dispatch(_, _assigns) do
    {:error, %{code: -32600, message: "Invalid request"}}
  end
end
```

### 11c. Tools skeleton

Create `lib/aitlas_elixir_template/mcp/tools.ex`:

```elixir
# lib/aitlas_elixir_template/mcp/tools.ex
defmodule AitlasElixirTemplate.MCP.Tools do
  @doc """
  Return the list of tools this action exposes.
  Add your tool definitions here.
  """
  def list do
    [
      %{
        name: "example_tool",
        description: "An example tool — replace with real tools",
        inputSchema: %{
          type: "object",
          properties: %{
            query: %{type: "string", description: "The input query"}
          },
          required: ["query"]
        },
        creditCost: 1
      }
    ]
  end

  @doc """
  Execute a tool by name.
  Pattern match to add new tools.
  """
  def call("example_tool", %{"query" => query}, _assigns) do
    {:ok, %{
      content: [%{type: "text", text: "Result for: #{query}"}]
    }}
  end

  def call(name, _arguments, _assigns) do
    {:error, %{code: -32601, message: "Tool not found: #{name}"}}
  end
end
```

---

## Step 12 — Oban Workers

Create `lib/aitlas_elixir_template/workers/example_worker.ex`:

```elixir
# lib/aitlas_elixir_template/workers/example_worker.ex
defmodule AitlasElixirTemplate.Workers.ExampleWorker do
  use Oban.Worker,
    queue: :default,
    max_attempts: 3,
    unique: [period: 60]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id} = args}) do
    # Your job logic here
    :ok
  end
end
```

Enqueue a job from anywhere:

```elixir
%{user_id: "user_123", action: "process"}
|> AitlasElixirTemplate.Workers.ExampleWorker.new()
|> Oban.insert()
```

---

## Step 13 — Router

Replace `lib/aitlas_elixir_template_web/router.ex`:

```elixir
# lib/aitlas_elixir_template_web/router.ex
defmodule AitlasElixirTemplateWeb.Router do
  use AitlasElixirTemplateWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug CORSPlug,
      origin: [
        ~r/https:\/\/.*\.aitlas\.xyz/,
        ~r/https:\/\/.*\.f\.xyz/,
        "http://localhost:3000",
        "http://localhost:3001"
      ],
      methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      headers: ["Authorization", "Content-Type", "X-Furma-Internal"]
  end

  pipeline :authenticated do
    plug AitlasElixirTemplateWeb.Plugs.Auth
  end

  pipeline :internal do
    plug AitlasElixirTemplateWeb.Plugs.InternalAuth
  end

  pipeline :mcp_auth do
    plug AitlasElixirTemplateWeb.Plugs.MCPAuth
  end

  # ── Health (public) ─────────────────────────────────────────
  scope "/api", AitlasElixirTemplateWeb do
    pipe_through :api
    get "/health", HealthController, :index
  end

  # ── MCP (requires MCP_API_KEY or internal header) ───────────
  scope "/api", AitlasElixirTemplateWeb do
    pipe_through [:api, :mcp_auth]
    post "/mcp", MCPController, :handle
  end

  # ── Internal API (Nexus → Action) ───────────────────────────
  scope "/internal", AitlasElixirTemplateWeb do
    pipe_through [:api, :internal]
    # Add internal-only routes here
  end

  # ── Authenticated API (user session) ────────────────────────
  scope "/api", AitlasElixirTemplateWeb do
    pipe_through [:api, :authenticated]
    # Add user-facing API routes here
  end
end
```

Create MCP auth plug `lib/aitlas_elixir_template_web/plugs/mcp_auth.ex`:

```elixir
defmodule AitlasElixirTemplateWeb.Plugs.MCPAuth do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, _opts) do
    internal_secret = Application.get_env(:aitlas_elixir_template, :furma_internal_secret)
    mcp_api_key = Application.get_env(:aitlas_elixir_template, :mcp_api_key)

    internal_header = get_req_header(conn, "x-furma-internal")
    auth_header = get_req_header(conn, "authorization")

    cond do
      internal_header == [internal_secret] ->
        assign(conn, :mcp_caller, :internal)

      auth_header == ["Bearer #{mcp_api_key}"] ->
        assign(conn, :mcp_caller, :external)

      true ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "unauthorized", code: -32002})
        |> halt()
    end
  end
end
```

---

## Step 14 — Health Controller

Create `lib/aitlas_elixir_template_web/controllers/health_controller.ex`:

```elixir
defmodule AitlasElixirTemplateWeb.HealthController do
  use AitlasElixirTemplateWeb, :controller

  def index(conn, _params) do
    case AitlasElixirTemplate.Repo.query("SELECT 1") do
      {:ok, _} ->
        json(conn, %{
          status: "ok",
          db: "connected",
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
        })

      {:error, _} ->
        conn
        |> put_status(503)
        |> json(%{status: "error", db: "disconnected"})
    end
  end
end
```

---

## Step 15 — Application Supervisor

Edit `lib/aitlas_elixir_template/application.ex`:

```elixir
defmodule AitlasElixirTemplate.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # DB
      AitlasElixirTemplate.Repo,

      # Phoenix
      {Phoenix.PubSub, name: AitlasElixirTemplate.PubSub},
      AitlasElixirTemplateWeb.Endpoint,

      # Oban
      {Oban, Application.fetch_env!(:aitlas_elixir_template, Oban)},

      # Hammer rate limiting (ETS backend for dev)
      {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60, cleanup_rate_ms: 60_000 * 10]},
    ]

    opts = [strategy: :one_for_one, name: AitlasElixirTemplate.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    AitlasElixirTemplateWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
```

---

## Step 16 — Package Scripts (Makefile)

Create `Makefile` at project root:

```makefile
.PHONY: setup dev test build migrate reset

setup:
	mix deps.get
	mix ecto.setup

dev:
	mix phx.server

test:
	MIX_ENV=test mix test

test.watch:
	MIX_ENV=test mix test.watch

migrate:
	DATABASE_URL=$$DATABASE_URL_UNPOOLED mix ecto.migrate

migrate.rollback:
	DATABASE_URL=$$DATABASE_URL_UNPOOLED mix ecto.rollback

migrate.reset:
	DATABASE_URL=$$DATABASE_URL_UNPOOLED mix ecto.reset

lint:
	mix credo --strict

type-check:
	mix dialyzer

security:
	mix sobelow --config

gen.migration:
	mix ecto.gen.migration $(name)

gen.worker:
	mix phx.gen.context Workers $(name) workers/$(name)
```

---

## Step 17 — AGENTS.md

Create `AGENTS.md` at project root:

```markdown
# AGENTS.md — aitlas-elixir-template

## Stack
- Elixir 1.18 + OTP 27
- Phoenix 1.7 (API mode — no HTML, no LiveView)
- Oban 2.19 (Postgres-backed job queue)
- Ecto + Postgrex (Neon Postgres)
- MCP server (JSON-RPC 2.0 at POST /api/mcp)

## Key Files
- `config/runtime.exs` — all runtime env vars (validate at boot)
- `lib/*/repo.ex` — Ecto repo + transact/1 helper
- `lib/*/crypto.ex` — AES-256-GCM for BYOK key encryption
- `lib/*/credits.ex` — append-only credit ledger
- `lib/*/injection_guard.ex` — tool call validation
- `lib/*/logger_redactor.ex` — secrets redaction
- `lib/*_web/plugs/auth.ex` — session validation
- `lib/*_web/plugs/internal_auth.ex` — service-to-service auth
- `lib/*_web/plugs/mcp_auth.ex` — MCP endpoint auth
- `lib/*/mcp/tools.ex` — add new MCP tools here
- `lib/*/workers/` — Oban workers go here

## Conventions

### Security (non-negotiable)
- `Crypto.decrypt/2` result: NEVER assign to variable, NEVER log, use inline only
- ALL DB mutations: use `Repo.transact/1`
- ALL user inputs: validate with Ecto changesets
- user_id: present in ALL DB queries — no cross-tenant access
- Credits: deduct ONLY after successful execution

### Adding a new Oban worker
1. Create `lib/*/workers/my_worker.ex`
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
2. Create controller in `lib/*_web/controllers/`
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
```

---

## Step 18 — Final Structure

```
aitlas_elixir_template/
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── prod.exs
│   ├── test.exs
│   └── runtime.exs
├── lib/
│   ├── aitlas_elixir_template/
│   │   ├── application.ex
│   │   ├── repo.ex
│   │   ├── crypto.ex
│   │   ├── injection_guard.ex
│   │   ├── logger_redactor.ex
│   │   ├── credits.ex
│   │   ├── credits/
│   │   │   └── ledger_entry.ex
│   │   ├── accounts/
│   │   │   ├── user.ex
│   │   │   └── session.ex
│   │   ├── mcp/
│   │   │   ├── dispatcher.ex
│   │   │   └── tools.ex
│   │   └── workers/
│   │       └── example_worker.ex
│   └── aitlas_elixir_template_web/
│       ├── endpoint.ex
│       ├── router.ex
│       ├── controllers/
│       │   ├── health_controller.ex
│       │   └── mcp_controller.ex
│       └── plugs/
│           ├── auth.ex
│           ├── internal_auth.ex
│           └── mcp_auth.ex
├── priv/
│   └── repo/migrations/
├── test/
├── AGENTS.md
├── Makefile
├── .env
├── .env.example
└── mix.exs
```

---

## Step 19 — First Run

```bash
# Install dependencies
mix deps.get

# Create + migrate DB
make migrate

# Verify compilation
mix compile --warnings-as-errors

# Start server
make dev
```

Open `http://localhost:4000/api/health` — should return:

```json
{
  "status": "ok",
  "db": "connected",
  "timestamp": "2026-03-10T..."
}
```

Test MCP endpoint:

```bash
curl -X POST http://localhost:4000/api/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-mcp-api-key" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

Expected:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [
      {
        "name": "example_tool",
        "description": "An example tool — replace with real tools",
        ...
      }
    ]
  }
}
```

---

## Common Issues

**`mix ecto.create` fails — SSL error**
Neon requires SSL. Ensure `url` config includes `?sslmode=require` or set `ssl: [verify: :verify_none]` in Repo config.

**Oban not processing jobs**
Check the queue name matches the worker's `queue:` option. Verify `Oban` is in the supervisor children list.

**Session validation always returns unauthorized**
The session `token` field must match exactly what Better Auth (on the Next.js side) sets as the cookie/bearer token. Check the sessions table in Neon Studio.

**Neon connection drops**
Neon serverless goes idle. Add `keepalives: true` and `keepalives_idle: 30` to Repo config for long-lived services.

**CORS blocking requests from Nova**
Ensure the origin matches exactly — including port in development. Check `CORSPlug` config in router.

---

## Neon Setup Reference

Same Neon project as the UI template. Add pgvector for services using vector memory:

```sql
-- Run in Neon SQL editor
CREATE EXTENSION IF NOT EXISTS vector;

-- HNSW index for vector memory (add after creating the table)
CREATE INDEX idx_memory_vectors_hnsw ON memory_vectors
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);
```

Use `DATABASE_URL_UNPOOLED` (no PgBouncer) for migrations. Use `DATABASE_URL` (pooled) for the runtime Repo.

---

*Template maintained by Herb (AI CTO). Do not modify this template directly — fork it per service.*
