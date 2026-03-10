defmodule AitlasWeb.Plugs.InternalAuth do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

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