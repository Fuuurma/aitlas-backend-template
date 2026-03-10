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

config :aitlas, Aitlas.Repo,
  url: database_url,
  ssl: [verify: :verify_none],
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise "SECRET_KEY_BASE environment variable is missing"

host = System.get_env("PHX_HOST") || "localhost"
port = String.to_integer(System.get_env("PORT") || "4000")

config :aitlas, AitlasWeb.Endpoint,
  url: [host: host, port: 443, scheme: "https"],
  http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
  secret_key_base: secret_key_base

config :aitlas,
  better_auth_secret:
    System.get_env("BETTER_AUTH_SECRET") ||
      raise("BETTER_AUTH_SECRET is missing"),
  furma_internal_secret:
    System.get_env("FURMA_INTERNAL_SECRET") ||
      raise("FURMA_INTERNAL_SECRET is missing"),
  encryption_key:
    System.get_env("ENCRYPTION_KEY") ||
      raise("ENCRYPTION_KEY is missing"),
  mcp_api_key:
    System.get_env("MCP_API_KEY") ||
      raise("MCP_API_KEY is missing")
