defmodule DroodotfooWeb.Live.ConnectionRecovery do
  @moduledoc """
  Handles WebSocket connection recovery with exponential backoff.
  Provides graceful handling of network interruptions.
  """

  defstruct [
    :status,
    :reconnect_attempts,
    :max_attempts,
    :base_delay_ms,
    :max_delay_ms,
    :last_disconnect_time,
    :queued_commands
  ]

  @type status :: :connected | :disconnected | :reconnecting | :failed
  @type t :: %__MODULE__{
          status: status(),
          reconnect_attempts: non_neg_integer(),
          max_attempts: pos_integer(),
          base_delay_ms: pos_integer(),
          max_delay_ms: pos_integer(),
          last_disconnect_time: integer() | nil,
          queued_commands: list()
        }

  @doc """
  Creates initial connection recovery state
  """
  def new(opts \\ []) do
    %__MODULE__{
      status: :connected,
      reconnect_attempts: 0,
      max_attempts: Keyword.get(opts, :max_attempts, 10),
      base_delay_ms: Keyword.get(opts, :base_delay_ms, 1000),
      max_delay_ms: Keyword.get(opts, :max_delay_ms, 30_000),
      last_disconnect_time: nil,
      queued_commands: []
    }
  end

  @doc """
  Handles connection loss
  """
  def handle_disconnect(state) do
    %{state | status: :disconnected, last_disconnect_time: System.monotonic_time(:millisecond)}
  end

  @doc """
  Attempts reconnection with exponential backoff
  """
  def attempt_reconnect(state) do
    if state.reconnect_attempts >= state.max_attempts do
      %{state | status: :failed}
    else
      delay = calculate_backoff_delay(state)
      new_attempts = state.reconnect_attempts + 1

      %{state | status: :reconnecting, reconnect_attempts: new_attempts}
      |> schedule_reconnect(delay)
    end
  end

  @doc """
  Handles successful reconnection
  """
  def handle_reconnect_success(state) do
    %{state | status: :connected, reconnect_attempts: 0, last_disconnect_time: nil}
  end

  @doc """
  Queues command during disconnection
  """
  def queue_command(state, command) do
    if state.status == :disconnected do
      %{state | queued_commands: [command | state.queued_commands]}
    else
      state
    end
  end

  @doc """
  Flushes queued commands after reconnection
  """
  def flush_queued_commands(state) do
    commands = Enum.reverse(state.queued_commands)
    new_state = %{state | queued_commands: []}
    {commands, new_state}
  end

  @doc """
  Gets connection status for UI display
  """
  def get_status_display(state) do
    case state.status do
      :connected -> %{status: "Connected", class: "connected", show: false}
      :disconnected -> %{status: "Disconnected", class: "disconnected", show: true}
      :reconnecting -> %{status: "Reconnecting...", class: "reconnecting", show: true}
      :failed -> %{status: "Connection Failed", class: "failed", show: true}
    end
  end

  @doc """
  Checks if connection is healthy
  """
  def is_connected?(state), do: state.status == :connected

  @doc """
  Gets time since last disconnect
  """
  def time_since_disconnect(state) do
    if state.last_disconnect_time do
      System.monotonic_time(:millisecond) - state.last_disconnect_time
    else
      0
    end
  end

  # Private functions

  defp calculate_backoff_delay(state) do
    # Exponential backoff: base_delay * 2^(attempts - 1)
    delay = state.base_delay_ms * :math.pow(2, state.reconnect_attempts - 1)

    # Add jitter to prevent thundering herd
    jitter = :rand.uniform(1000)

    # Cap at max delay
    (delay + jitter)
    |> round()
    |> min(state.max_delay_ms)
  end

  defp schedule_reconnect(state, _delay_ms) do
    # In real implementation, this would schedule a process message
    # For LiveView, we'll handle this in the LiveView process
    state
  end
end
