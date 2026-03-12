defmodule FImproveWeb.SSEController do
  @moduledoc """
  SSE endpoint for real-time job updates.
  """
  
  use FImproveWeb, :controller
  
  alias FImproveWeb.SSE
  
  def stream(conn, %{"id" => job_id}) do
    conn = conn
    |> put_resp_header("cache-control", "no-cache")
    |> put_resp_content_type("text/event-stream")
    |> send_chunked(200)
    
    # Send initial event
    chunk(conn, "event: connected\ndata: {\"job_id\": \"#{job_id}\"}\n\n")
    
    # Stream updates
    SSE.stream(job_id, fn
      :init, data ->
        chunk(conn, "event: init\ndata: #{Jason.encode!(data)}\n\n")
        
      :experiment, data ->
        chunk(conn, "event: experiment\ndata: #{Jason.encode!(data)}\n\n")
        
      :completed, data ->
        chunk(conn, "event: completed\ndata: #{Jason.encode!(data)}\n\n")
        
      :error, data ->
        chunk(conn, "event: error\ndata: #{Jason.encode!(data)}\n\n")
        
      :timeout, _ ->
        chunk(conn, "event: timeout\ndata: {}\n\n")
    end)
    
    conn
  end
  
  defp chunk(conn, data) do
    Plug.Conn.chunk(conn, data)
  end
end