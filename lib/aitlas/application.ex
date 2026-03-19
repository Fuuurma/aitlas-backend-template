defmodule Aitlas.Application do
  @moduledoc """
  Application supervisor for Aitlas.

  Supervises:
  - Aitlas.Repo (Ecto database connection)
  - Aitlas.PubSub (Phoenix pubsub)
  - AitlasWeb.Endpoint (Phoenix HTTP server)
  - Oban (job queue)
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Aitlas.Repo,
      Hermes.Server.Registry,
      {Phoenix.PubSub, name: Aitlas.PubSub},
      AitlasWeb.Endpoint,
      {Oban, Application.fetch_env!(:aitlas, Oban)}
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
