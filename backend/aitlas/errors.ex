# lib/aitlas/errors.ex
defmodule Aitlas.Errors do
  @moduledoc """
  Error handling utilities for Aitlas services.

  Provides structured error types and helper functions for
  consistent error handling across MCP tools and API endpoints.

  ## Usage

      # In MCP tools
      def execute(args, frame) do
        with {:ok, value} <- validate(args) do
          {:ok, result}
        else
          {:error, :not_found} -> {:error, "Resource not found"}
          {:error, :invalid} -> {:error, "Invalid input"}
        end
      end

      # In controllers
      def index(conn, _params) do
        case do_something() do
          {:ok, result} -> json(conn, result)
          {:error, reason} -> error_response(conn, reason)
        end
      end
  """

  # ─── Error Types ─────────────────────────────────────────────────────

  @type error_code :: atom()

  @type t :: %__MODULE__{
          code: error_code(),
          message: String.t(),
          details: map() | nil
        }

  defstruct [:code, :message, :details]

  # ─── Constructors ────────────────────────────────────────────────────

  @doc "Create a new error struct"
  def new(code, message, details \\ nil) do
    %__MODULE__{code: code, message: message, details: details}
  end

  @doc "Authentication required error"
  def auth_required do
    new(:auth_required, "Authentication required")
  end

  @doc "Permission denied error"
  def permission_denied do
    new(:permission_denied, "Permission denied")
  end

  @doc "Resource not found error"
  def not_found(resource \\ "Resource") do
    new(:not_found, "#{resource} not found")
  end

  @doc "Validation error"
  def validation_error(errors) when is_map(errors) do
    new(:validation_error, "Validation failed", errors)
  end

  @doc "Rate limit exceeded error"
  def rate_limited(retry_after \\ 60) do
    new(:rate_limited, "Rate limit exceeded", %{retry_after: retry_after})
  end

  @doc "Insufficient credits error"
  def insufficient_credits(required, available) do
    new(
      :insufficient_credits,
      "Insufficient credits",
      %{required: required, available: available}
    )
  end

  @doc "Internal server error"
  def internal_error(message \\ "Internal server error") do
    new(:internal_error, message)
  end

  # ─── Helpers ─────────────────────────────────────────────────────────

  @doc "Check if result is an error"
  def error?({:error, _}), do: true
  def error?(_), do: false

  @doc "Check if result is ok"
  def ok?({:ok, _}), do: true
  def ok?(:ok), do: true
  def ok?(_), do: false

  @doc "Extract error from result"
  def get_error({:error, error}), do: error
  def get_error(_), do: nil

  @doc "Extract value from result"
  def get_value({:ok, value}), do: value
  def get_value(_), do: nil

  @doc "Map over an ok result"
  def map({:ok, value}, fun), do: {:ok, fun.(value)}
  def map({:error, _} = error, _fun), do: error

  @doc "Chain operations that may fail"
  def and_then({:ok, value}, fun), do: fun.(value)
  def and_then({:error, _} = error, _fun), do: error

  @doc "Convert error to user-friendly message"
  def to_message(%__MODULE__{message: message}), do: message
  def to_message(:not_found), do: "Resource not found"
  def to_message(:invalid), do: "Invalid input"
  def to_message(:unauthorized), do: "Authentication required"
  def to_message(:forbidden), do: "Permission denied"
  def to_message(_), do: "An unexpected error occurred"

  @doc "Convert error to HTTP status code"
  def to_status(%__MODULE__{code: code}), do: code_to_status(code)
  def to_status(:not_found), do: 404
  def to_status(:invalid), do: 400
  def to_status(:unauthorized), do: 401
  def to_status(:forbidden), do: 403
  def to_status(_), do: 500

  defp code_to_status(:auth_required), do: 401
  defp code_to_status(:permission_denied), do: 403
  defp code_to_status(:not_found), do: 404
  defp code_to_status(:validation_error), do: 422
  defp code_to_status(:rate_limited), do: 429
  defp code_to_status(:insufficient_credits), do: 402
  defp code_to_status(_), do: 500
end