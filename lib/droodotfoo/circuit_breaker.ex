defmodule Droodotfoo.CircuitBreaker do
  @moduledoc """
  Circuit breaker for external API calls.

  Prevents cascading failures by failing fast when an external service is down.
  Uses a simple state machine: closed -> open -> half_open -> closed/open.

  ## Usage

      case CircuitBreaker.call(:github, fn -> GitHub.fetch_repos() end) do
        {:ok, result} -> result
        {:error, :circuit_open} -> cached_or_fallback_data()
        {:error, reason} -> handle_error(reason)
      end

  ## Configuration

  Each service can have custom thresholds:

      CircuitBreaker.configure(:spotify,
        failure_threshold: 3,
        reset_timeout_ms: 30_000
      )

  ## States

  - `:closed` - Normal operation, requests pass through
  - `:open` - Too many failures, requests fail immediately
  - `:half_open` - Testing if service recovered, one request allowed

  """

  use GenServer
  require Logger

  @default_failure_threshold 5
  @default_reset_timeout_ms 30_000
  @default_half_open_max 1

  defstruct [
    :name,
    state: :closed,
    failure_count: 0,
    success_count: 0,
    last_failure_time: nil,
    half_open_attempts: 0,
    failure_threshold: @default_failure_threshold,
    reset_timeout_ms: @default_reset_timeout_ms
  ]

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Execute a function through the circuit breaker.

  Returns `{:ok, result}` on success, `{:error, :circuit_open}` if circuit is open,
  or `{:error, reason}` if the function fails.
  """
  def call(service, fun, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5000)

    case GenServer.call(__MODULE__, {:check, service}, timeout) do
      :ok ->
        execute_and_record(service, fun)

      {:error, :circuit_open} = error ->
        Logger.warning("Circuit breaker open for #{service}, failing fast")
        error
    end
  end

  @doc """
  Configure thresholds for a specific service.
  """
  def configure(service, opts) do
    GenServer.call(__MODULE__, {:configure, service, opts})
  end

  @doc """
  Get the current state of a circuit.
  """
  def get_state(service) do
    GenServer.call(__MODULE__, {:get_state, service})
  end

  @doc """
  Reset a circuit to closed state (useful for testing or manual recovery).
  """
  def reset(service) do
    GenServer.call(__MODULE__, {:reset, service})
  end

  @doc """
  Get status of all circuits.
  """
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    {:ok, %{circuits: %{}}}
  end

  @impl true
  def handle_call({:check, service}, _from, state) do
    circuit = get_or_create_circuit(state, service)
    now = System.monotonic_time(:millisecond)

    case check_circuit(circuit, now) do
      {:ok, updated_circuit} ->
        new_state = put_circuit(state, service, updated_circuit)
        {:reply, :ok, new_state}

      {:error, :circuit_open} ->
        {:reply, {:error, :circuit_open}, state}
    end
  end

  @impl true
  def handle_call({:record_success, service}, _from, state) do
    circuit = get_or_create_circuit(state, service)
    updated = record_success(circuit)
    {:reply, :ok, put_circuit(state, service, updated)}
  end

  @impl true
  def handle_call({:record_failure, service}, _from, state) do
    circuit = get_or_create_circuit(state, service)
    now = System.monotonic_time(:millisecond)
    updated = record_failure(circuit, now)

    if updated.state == :open and circuit.state != :open do
      Logger.error(
        "Circuit breaker opened for #{service} after #{updated.failure_count} failures"
      )
    end

    {:reply, :ok, put_circuit(state, service, updated)}
  end

  @impl true
  def handle_call({:configure, service, opts}, _from, state) do
    circuit = get_or_create_circuit(state, service)

    updated =
      circuit
      |> maybe_update(:failure_threshold, opts[:failure_threshold])
      |> maybe_update(:reset_timeout_ms, opts[:reset_timeout_ms])

    {:reply, :ok, put_circuit(state, service, updated)}
  end

  @impl true
  def handle_call({:get_state, service}, _from, state) do
    circuit = get_or_create_circuit(state, service)
    {:reply, circuit.state, state}
  end

  @impl true
  def handle_call({:reset, service}, _from, state) do
    circuit = get_or_create_circuit(state, service)
    updated = %{circuit | state: :closed, failure_count: 0, half_open_attempts: 0}
    Logger.info("Circuit breaker reset for #{service}")
    {:reply, :ok, put_circuit(state, service, updated)}
  end

  @impl true
  def handle_call(:status, _from, state) do
    status =
      Map.new(state.circuits, fn {name, circuit} ->
        {name,
         %{
           state: circuit.state,
           failure_count: circuit.failure_count,
           success_count: circuit.success_count,
           last_failure: circuit.last_failure_time
         }}
      end)

    {:reply, status, state}
  end

  # Private functions

  defp get_or_create_circuit(state, service) do
    Map.get(state.circuits, service, %__MODULE__{name: service})
  end

  defp put_circuit(state, service, circuit) do
    %{state | circuits: Map.put(state.circuits, service, circuit)}
  end

  defp check_circuit(%{state: :closed} = circuit, _now) do
    {:ok, circuit}
  end

  defp check_circuit(%{state: :open} = circuit, now) do
    time_since_failure = now - (circuit.last_failure_time || 0)

    if time_since_failure >= circuit.reset_timeout_ms do
      # Transition to half-open, allow one request through
      {:ok, %{circuit | state: :half_open, half_open_attempts: 1}}
    else
      {:error, :circuit_open}
    end
  end

  defp check_circuit(%{state: :half_open} = circuit, _now) do
    if circuit.half_open_attempts < @default_half_open_max do
      {:ok, %{circuit | half_open_attempts: circuit.half_open_attempts + 1}}
    else
      {:error, :circuit_open}
    end
  end

  defp record_success(%{state: :half_open} = circuit) do
    # Service recovered, close the circuit
    Logger.info("Circuit breaker closed for #{circuit.name}, service recovered")

    %{
      circuit
      | state: :closed,
        failure_count: 0,
        success_count: circuit.success_count + 1,
        half_open_attempts: 0
    }
  end

  defp record_success(circuit) do
    # Reset failure count on success in closed state
    %{circuit | failure_count: 0, success_count: circuit.success_count + 1}
  end

  defp record_failure(%{state: :half_open} = circuit, now) do
    # Still failing in half-open, go back to open
    %{
      circuit
      | state: :open,
        failure_count: circuit.failure_count + 1,
        last_failure_time: now,
        half_open_attempts: 0
    }
  end

  defp record_failure(circuit, now) do
    new_count = circuit.failure_count + 1
    new_state = if new_count >= circuit.failure_threshold, do: :open, else: :closed

    %{circuit | state: new_state, failure_count: new_count, last_failure_time: now}
  end

  defp maybe_update(circuit, _key, nil), do: circuit
  defp maybe_update(circuit, key, value), do: Map.put(circuit, key, value)

  defp execute_and_record(service, fun) do
    try do
      case fun.() do
        {:ok, _} = result ->
          GenServer.call(__MODULE__, {:record_success, service})
          result

        {:error, _} = error ->
          GenServer.call(__MODULE__, {:record_failure, service})
          error

        other ->
          # Treat non-tagged returns as success
          GenServer.call(__MODULE__, {:record_success, service})
          {:ok, other}
      end
    rescue
      e ->
        GenServer.call(__MODULE__, {:record_failure, service})
        Logger.error("Circuit breaker caught exception for #{service}: #{inspect(e)}")
        {:error, :exception}
    catch
      :exit, reason ->
        GenServer.call(__MODULE__, {:record_failure, service})
        Logger.error("Circuit breaker caught exit for #{service}: #{inspect(reason)}")
        {:error, :exit}
    end
  end
end
