# lib/aitlas/circuit_breaker.ex
defmodule Aitlas.CircuitBreaker do
  @moduledoc """
  Circuit breaker pattern for external service calls.

  Prevents cascading failures by:
  1. Tracking failures and opening circuit when threshold exceeded
  2. Rejecting calls when circuit is open (fast fail)
  3. Allowing retry after timeout (half-open state)
  4. Closing circuit if retry succeeds

  ## States

  - `:closed` - Normal operation, calls pass through
  - `:open` - Circuit tripped, calls rejected immediately
  - `:half_open` - Testing if service recovered

  ## Usage

      # Define circuit breaker
      defmodule MyApp.ExternalService do
        use Aitlas.CircuitBreaker,
          threshold: 5,
          timeout: 30_000,
          name: :external_service
      end

      # Execute calls through circuit
      ExternalService.call(fn ->
        HTTPClient.get("https://api.example.com/data")
      end)

  ## Configuration

      config :aitlas, :circuit_breakers,
        external_api: [threshold: 5, timeout: 30_000],
        database: [threshold: 10, timeout: 10_000]
  """

  use GenServer

  defstruct [
    :name,
    :threshold,
    :timeout,
    :state,
    :failures,
    :last_failure,
    :metadata
  ]

  # ─── Client API ─────────────────────────────────────────────────

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Execute a function through the circuit breaker.
  """
  def call(name, fun, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5000)

    case GenServer.call(name, {:call, fun}, timeout) do
      {:ok, result} -> {:ok, result}
      {:error, :circuit_open} -> {:error, :circuit_open}
      {:error, reason} -> {:error, reason}
    end
  rescue
    e in -> {:error, e}
  end

  @doc """
  Get current circuit state.
  """
  def state(name) do
    GenServer.call(name, :state)
  end

  @doc """
  Manually reset the circuit.
  """
  def reset(name) do
    GenServer.call(name, :reset)
  end

  @doc """
  Force open the circuit.
  """
  def trip(name) do
    GenServer.call(name, :trip)
  end

  # ─── Server Callbacks ───────────────────────────────────────────

  @impl true
  def init(opts) do
    state = %__MODULE__{
      name: Keyword.fetch!(opts, :name),
      threshold: Keyword.get(opts, :threshold, 5),
      timeout: Keyword.get(opts, :timeout, 30_000),
      state: :closed,
      failures: 0,
      last_failure: nil,
      metadata: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:call, fun}, _from, %{state: :open} = state) do
    # Check if we should try half-open
    if should_try_half_open?(state) do
      new_state = %{state | state: :half_open}
      execute_in_half_open(fun, new_state)
    else
      {:reply, {:error, :circuit_open}, state}
    end
  end

  def handle_call({:call, fun}, _from, %{state: :closed} = state) do
    execute_call(fun, state)
  end

  def handle_call({:call, fun}, _from, %{state: :half_open} = state) do
    execute_in_half_open(fun, state)
  end

  def handle_call(:state, _from, state) do
    {:reply, Map.from_struct(state), state}
  end

  def handle_call(:reset, _from, state) do
    new_state = %{state | state: :closed, failures: 0, last_failure: nil}
    {:reply, :ok, new_state}
  end

  def handle_call(:trip, _from, state) do
    new_state = %{state | state: :open, last_failure: DateTime.utc_now()}
    {:reply, :ok, new_state}
  end

  # ─── Private Functions ──────────────────────────────────────────

  defp execute_call(fun, state) do
    try do
      result = fun.()
      new_state = reset_failures(state)
      {:reply, {:ok, result}, new_state}
    rescue
      e ->
        new_state = record_failure(state)
        {:reply, {:error, e}, new_state}
    end
  end

  defp execute_in_half_open(fun, state) do
    try do
      result = fun.()
      new_state = close_circuit(state)
      {:reply, {:ok, result}, new_state}
    rescue
      e ->
        new_state = open_circuit(state)
        {:reply, {:error, e}, new_state}
    end
  end

  defp should_try_half_open?(%{last_failure: nil}), do: true
  defp should_try_half_open?(%{last_failure: last, timeout: timeout}) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, last, :millisecond)
    diff >= timeout
  end

  defp record_failure(%{failures: failures, threshold: threshold} = state) do
    new_failures = failures + 1

    if new_failures >= threshold do
      open_circuit(state)
    else
      %{state | failures: new_failures, last_failure: DateTime.utc_now()}
    end
  end

  defp reset_failures(state) do
    %{state | failures: 0, last_failure: nil}
  end

  defp open_circuit(state) do
    %{state | state: :open, last_failure: DateTime.utc_now()}
  end

  defp close_circuit(state) do
    %{state | state: :closed, failures: 0, last_failure: nil}
  end
end

# ─── Convenience Macros ─────────────────────────────────────────────

defmodule Aitlas.CircuitBreaker.Macros do
  @moduledoc """
  Macros for defining circuit breakers.
  """

  defmacro __using__(opts) do
    quote do
      use GenServer

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def call(fun, opts \\ []) do
        Aitlas.CircuitBreaker.call(__MODULE__, fun, opts)
      end

      def state do
        Aitlas.CircuitBreaker.state(__MODULE__)
      end

      def reset do
        Aitlas.CircuitBreaker.reset(__MODULE__)
      end

      @impl true
      def init(opts) do
        Aitlas.CircuitBreaker.init(unquote(opts) ++ opts)
      end

      @impl true
      def handle_call(msg, from, state) do
        Aitlas.CircuitBreaker.handle_call(msg, from, state)
      end
    end
  end
end