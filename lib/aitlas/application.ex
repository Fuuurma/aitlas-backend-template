defmodule Aitlas.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # DB
      Aitlas.Repo,

      # Phoenix
      {Phoenix.PubSub, name: Aitlas.PubSub},
      AitlasWeb.Endpoint,

      # Oban
      {Oban, Application.fetch_env!(:aitlas, Oban)},

      # Hammer rate limiting (ETS backend for dev)
      {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60, cleanup_rate_ms: 60_000 * 10]}
    ]

    opts = [strategy: :one_for_one, name: Aitlas.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    AitlasWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end