# lib/aitlas/response.ex
defmodule Aitlas.Response do
  @moduledoc """
  JSON response formatting for Aitlas API endpoints.

  Provides consistent response structures for all API endpoints
  following JSON:API conventions.

  ## Usage

      # Success responses
      def index(conn, _params) do
        items = list_items()
        json(conn, Response.success(items))
      end

      def show(conn, %{"id" => id}) do
        case get_item(id) do
          {:ok, item} -> json(conn, Response.success(item))
          {:error, error} -> json(conn, Response.error(error), status: 400)
        end
      end

      # Paginated responses
      def list(conn, params) do
        {items, meta} = list_paginated(params)
        json(conn, Response.success(items, meta))
      end
  """

  # ─── Success Responses ───────────────────────────────────────────────

  @doc "Format a successful response with data"
  def success(data) when is_map(data) do
    %{success: true, data: data}
  end

  def success(data) when is_list(data) do
    %{success: true, data: data}
  end

  @doc "Format a successful response with data and metadata"
  def success(data, meta) when is_map(meta) do
    Map.merge(success(data), %{meta: meta})
  end

  @doc "Format a simple success message"
  def message(msg) do
    %{success: true, message: msg}
  end

  @doc "Format a created resource response"
  def created(data) do
    %{success: true, data: data, created: true}
  end

  @doc "Format an updated resource response"
  def updated(data) do
    %{success: true, data: data, updated: true}
  end

  @doc "Format a deleted resource response"
  def deleted do
    %{success: true, deleted: true}
  end

  # ─── Paginated Responses ────────────────────────────────────────────

  @doc "Format a paginated list response"
  def paginated(items, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)
    total = Keyword.get(opts, :total, length(items))
    total_pages = ceil(total / per_page)

    success(items, %{
      pagination: %{
        page: page,
        per_page: per_page,
        total: total,
        total_pages: total_pages,
        has_next: page < total_pages,
        has_prev: page > 1
      }
    })
  end

  # ─── Error Responses ────────────────────────────────────────────────

  @doc "Format an error response"
  def error(message, code \\ nil) when is_binary(message) do
    base = %{success: false, error: message}
    if code, do: Map.put(base, :code, code), else: base
  end

  @doc "Format a validation error response"
  def validation_error(errors) when is_map(errors) do
    %{
      success: false,
      error: "Validation failed",
      code: "validation_error",
      details: errors
    }
  end

  @doc "Format a not found error response"
  def not_found(resource \\ "Resource") do
    %{
      success: false,
      error: "#{resource} not found",
      code: "not_found"
    }
  end

  @doc "Format an unauthorized error response"
  def unauthorized(message \\ "Authentication required") do
    %{
      success: false,
      error: message,
      code: "unauthorized"
    }
  end

  @doc "Format a forbidden error response"
  def forbidden(message \\ "Permission denied") do
    %{
      success: false,
      error: message,
      code: "forbidden"
    }
  end

  @doc "Format a rate limited error response"
  def rate_limited(retry_after \\ 60) do
    %{
      success: false,
      error: "Rate limit exceeded",
      code: "rate_limited",
      retry_after: retry_after
    }
  end

  @doc "Format an insufficient credits error response"
  def insufficient_credits(required, available) do
    %{
      success: false,
      error: "Insufficient credits",
      code: "insufficient_credits",
      required: required,
      available: available
    }
  end

  # ─── MCP Tool Responses ─────────────────────────────────────────────

  @doc "Format MCP tool content response"
  def mcp_text(text) do
    %{content: [%{type: "text", text: text}]}
  end

  @doc "Format MCP tool error response"
  def mcp_error(message) do
    %{content: [%{type: "text", text: "Error: #{message}"}], isError: true}
  end

  @doc "Format MCP tool resource response"
  def mcp_resource(uri, name, mime_type, text) do
    %{
      content: [
        %{
          type: "resource",
          resource: %{
            uri: uri,
            name: name,
            mimeType: mime_type,
            text: text
          }
        }
      ]
    }
  end
end