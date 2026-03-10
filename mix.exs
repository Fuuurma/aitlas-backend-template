defmodule Aitlas.MixProject do
  use Mix.Project

  def project do
    [
      app: :aitlas,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Aitlas.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
      {:gettext, "~> 0.24"},

      # Job queue
      {:oban, "~> 2.19"},

      # HTTP client (for MCP tool calls)
      {:req, "~> 0.5"},

      # CORS
      {:cors_plug, "~> 3.0"},

      # Rate limiting
      {:hammer, "~> 6.0"},
      {:hammer_plug, "~> 2.0"},

      # JWT / token validation
      {:joken, "~> 2.6"},

      # Vector search (for memory)
      {:pgvector, "~> 0.2"},

      # Telemetry / observability
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},

      # Dev / test
      {:ex_machina, "~> 2.8", only: [:dev, :test]},
      {:faker, "~> 0.18", only: [:dev, :test]},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end