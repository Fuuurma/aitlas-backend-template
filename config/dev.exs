# config/dev.exs
import Config

config :aitlas, Aitlas.Repo,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 5

config :aitlas, AitlasWeb.Endpoint,
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
