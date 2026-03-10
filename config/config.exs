# config/config.exs
import Config

config :aitlas,
  ecto_repos: [Aitlas.Repo]

config :phoenix, :json_library, Jason

config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# Oban
config :aitlas, Oban,
  repo: Aitlas.Repo,
  engine: Oban.Engines.Basic,
  queues: [
    default: 10,
    agents: 20,
    tools: 30,
    memory: 5,
    files: 5
  ],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(5)}
  ]

# Logger with secrets redaction
config :logger, :console,
  format: {Aitlas.LoggerRedactor, :redact},
  metadata: [:request_id, :user_id, :task_id]

import_config "#{config_env()}.exs"
