defmodule AitlasWeb.Plugs.MCPAuth do
  @moduledoc """
  MCP endpoint authentication plug.

  Supports three authentication methods:
  - Internal: `x-furma-internal` header (service-to-service)
  - External: `Authorization: Bearer <MCP_API_KEY>` (external clients)
  - Better Auth: `Authorization: Bearer <session_token>` (AI agents via OAuth)

  On success, assigns:
  - `:mcp_caller` - `:internal`, `:external`, or `:oauth`
  - `:current_user_id` - User ID (for OAuth calls)
  - `:current_session` - Session record (for OAuth calls)
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias Aitlas.Accounts.Session
  alias Aitlas.Repo

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, _opts) do
    internal_secret = Application.get_env(:aitlas, :furma_internal_secret)
    mcp_api_key = Application.get_env(:aitlas, :mcp_api_key)

    internal_header = get_req_header(conn, "x-furma-internal")
    auth_header = get_req_header(conn, "authorization")

    cond do
      # Service-to-service auth
      internal_header == [internal_secret] ->
        assign(conn, :mcp_caller, :internal)

      # Static API key auth
      auth_header == ["Bearer #{mcp_api_key}"] ->
        assign(conn, :mcp_caller, :external)

      # Better Auth session token (OAuth for AI agents)
      match?(["Bearer " <> _], auth_header) ->
        validate_better_auth_session(conn, auth_header)

      true ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "unauthorized", code: -32_002})
        |> halt()
    end
  end

  defp validate_better_auth_session(conn, ["Bearer " <> token]) do
    case Repo.get_by(Session, token: token) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "invalid session", code: -32_002})
        |> halt()

      session ->
        if DateTime.compare(session.expires_at, DateTime.utc_now()) == :gt do
          conn
          |> assign(:mcp_caller, :oauth)
          |> assign(:current_user_id, session.user_id)
          |> assign(:current_session, session)
        else
          conn
          |> put_status(:unauthorized)
          |> json(%{error: "session expired", code: -32_002})
          |> halt()
        end
    end
  end

  defp validate_better_auth_session(conn, _) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "unauthorized", code: -32_002})
    |> halt()
  end
end
