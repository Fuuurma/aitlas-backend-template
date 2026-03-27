# lib/aitlas_web/plugs/request_id.ex
defmodule AitlasWeb.Plugs.RequestId do
  @moduledoc """
  Request ID tracking for distributed tracing.

  Generates or propagates a unique request ID for each request.
  Used for log correlation and debugging across services.

  ## Headers

  - `x-request-id` - Set by load balancer or upstream
  - `x-correlation-id` - Alternative header (fallback)

  ## Usage

  Add to pipeline:

      pipeline :api do
        plug AitlasWeb.Plugs.RequestId
      end

  Access in handlers:

      def handle(conn, _opts) do
        request_id = conn.assigns.request_id
        Logger.info("Processing", request_id: request_id)
      end

  ## Log Correlation

  The request ID is automatically included in structured logs:

      Logger.metadata(request_id: conn.assigns.request_id)
  """

  import Plug.Conn

  @header "x-request-id"
  @alt_header "x-correlation-id"

  def init(opts), do: opts

  def call(conn, _opts) do
    request_id = get_request_id(conn)

    conn
    |> assign(:request_id, request_id)
    |> put_resp_header(@header, request_id)
    |> put_req_id_in_logger(request_id)
  end

  defp get_request_id(conn) do
    # Try primary header
    case get_req_header(conn, @header) do
      [id | _] when is_binary(id) and id != "" ->
        id

      # Try alternative header
      _ ->
        case get_req_header(conn, @alt_header) do
          [id | _] when is_binary(id) and id != "" ->
            id

          # Generate new ID
          _ ->
            generate_id()
        end
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end

  defp put_req_id_in_logger(conn, request_id) do
    Logger.metadata(request_id: request_id)
    conn
  end
end