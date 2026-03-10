defmodule AitlasWeb.Plugs.Auth do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias Aitlas.Repo
  alias Aitlas.Accounts.Session

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, token} <- extract_token(conn),
         {:ok, session} <- validate_session(token) do
      conn
      |> assign(:current_user_id, session.user_id)
      |> assign(:current_session, session)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "unauthorized"})
        |> halt()
    end
  end

  defp extract_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, token}
      _ -> :error
    end
  end

  defp validate_session(token) do
    case Repo.get_by(Session, token: token) do
      nil -> :error
      session ->
        if DateTime.compare(session.expires_at, DateTime.utc_now()) == :gt do
          {:ok, session}
        else
          :error
        end
    end
  end
end