defmodule DroodotfooWeb.DroodotfooLive do
  use DroodotfooWeb, :live_view
  alias Droodotfoo.TerminalBridge
  alias Droodotfoo.{RaxolApp, AdaptiveRefresh, InputDebouncer, InputRateLimiter}
  alias DroodotfooWeb.Live.ConnectionRecovery

  @impl true
  def mount(_params, _session, socket) do
    # Record page request
    Droodotfoo.PerformanceMonitor.record_request()

    # Use the existing RaxolApp process (started in supervision tree)
    raxol_pid = Process.whereis(RaxolApp) || RaxolApp

    # Initialize performance optimization systems
    adaptive_refresh = AdaptiveRefresh.new()
    input_debouncer = InputDebouncer.new(InputDebouncer.config_for_mode(:navigation))
    rate_limiter = InputRateLimiter.new()

    # Start with adaptive refresh rate
    if connected?(socket) do
      schedule_next_tick(adaptive_refresh)
    end

    {:ok,
     socket
     |> assign(:raxol_pid, raxol_pid)
     |> assign(:terminal_html, "")
     |> assign(:current_section, :home)
     |> assign(:last_render_time, System.monotonic_time(:millisecond))
     |> assign(:connection_recovery, ConnectionRecovery.new())
     |> assign(:adaptive_refresh, adaptive_refresh)
     |> assign(:input_debouncer, input_debouncer)
     |> assign(:rate_limiter, rate_limiter)
     |> assign(:last_buffer_hash, nil)
     |> assign(:performance_mode, :normal)
     |> assign(:tick_timer, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="monospace-web-container monospace-container">
      <!-- Monospace-web style header -->
      <table class="header">
        <tr>
          <td colspan="2" rowspan="2" class="width-auto">
            <h1 class="title">DROO.FOO</h1>
            <span class="subtitle">Terminal-Powered Web Experience</span>
          </td>
          <th>Version</th>
          <td class="width-min">v1.0.0</td>
        </tr>
        <tr>
          <th>Updated</th>
          <td class="width-min"><time>{Date.to_string(Date.utc_today())}</time></td>
        </tr>
      </table>
      
    <!-- Connection status indicator -->
      <%= if assigns[:connection_recovery] do %>
        <% status_info = ConnectionRecovery.get_status_display(@connection_recovery) %>
        <%= if status_info.show do %>
          <div class={"connection-status #{status_info.class}"}>
            {status_info.status}
          </div>
        <% end %>
      <% end %>
      
    <!-- Terminal container with monospace grid -->
      <div
        class="terminal-wrapper"
        id="terminal-wrapper"
        phx-hook="TerminalHook"
        phx-window-keydown="key_press"
        tabindex="0"
      >
        {raw(@terminal_html)}
        
    <!-- Hidden input for keyboard capture inside the hook element -->
        <input
          id="terminal-input"
          type="text"
          phx-keydown="key_press"
          phx-key="Enter"
          style="position: absolute; left: -9999px; top: 0;"
          autofocus
        />
      </div>
      
    <!-- Instructions -->
      <div class="instructions-box">
        <span class="text-muted">
          <strong>j/k</strong> navigate • <strong>Enter</strong> select • <strong>/</strong> search
        </span>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info({:update_connection_status, status}, socket) do
    # Update connection recovery status
    recovery = %{socket.assigns.connection_recovery | status: status}
    {:noreply, assign(socket, :connection_recovery, recovery)}
  end

  @impl true
  def handle_info(:tick, socket) do
    adaptive = socket.assigns.adaptive_refresh

    # Check if we should render based on adaptive refresh rate
    if AdaptiveRefresh.should_render?(adaptive) do
      start_time = System.monotonic_time(:millisecond)

      # Get current terminal buffer from Raxol
      buffer = RaxolApp.get_buffer(socket.assigns.raxol_pid)

      # Calculate buffer hash for dirty checking
      buffer_hash = :erlang.phash2(buffer)

      # Only render if buffer has changed
      {html, should_update} =
        if buffer_hash != socket.assigns.last_buffer_hash do
          # Use terminal bridge for HTML generation
          rendered_html = TerminalBridge.terminal_to_html(buffer)
          {rendered_html, true}
        else
          {socket.assigns.terminal_html, false}
        end

      # Calculate render time
      render_time = System.monotonic_time(:millisecond) - start_time

      # Record render in adaptive refresh
      adaptive = AdaptiveRefresh.record_render(adaptive, render_time)

      # Only record metrics for actual renders
      if should_update do
        Droodotfoo.PerformanceMonitor.record_render_time(render_time)
        # Push event to JS to verify grid alignment
        push_event(socket, "terminal_updated", %{})
      end

      # Schedule next tick based on adaptive refresh rate
      schedule_next_tick(adaptive)

      {:noreply,
       socket
       |> assign(:terminal_html, html)
       |> assign(:last_render_time, render_time)
       |> assign(:adaptive_refresh, adaptive)
       |> assign(
         :last_buffer_hash,
         if(should_update, do: buffer_hash, else: socket.assigns.last_buffer_hash)
       )}
    else
      # Skip this tick, schedule next one
      schedule_next_tick(adaptive)
      {:noreply, socket}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    recovery = ConnectionRecovery.handle_disconnect(socket.assigns.connection_recovery)
    recovery = ConnectionRecovery.attempt_reconnect(recovery)

    # Schedule reconnection attempt
    :timer.send_after(1000, self(), :attempt_reconnect)

    {:noreply, assign(socket, :connection_recovery, recovery)}
  end

  # Handle reconnection attempts
  def handle_info(:attempt_reconnect, socket) do
    recovery = socket.assigns.connection_recovery

    if recovery.status == :reconnecting do
      # Try to reconnect by starting a new tick cycle
      if connected?(socket) do
        recovery = ConnectionRecovery.handle_reconnect_success(recovery)
        {queued_commands, recovery} = ConnectionRecovery.flush_queued_commands(recovery)

        # Process any queued commands
        socket = process_queued_commands(socket, queued_commands)

        # Restart tick timer using existing schedule function
        schedule_next_tick(socket.assigns.adaptive_refresh)

        {:noreply, assign(socket, :connection_recovery, recovery)}
      else
        # Still disconnected, try again
        recovery = ConnectionRecovery.attempt_reconnect(recovery)
        delay = calculate_reconnect_delay(recovery)
        :timer.send_after(delay, self(), :attempt_reconnect)

        {:noreply, assign(socket, :connection_recovery, recovery)}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_info({:debounce_timeout, :input}, socket) do
    {keys, debouncer} = InputDebouncer.handle_timeout(socket.assigns.input_debouncer)
    Enum.each(keys, &RaxolApp.send_input(socket.assigns.raxol_pid, &1))

    {:noreply, assign(socket, :input_debouncer, debouncer)}
  end

  # Catch-all for unexpected messages to prevent crashes
  def handle_info(msg, socket) do
    # Log unexpected messages in development
    if Mix.env() != :prod do
      IO.inspect(msg, label: "Unexpected message in DroodotfooLive")
    end
    {:noreply, socket}
  end

  @impl true
  def handle_event("key_press", %{"key" => key}, socket) do
    # Check rate limiting first
    {allowed?, rate_limiter} = InputRateLimiter.allow_event?(socket.assigns.rate_limiter)
    socket = assign(socket, :rate_limiter, rate_limiter)

    if not allowed? do
      # Event blocked by rate limiter
      {:noreply, socket}
    else
      # Validate input key
      if not valid_input_key?(key) do
        {:noreply, socket}
      else
        # Record activity in adaptive refresh
        adaptive = AdaptiveRefresh.record_activity(socket.assigns.adaptive_refresh)
        process_valid_input(key, socket, adaptive)
      end
    end
  end

  def handle_event("cell_click", %{"row" => row, "col" => col}, socket) do
    # Handle cell click from mobile interface
    # Could be used to move cursor or select items
    IO.puts("Cell clicked at row: #{row}, col: #{col}")
    {:noreply, socket}
  end

  def handle_event("recalculate_grid", _params, socket) do
    # Trigger grid recalculation after font size change
    buffer = RaxolApp.get_buffer(socket.assigns.raxol_pid)

    # Use terminal bridge for HTML generation
    html_content = Droodotfoo.TerminalBridge.terminal_to_html(buffer)

    # Send updated HTML to client
    {:noreply, push_event(socket, "update_grid", %{html: html_content})}
  end

  defp valid_input_key?(nil), do: false
  defp valid_input_key?(""), do: false

  defp valid_input_key?(key) when is_binary(key) do
    # Whitelist of allowed keys
    valid_keys = [
      "j",
      "k",
      "h",
      "l",
      "/",
      "Enter",
      "Escape",
      "ArrowUp",
      "ArrowDown",
      "ArrowLeft",
      "ArrowRight",
      "Backspace",
      " ",
      ":",
      "q"
    ]

    # Also allow alphanumeric characters for search/command input
    key in valid_keys or (String.length(key) == 1 and String.match?(key, ~r/^[a-zA-Z0-9]$/))
  end

  defp valid_input_key?(_), do: false

  defp process_valid_input(key, socket, adaptive) do
    # Process key through debouncer
    {debouncer, keys_to_process} =
      case InputDebouncer.process_key(socket.assigns.input_debouncer, key) do
        {:immediate, key} ->
          # Process immediately
          RaxolApp.send_input(socket.assigns.raxol_pid, key)
          {socket.assigns.input_debouncer, []}

        {:debounced, new_debouncer} ->
          # Key is being debounced
          {new_debouncer, []}

        {:batched, keys, new_debouncer} ->
          # Process batch of keys
          {new_debouncer, keys}

        {:batch_with_immediate, batch_keys, immediate_key, new_debouncer} ->
          # Process batch then immediate key
          Enum.each(batch_keys, &RaxolApp.send_input(socket.assigns.raxol_pid, &1))
          RaxolApp.send_input(socket.assigns.raxol_pid, immediate_key)
          {new_debouncer, []}

        {:batch_then_start, keys, new_debouncer} ->
          # Process previous batch, start new one
          {new_debouncer, keys}
      end

    # Process any batched keys
    Enum.each(keys_to_process, &RaxolApp.send_input(socket.assigns.raxol_pid, &1))

    # Mark buffer as dirty for immediate render
    adaptive = AdaptiveRefresh.mark_dirty(adaptive)

    {:noreply,
     socket
     |> assign(:adaptive_refresh, adaptive)
     |> assign(:input_debouncer, debouncer)}
  end

  # Process commands that were queued during disconnection
  defp process_queued_commands(socket, commands) do
    Enum.reduce(commands, socket, fn command, acc_socket ->
      # Send command to RaxolApp
      RaxolApp.send_input(acc_socket.assigns.raxol_pid, command)
      acc_socket
    end)
  end

  defp calculate_reconnect_delay(recovery) do
    base_delay = 1000
    max_delay = 30_000
    delay = base_delay * :math.pow(2, recovery.reconnect_attempts - 1)
    jitter = :rand.uniform(1000)

    (delay + jitter)
    |> round()
    |> min(max_delay)
  end

  # Schedule next tick based on adaptive refresh rate
  defp schedule_next_tick(adaptive_refresh) do
    interval = AdaptiveRefresh.get_interval_ms(adaptive_refresh)
    Process.send_after(self(), :tick, interval)
  end

  # Configuration function for switching between terminal bridges
end
