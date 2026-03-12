defmodule FImprove.LLM do
  @moduledoc """
  LLM integration for hypothesis generation.
  
  Uses BYOK (Bring Your Own Key) - user's API key is fetched
  from the accounts service.
  """
  
  alias FImprove.Accounts.ApiKey
  
  @doc """
  Generate improvement hypothesis based on code and goal.
  
  Returns:
    - `{:ok, %{hypothesis: string, change: string, description: string}}`
    - `{:error, reason}`
  """
  def generate_hypothesis(user_id, code, goal, current_metric) do
    with {:ok, api_key} <- get_api_key(user_id),
         {:ok, response} <- call_llm(api_key, build_prompt(code, goal, current_metric)) do
      parse_response(response)
    end
  end
  
  defp get_api_key(user_id) do
    case ApiKey.get_active_key(user_id) do
      nil -> {:error, :no_api_key}
      key -> {:ok, key}
    end
  end
  
  defp build_prompt(code, goal, current_metric) do
    """
    You are an expert code optimizer. Your task is to improve this code.
    
    ## Goal
    #{format_goal(goal)}
    
    ## Current Code
    ```
    #{code}
    ```
    
    ## Current Metric
    #{format_metric(current_metric)}
    
    ## Instructions
    1. Analyze the code for improvement opportunities
    2. Propose ONE specific change that will improve the metric
    3. Explain your hypothesis (why this change will help)
    4. Provide the modified code
    
    ## Response Format
    Return JSON:
    {
      "hypothesis": "Brief explanation of why this change will improve the metric",
      "change": "Description of the specific change",
      "modified_code": "The complete modified code",
      "expected_improvement": "Expected metric improvement (e.g., '20% faster')"
    }
    """
  end
  
  defp format_goal(:performance), do: "Improve performance (reduce execution time)"
  defp format_goal(:quality), do: "Improve code quality (readability, maintainability)"
  defp format_goal(:coverage), do: "Increase test coverage"
  defp format_goal(:bugs), do: "Find and fix potential bugs"
  defp format_goal(:refactor), do: "Refactor for better structure"
  defp format_goal(other), do: "Goal: #{other}"
  
  defp format_metric(nil), do: "No baseline metric yet"
  defp format_metric(metric), do: "Current value: #{metric}"
  
  defp call_llm(api_key, prompt) do
    # Call OpenAI-compatible API
    case HTTPoison.post(
      "https://api.openai.com/v1/chat/completions",
      Jason.encode!(%{
        model: "gpt-4",
        messages: [
          %{role: "system", content: "You are an expert code optimizer. Always respond with valid JSON."},
          %{role: "user", content: prompt}
        ],
        temperature: 0.7
      }),
      [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ],
      recv_timeout: 60_000
    ) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)["choices"] |> List.first() |> Map.get("message") |> Map.get("content")}
        
      {:error, %{reason: reason}} ->
        {:error, reason}
    end
  end
  
  defp parse_response(response) do
    case Jason.decode(response) do
      {:ok, parsed} ->
        {:ok, %{
          hypothesis: parsed["hypothesis"],
          change: parsed["change"],
          modified_code: parsed["modified_code"],
          expected_improvement: parsed["expected_improvement"]
        }}
        
      {:error, _} ->
        # Try to extract JSON from response
        case Regex.run(~r/\{[\s\S]*\}/, response) do
          [json_str] ->
            parse_response(json_str)
          _ ->
            {:error, :invalid_response}
        end
    end
  end
end