defmodule AitlasWeb.Plugs.Auth do
  @moduledoc """
  Session authentication plug for user-facing API routes.

  Validates Bearer tokens against the sessions table and ensures
  the session hasn't expired. On success, assigns `:current_user_id`
  and `:current_session` to the connection.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias Aitlas.Accounts.Session
  alias Aitlas.Repo

  @doc false
  def init(opts), do: opts

  @doc false
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
      nil ->
        :error

      session ->
        if DateTime.compare(session.expires_at, DateTime.utc_now()) == :gt do
          {:ok, session}
        else
          :error
        end
    end
  end
end
