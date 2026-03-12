defmodule FImprove.Sandbox do
  @moduledoc """
  Docker sandbox for isolated benchmark execution.
  
  Like autoresearch's isolated run environment, each experiment
  runs in a fresh container with resource limits.
  """
  
  @doc """
  Execute code in Docker sandbox.
  
  ## Options
    - `time_limit_ms`: Max execution time (default: 300_000 = 5 min)
    - `memory_mb`: Memory limit (default: 2048 = 2GB)
    - `cpu_count`: CPU limit (default: 1)
  
  ## Returns
    - `{:ok, %{output: string, time_ms: integer, memory_mb: float}}`
    - `{:error, reason}`
  """
  def execute(code, benchmark, opts \\ []) do
    time_limit_ms = Keyword.get(opts, :time_limit_ms, 300_000)
    memory_mb = Keyword.get(opts, :memory_mb, 2048)
    cpu_count = Keyword.get(opts, :cpu_count, 1)
    
    # Create temporary directory for this run
    workdir = create_workdir()
    
    # Write code to file
    write_code(workdir, code)
    
    # Write benchmark script
    write_benchmark(workdir, benchmark)
    
    # Build and run container
    container_id = run_container(workdir, %{
      time_limit_ms: time_limit_ms,
      memory_mb: memory_mb,
      cpu_count: cpu_count
    })
    
    # Wait for completion
    result = wait_for_completion(container_id, time_limit_ms)
    
    # Cleanup
    cleanup(workdir, container_id)
    
    result
  end
  
  defp create_workdir do
    id = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
    path = Path.join(System.tmp_dir!(), "f_improve_#{id}")
    File.mkdir_p!(path)
    path
  end
  
  defp write_code(workdir, code) do
    File.write!(Path.join(workdir, "code.py"), code)
  end
  
  defp write_benchmark(workdir, benchmark) do
    File.write!(Path.join(workdir, "benchmark.sh"), """
    #!/bin/bash
    set -e
    cd /workspace
    #{benchmark}
    """)
  end
  
  defp run_container(workdir, opts) do
    docker_cmd = [
      "run", "-d",
      "--rm",
      "--memory=#{opts.memory_mb}m",
      "--cpus=#{opts.cpu_count}",
      "--timeout=#{div(opts.time_limit_ms, 1000)}",
      "-v", "#{workdir}:/workspace",
      "-w", "/workspace",
      "python:3.12-slim",
      "bash", "benchmark.sh"
    ]
    
    {output, 0} = System.cmd("docker", docker_cmd)
    String.trim(output)
  end
  
  defp wait_for_completion(container_id, timeout_ms) do
    # Poll for completion
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    
    wait_loop(container_id, deadline)
  end
  
  defp wait_loop(container_id, deadline) do
    now = System.monotonic_time(:millisecond)
    
    if now >= deadline do
      # Timeout - kill container
      System.cmd("docker", ["kill", container_id])
      {:error, :timeout}
    else
      # Check status
      {status, 0} = System.cmd("docker", ["inspect", "--format={{.State.Status}}", container_id])
      status = String.trim(status)
      
      case status do
        "exited" ->
          # Get output and stats
          {:ok, collect_results(container_id)}
          
        "running" ->
          # Wait and retry
          Process.sleep(100)
          wait_loop(container_id, deadline)
          
        other ->
          {:error, {:unexpected_status, other}}
      end
    end
  end
  
  defp collect_results(container_id) do
    # Get stdout/stderr
    {output, 0} = System.cmd("docker", ["logs", container_id])
    
    # Get stats
    {stats_json, 0} = System.cmd("docker", ["inspect", container_id])
    stats = Jason.decode!(stats_json) |> List.first()
    
    %{
      output: output,
      time_ms: parse_time_ms(stats),
      memory_mb: parse_memory_mb(stats)
    }
  end
  
  defp parse_time_ms(stats) do
    # Parse execution time from container stats
    # This is approximate - real implementation would use time command
    0
  end
  
  defp parse_memory_mb(stats) do
    # Parse memory usage from container stats
    0.0
  end
  
  defp cleanup(workdir, container_id) do
    File.rm_rf!(workdir)
    System.cmd("docker", ["rm", "-f", container_id], stderr_to_stdout: true)
  end
end