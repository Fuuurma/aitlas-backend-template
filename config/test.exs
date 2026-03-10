# config/test.exs
import Config

config :aitlas, Aitlas.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5

config :aitlas, AitlasWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_not_for_production_at_least_64_chars_1234"

config :aitlas, Oban, testing: :inline

config :logger, level: :warning