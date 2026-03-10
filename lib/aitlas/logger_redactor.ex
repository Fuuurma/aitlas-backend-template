defmodule Aitlas.LoggerRedactor do
  @redact_patterns [
    ~r/(api[_-]?key|authorization|password|secret|token|bearer)[=:\s"']+\S+/i,
    ~r/sk-[a-zA-Z0-9]{20,}/,
    ~r/Bearer [a-zA-Z0-9\-_.]+/
  ]

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