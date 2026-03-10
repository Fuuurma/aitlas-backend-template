defmodule AitlasWeb.Plugs.InternalAuth do
  @moduledoc """
  Internal service authentication plug.

  Validates requests from other Aitlas services using the
  `x-furma-internal` header. Used for service-to-service
  communication that bypasses user session validation.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, _opts) do
    expected = Application.get_env(:aitlas, :furma_internal_secret)

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
