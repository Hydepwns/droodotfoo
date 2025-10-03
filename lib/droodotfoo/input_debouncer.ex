defmodule Droodotfoo.InputDebouncer do
  @moduledoc """
  Debounces keyboard and mouse input to improve performance and prevent
  excessive event processing during rapid input.
  """

  defstruct [
    :buffer,
    :timer_ref,
    :last_input,
    :pending_keys,
    :config
  ]

  # Default configuration
  @default_config %{
    # Debounce window in milliseconds
    debounce_ms: 10,
    # Max keys to batch together
    batch_size: 10,
    # Some keys bypass debouncing (Enter, Esc, etc.)
    special_keys_instant: true
  }

  # Keys that should be processed immediately (no debouncing)
  @instant_keys ~w(Enter Escape Tab ArrowUp ArrowDown ArrowLeft ArrowRight
                    PageUp PageDown Home End F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12)

  @doc """
  Initialize a new input debouncer.
  """
  def new(config \\ %{}) do
    %__MODULE__{
      buffer: [],
      timer_ref: nil,
      last_input: System.monotonic_time(:millisecond),
      pending_keys: [],
      config: Map.merge(@default_config, config)
    }
  end

  @doc """
  Process a keyboard input event with debouncing.
  Returns {:immediate, key} for instant processing,
  {:debounced, state} for debounced processing,
  or {:batched, keys, state} when batch is ready.
  """
  def process_key(state, key) do
    now = System.monotonic_time(:millisecond)

    cond do
      # Process special keys immediately
      should_process_immediately?(key, state.config) ->
        # Flush any pending keys first
        if state.pending_keys != [] do
          new_state = %{state | pending_keys: [], timer_ref: nil}
          {:batch_with_immediate, state.pending_keys, key, new_state}
        else
          {:immediate, key}
        end

      # Add to batch if within debounce window
      within_debounce_window?(state, now) ->
        add_to_batch(state, key, now)

      # Start new batch
      true ->
        start_new_batch(state, key, now)
    end
  end

  @doc """
  Force flush all pending keys.
  """
  def flush(state) do
    cancel_timer(state.timer_ref)

    {state.pending_keys, %{state | pending_keys: [], timer_ref: nil}}
  end

  @doc """
  Handle timer expiration (called when debounce period ends).
  """
  def handle_timeout(state) do
    keys = state.pending_keys
    new_state = %{state | pending_keys: [], timer_ref: nil}
    {keys, new_state}
  end

  @doc """
  Check if debouncer has pending keys.
  """
  def has_pending?(state) do
    state.pending_keys != []
  end

  @doc """
  Get statistics about the debouncer.
  """
  def get_stats(state) do
    %{
      pending_count: length(state.pending_keys),
      has_timer: state.timer_ref != nil,
      last_input_ms_ago: System.monotonic_time(:millisecond) - state.last_input
    }
  end

  # Private functions

  defp should_process_immediately?(key, config) do
    config.special_keys_instant && key in @instant_keys
  end

  defp within_debounce_window?(state, now) do
    state.timer_ref != nil &&
      now - state.last_input < state.config.debounce_ms
  end

  defp add_to_batch(state, key, now) do
    new_keys = state.pending_keys ++ [key]

    if length(new_keys) >= state.config.batch_size do
      # Batch is full, send immediately
      cancel_timer(state.timer_ref)
      new_state = %{state | pending_keys: [], timer_ref: nil, last_input: now}
      {:batched, new_keys, new_state}
    else
      # Add to batch and continue
      new_state = %{state | pending_keys: new_keys, last_input: now}
      {:debounced, new_state}
    end
  end

  defp start_new_batch(state, key, now) do
    # Flush existing batch if any
    result =
      if state.pending_keys != [] do
        cancel_timer(state.timer_ref)
        {:batched, state.pending_keys, key}
      else
        {:new_batch, key}
      end

    # Start new batch with this key
    timer_ref =
      Process.send_after(
        self(),
        {:debounce_timeout, :input},
        state.config.debounce_ms
      )

    new_state = %{state | pending_keys: [key], timer_ref: timer_ref, last_input: now}

    case result do
      {:batched, keys, _new_key} ->
        {:batch_then_start, keys, new_state}

      _ ->
        {:debounced, new_state}
    end
  end

  defp cancel_timer(nil), do: :ok

  defp cancel_timer(ref) do
    Process.cancel_timer(ref, async: false, info: false)
  end

  @doc """
  Create optimized debounce configuration for different scenarios.
  """
  def config_for_mode(mode) do
    case mode do
      :typing ->
        # Fast typing - minimal debouncing
        %{debounce_ms: 5, batch_size: 20, special_keys_instant: true}

      :navigation ->
        # Navigation - instant special keys
        %{debounce_ms: 15, batch_size: 5, special_keys_instant: true}

      :idle ->
        # Idle - can afford longer debounce
        %{debounce_ms: 50, batch_size: 10, special_keys_instant: true}

      :command ->
        # Command mode - balanced
        %{debounce_ms: 20, batch_size: 15, special_keys_instant: true}

      _ ->
        @default_config
    end
  end
end
