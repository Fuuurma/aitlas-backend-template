# config/config.exs
import Config

config :nova,
  ecto_repos: [Nova.Repo]

config :phoenix, :json_library, Jason

config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# Oban (disabled for now)
# config :nova, Oban,
#   repo: Nova.Repo,
#   engine: Oban.Engines.Basic,
#   queues: [
#     default: 10,
#     agents: 20,
#     tools: 30,
#     memory: 5,
#     files: 5
#   ],
#   plugins: [
#     {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
#     {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(5)}
#   ]

# Logger with secrets redaction
config :logger, :console,
  format: {Aitlas.LoggerRedactor, :redact},
  metadata: [:request_id, :user_id, :task_id]

# Nexus client
config :nova,
  nexus_url: System.get_env("NEXUS_API_URL", "http://localhost:4000"),
  nexus_api_key: System.get_env("NEXUS_API_KEY")

import_config "#{config_env()}.exs"
