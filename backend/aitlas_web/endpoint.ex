defmodule AitlasWeb.Endpoint do
  @moduledoc """
  Phoenix Endpoint for Aitlas.

  Handles HTTP requests, session management, and code reloading.
  """

  use Phoenix.Endpoint, otp_app: :aitlas

  @session_options [
    store: :cookie,
    key: "_aitlas_key",
    signing_salt: "mw3rrwSR",
    same_site: "Lax"
  ]

  plug(Plug.Static,
    at: "/",
    from: :aitlas,
    gzip: not code_reloading?,
    only: AitlasWeb.static_paths(),
    raise_on_missing_only: code_reloading?
  )

  if code_reloading? do
    plug(Phoenix.CodeReloader)
    plug(Phoenix.Ecto.CheckRepoStatus, otp_app: :aitlas)
  end

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(AitlasWeb.Router)
end
