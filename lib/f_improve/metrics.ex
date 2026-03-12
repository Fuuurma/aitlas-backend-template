defmodule FImprove.Metrics do
  @moduledoc """
  Metrics parsing from benchmark output.
  
  Like autoresearch captures `val_bpb`, f.improve extracts
  user-defined metrics from benchmark output.
  """
  
  @doc """
  Parse metric from benchmark output.
  
  Looks for patterns like:
    - "time: 150ms"
    - "execution_time: 1.23s"
    - "metric: 0.0045"
    - "score: 85%"
  
  Returns the first metric found, or nil.
  """
  def parse(output) do
    patterns = [
      # Time patterns
      ~r/time:\s*([\d.]+)\s*(ms|s)/i,
      ~r/execution_time:\s*([\d.]+)\s*(ms|s)/i,
      ~r/elapsed:\s*([\d.]+)\s*(ms|s)/i,
      ~r/duration:\s*([\d.]+)\s*(ms|s)/i,
      
      # Generic metric
      ~r/metric:\s*([\d.]+)/i,
      ~r/score:\s*([\d.]+)%?/i,
      ~r/value:\s*([\d.]+)/i,
      
      # Performance
      ~r/ops\/sec:\s*([\d.]+)/i,
      ~r/throughput:\s*([\d.]+)/i,
    ]
    
    Enum.find_value(patterns, fn pattern ->
      case Regex.run(pattern, output) do
        [_, value, unit] when unit in ["ms", "s"] ->
          parse_time(value, unit)
          
        [_, value, unit] when unit == "ms" ->
          parse_time(value, unit)
          
        [_, value] ->
          parse_number(value)
          
        _ ->
          nil
      end
    end)
  end
  
  defp parse_time(value, "ms"), do: String.to_float(value)
  defp parse_time(value, "s"), do: String.to_float(value) * 1000
  defp parse_time(value, _), do: String.to_float(value)
  
  defp parse_number(value) do
    case Float.parse(value) do
      {num, _} -> num
      :error -> nil
    end
  end
  
  @doc """
  Compare two metrics.
  
  For time-based metrics (lower is better):
    - improvement > 0 means new is better
  
  Returns improvement percentage (positive = better).
  """
  def compare(old_metric, new_metric) when is_number(old_metric) and is_number(new_metric) do
    # Assuming lower is better (time-based)
    ((old_metric - new_metric) / old_metric) * 100
  end
  
  def compare(_, _), do: 0.0
end