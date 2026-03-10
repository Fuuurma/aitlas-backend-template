defmodule Aitlas.InjectionGuard do
  @suspicious_patterns [
    ~r/ignore (previous|all) instructions/i,
    ~r/exfiltrate/i,
    ~r/reveal (api|secret|key)/i,
    ~r/execute (system|shell|bash)/i,
    ~r/call (tool|function) .+ instead/i,
    ~r/system prompt/i,
    ~r/jailbreak/i
  ]

  @doc """
  Validate a tool call against an agent's allowlist and injection patterns.
  Returns :ok or {:error, reason}
  """
  def validate(tool_name, arguments, allowlist) do
    cond do
      tool_name not in allowlist ->
        {:error, :tool_not_in_allowlist}

      contains_injection?(arguments) ->
        {:error, :injection_detected}

      true ->
        :ok
    end
  end

  defp contains_injection?(arguments) when is_map(arguments) do
    arguments
    |> Map.values()
    |> Enum.any?(fn
      v when is_binary(v) -> matches_suspicious?(v)
      _ -> false
    end)
  end

  defp contains_injection?(_), do: false

  defp matches_suspicious?(text) do
    Enum.any?(@suspicious_patterns, &Regex.match?(&1, text))
  end
end