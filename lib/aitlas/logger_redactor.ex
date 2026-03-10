defmodule Aitlas.LoggerRedactor do
  @moduledoc """
  Logger formatter that redacts sensitive information from log output.

  Automatically redacts:
  - API keys (api_key, apiKey, etc.)
  - Authorization headers
  - Passwords
  - Secrets
  - Tokens
  - Bearer strings
  - OpenAI-style keys (sk-xxx)
  """

  @redact_patterns [
    ~r/(api[_-]?key|authorization|password|secret|token|bearer)[=:\s"']+\S+/i,
    ~r/sk-[a-zA-Z0-9]{20,}/,
    ~r/Bearer [a-zA-Z0-9\-_.]+/
  ]

  @doc """
  Redact sensitive patterns from a log message.
  Returns the message with sensitive values replaced by [REDACTED].
  """
  def redact(message) when is_binary(message) do
    Enum.reduce(@redact_patterns, message, fn pattern, msg ->
      Regex.replace(pattern, msg, fn full_match ->
        key_part = String.split(full_match, ~r/[=:\s"']+/) |> List.first()
        "#{key_part}=[REDACTED]"
      end)
    end)
  end

  def redact(message), do: message
end
