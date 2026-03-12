defmodule FImprove.Sandbox do
  @moduledoc """
  Sandbox execution environment for running code benchmarks.
  
  Like autoresearch's fixed time budget, all benchmarks run in
  isolated containers with resource limits.
  """
  
  @time_budget_seconds 300  # 5 minutes like autoresearch
  
  def execute(code, benchmark_cmd) do
    workspace = create_workspace()
    write_code(workspace, code)
    result = run_in_container(workspace, benchmark_cmd)
    cleanup_workspace(workspace)
    {:ok, result}
  end
  
  defp create_workspace do
    path = Path.join(System.tmp_dir!(), "f_improve_#{:erlang.unique_integer([:positive])}")
    File.mkdir_p!(path)
    path
  end
  
  defp write_code(workspace, code) do
    File.write!(Path.join(workspace, "code.js"), code)
  end
  
  defp run_in_container(workspace, benchmark_cmd) do
    cmd = "docker run --rm -v #{workspace}:/workspace -w /workspace --memory=2g --cpus=1 node:20 sh -c '#{benchmark_cmd}'"
    {output, exit_code} = System.cmd("sh", ["-c", cmd], stderr_to_stdout: true)
    %{output: output, exit_code: exit_code, time_ms: parse_time(output), metrics: parse_metrics(output)}
  end
  
  defp cleanup_workspace(workspace), do: File.rm_rf!(workspace)
  defp parse_time(output) do
    case Regex.run(~r/(\d+(?:\.\d+)?)\s*ms/i, output) do
      [_, time] -> String.to_float(time) |> round()
      _ -> 0
    end
  end
  defp parse_metrics(output), do: %{time_ms: parse_time(output)}
end