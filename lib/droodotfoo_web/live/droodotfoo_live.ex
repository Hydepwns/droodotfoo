defmodule DroodotfooWeb.DroodotfooLive do
  use DroodotfooWeb, :live_view
  alias Droodotfoo.TerminalBridge
  alias Droodotfoo.{RaxolApp, AdaptiveRefresh, InputDebouncer, InputRateLimiter, BootSequence}
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

    # Start boot sequence on connected socket
    if connected?(socket) do
      # Schedule first boot step
      delay = BootSequence.delay_for_step(1)
      Process.send_after(self(), :boot_next_step, delay)

      # Generate initial boot display
      boot_html = render_boot_sequence(0)

      {:ok,
       socket
       |> assign(:raxol_pid, raxol_pid)
       |> assign(:terminal_html, boot_html)
       |> assign(:boot_in_progress, true)
       |> assign(:boot_step, 0)
       |> assign(:current_section, :home)
       |> assign(:last_render_time, System.monotonic_time(:millisecond))
       |> assign(:connection_recovery, ConnectionRecovery.new())
       |> assign(:adaptive_refresh, adaptive_refresh)
       |> assign(:input_debouncer, input_debouncer)
       |> assign(:rate_limiter, rate_limiter)
       |> assign(:last_buffer_hash, 0)
       |> assign(:performance_mode, :normal)
       |> assign(:tick_timer, nil)
       |> assign(:vim_mode, false)
       |> assign(:loading, false)
       |> assign(:breadcrumb_path, ["Home"])
       |> assign(:current_theme, "theme-synthwave84")
       |> assign(:crt_mode, false)
       |> assign(:high_contrast_mode, false)
       |> assign(:screen_reader_message, "Welcome to droo.foo terminal")}
    else
      # Not connected yet, show blank screen
      {:ok,
       socket
       |> assign(:raxol_pid, raxol_pid)
       |> assign(:terminal_html, "")
       |> assign(:boot_in_progress, false)
       |> assign(:boot_step, 0)
       |> assign(:current_section, :home)
       |> assign(:last_render_time, System.monotonic_time(:millisecond))
       |> assign(:connection_recovery, ConnectionRecovery.new())
       |> assign(:adaptive_refresh, adaptive_refresh)
       |> assign(:input_debouncer, input_debouncer)
       |> assign(:rate_limiter, rate_limiter)
       |> assign(:last_buffer_hash, 0)
       |> assign(:performance_mode, :normal)
       |> assign(:tick_timer, nil)
       |> assign(:vim_mode, false)
       |> assign(:loading, false)
       |> assign(:breadcrumb_path, ["Home"])
       |> assign(:current_theme, "theme-synthwave84")
       |> assign(:crt_mode, false)
       |> assign(:high_contrast_mode, false)
       |> assign(:screen_reader_message, "Welcome to droo.foo terminal")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="monospace-web-container monospace-container" role="main">
      <!-- Screen reader announcements -->
      <div
        id="screen-reader-announcements"
        role="status"
        aria-live="polite"
        aria-atomic="true"
        class="sr-only"
      >
        {assigns[:screen_reader_message] || ""}
      </div>

      <!-- Connection status indicator -->
      <%= if assigns[:connection_recovery] do %>
        <% status_info = ConnectionRecovery.get_status_display(@connection_recovery) %>
        <%= if status_info.show do %>
          <div class={"connection-status #{status_info.class}"} role="status" aria-live="polite">
            {status_info.status}
          </div>
        <% end %>
      <% end %>

    <!-- Loading indicator -->
      <%= if @loading do %>
        <div class="loading-indicator" role="status" aria-live="polite">
          <div class="loading-spinner" aria-hidden="true"></div>
          <span>Loading...</span>
        </div>
      <% end %>

    <!-- Terminal container with monospace grid -->
      <div
        class={"terminal-wrapper #{@current_theme} #{if @crt_mode, do: "crt-mode", else: ""} #{if @high_contrast_mode, do: "high-contrast", else: ""}"}
        id="terminal-wrapper"
        role="application"
        aria-label="Interactive terminal interface"
        phx-hook="TerminalHook"
        phx-window-keydown="key_press"
        tabindex="0"
      >
        <!-- Monospace-web style header inside terminal -->
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

        {raw(@terminal_html)}
        
    <!-- STL Viewer Canvas (conditional, inside terminal-wrapper) -->
        <%= if @current_section == :stl_viewer do %>
          <div id="stl-viewer-container" phx-hook="STLViewerHook" phx-update="ignore">
            <canvas id="stl-canvas"></canvas>
          </div>
        <% end %>
        
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
      
    <!-- Footer -->
      <div class="instructions-box">
        Disable adblockers for best experience • I don't collect any data or use analytics here
      </div>
    </div>
    """
  end

  @impl true
  def handle_info(:boot_next_step, socket) do
    next_step = socket.assigns.boot_step + 1

    if BootSequence.complete?(next_step) do
      # Boot sequence complete, transition to normal terminal
      initial_buffer = RaxolApp.get_buffer(socket.assigns.raxol_pid)
      initial_html = TerminalBridge.terminal_to_html(initial_buffer)
      initial_buffer_hash = :erlang.phash2(initial_buffer)

      # Start normal tick cycle
      schedule_next_tick(socket.assigns.adaptive_refresh)

      {:noreply,
       socket
       |> assign(:boot_in_progress, false)
       |> assign(:terminal_html, initial_html)
       |> assign(:last_buffer_hash, initial_buffer_hash)}
    else
      # Advance to next boot step
      boot_html = render_boot_sequence(next_step)

      # Schedule next step
      next_delay = BootSequence.delay_for_step(next_step + 1)
      Process.send_after(self(), :boot_next_step, next_delay)

      {:noreply,
       socket
       |> assign(:boot_step, next_step)
       |> assign(:terminal_html, boot_html)}
    end
  end

  @impl true
  def handle_info({:update_connection_status, status}, socket) do
    # Update connection recovery status
    recovery = %{socket.assigns.connection_recovery | status: status}
    {:noreply, assign(socket, :connection_recovery, recovery)}
  end

  @impl true
  def handle_info(:tick, socket) do
    # Skip tick processing during boot sequence
    if socket.assigns.boot_in_progress do
      {:noreply, socket}
    else
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

        # Check for section changes
        current_section = RaxolApp.get_current_section(socket.assigns.raxol_pid)
        section_changed = current_section != socket.assigns.current_section

        socket =
          if section_changed do
            breadcrumb = section_to_breadcrumb(current_section)
            sr_message = announce_section_change(current_section)

            socket
            |> assign(:current_section, current_section)
            |> assign(:breadcrumb_path, breadcrumb)
            |> assign(:loading, false)
            |> assign(:screen_reader_message, sr_message)
            |> push_event("section_changed", %{section: Atom.to_string(current_section)})
          else
            socket
          end

        # Check for theme changes
        theme_change = RaxolApp.get_theme_change(socket.assigns.raxol_pid)

        socket =
          if theme_change do
            socket
            |> assign(:current_theme, theme_change)
            |> push_event("theme_changed", %{theme: theme_change})
          else
            socket
          end

        # Check for STL viewer actions
        stl_action = RaxolApp.get_stl_viewer_action(socket.assigns.raxol_pid)

        socket =
          if stl_action do
            handle_stl_viewer_action(socket, stl_action)
          else
            socket
          end

        # Check for CRT mode changes
        crt_mode = RaxolApp.get_crt_mode(socket.assigns.raxol_pid)

        socket =
          if crt_mode != socket.assigns[:crt_mode] do
            assign(socket, :crt_mode, crt_mode)
          else
            socket
          end

        # Check for high contrast mode changes
        high_contrast_mode = RaxolApp.get_high_contrast_mode(socket.assigns.raxol_pid)

        socket =
          if high_contrast_mode != socket.assigns[:high_contrast_mode] do
            assign(socket, :high_contrast_mode, high_contrast_mode)
          else
            socket
          end

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
  def handle_event("set_vim_mode", %{"enabled" => enabled}, socket) do
    # Set vim mode from client (loaded from localStorage)
    RaxolApp.send_input(
      socket.assigns.raxol_pid,
      if(enabled, do: "set_vim_on", else: "set_vim_off")
    )

    {:noreply, assign(socket, :vim_mode, enabled)}
  end

  @impl true
  def handle_event("restore_section", %{"section" => section_str}, socket) do
    # Restore section from localStorage
    section_atom = String.to_existing_atom(section_str)
    breadcrumb = section_to_breadcrumb(section_atom)

    # Send to RaxolApp to restore state
    RaxolApp.send_input(socket.assigns.raxol_pid, "restore_section:#{section_str}")

    {:noreply,
     socket
     |> assign(:current_section, section_atom)
     |> assign(:breadcrumb_path, breadcrumb)}
  catch
    _kind, _reason ->
      # Invalid section, ignore
      {:noreply, socket}
  end

  @impl true
  def handle_event("set_theme", %{"theme" => theme}, socket) do
    # Set theme from client (loaded from localStorage)
    {:noreply, assign(socket, :current_theme, theme)}
  end

  @impl true
  def handle_event("change_theme", %{"theme" => theme}, socket) do
    # Theme changed via dropdown
    {:noreply,
     socket
     |> assign(:current_theme, theme)
     |> push_event("theme_changed", %{theme: theme})}
  end

  @impl true
  def handle_event("key_press", %{"key" => key}, socket) do
    # Block input during boot sequence
    if socket.assigns.boot_in_progress do
      {:noreply, socket}
    else
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
  end

  def handle_event("cell_click", %{"row" => row, "col" => col}, socket) do
    # Debug logging
    IO.inspect({:cell_click, row, col}, label: "Cell clicked")

    # Handle cell click - navigation menu is at rows 15-20, cols 0-29
    # Row 15 = Home (idx 0)
    # Row 16 = Projects (idx 1)
    # Row 17 = Skills (idx 2)
    # Row 18 = Experience (idx 3)
    # Row 19 = Contact (idx 4)
    # Row 20 = STL Viewer (idx 5)

    nav_start_row = 15
    nav_end_row = 20
    nav_start_col = 0
    nav_end_col = 29

    if row >= nav_start_row and row <= nav_end_row and
         col >= nav_start_col and col <= nav_end_col do
      IO.puts("Navigation clicked! menu_idx: #{row - nav_start_row}")
      # Calculate which menu item was clicked
      menu_idx = row - nav_start_row

      # Send cursor movement and selection to RaxolApp
      # First move cursor to the item
      RaxolApp.send_input(socket.assigns.raxol_pid, "cursor_set:#{menu_idx}")
      # Then select it
      RaxolApp.send_input(socket.assigns.raxol_pid, "Enter")

      # Mark as dirty for immediate render
      adaptive = AdaptiveRefresh.mark_dirty(socket.assigns.adaptive_refresh)
      {:noreply, assign(socket, :adaptive_refresh, adaptive)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("recalculate_grid", _params, socket) do
    # Trigger grid recalculation after font size change
    buffer = RaxolApp.get_buffer(socket.assigns.raxol_pid)

    # Use terminal bridge for HTML generation
    html_content = Droodotfoo.TerminalBridge.terminal_to_html(buffer)

    # Send updated HTML to client
    {:noreply, push_event(socket, "update_grid", %{html: html_content})}
  end

  # STL Viewer event handlers
  def handle_event(
        "stl_model_loaded",
        %{"triangles" => triangles, "vertices" => vertices, "bounds" => _bounds},
        socket
      ) do
    # For now, just acknowledge the load
    IO.puts("STL model loaded: #{triangles} triangles, #{vertices} vertices")
    {:noreply, socket}
  end

  def handle_event("stl_load_error", %{"error" => error}, socket) do
    IO.puts("STL load error: #{error}")
    {:noreply, socket}
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
      "q",
      "v",
      "V",
      "t",
      "T",
      "g",
      "G",
      "?",
      "r",
      "m"
    ]

    # Also allow alphanumeric characters for search/command input
    key in valid_keys or (String.length(key) == 1 and String.match?(key, ~r/^[a-zA-Z0-9]$/))
  end

  defp valid_input_key?(_), do: false

  defp process_valid_input(key, socket, adaptive) do
    # Special handling for vim mode toggle - need to notify client for persistence
    socket =
      if key in ["v", "V"] do
        # Send the key to RaxolApp to toggle vim mode
        RaxolApp.send_input(socket.assigns.raxol_pid, key)

        # Get the updated state to check new vim mode value
        # We'll push the event optimistically - assuming toggle worked
        # In a real scenario, we'd want to check the actual state
        # For now, we'll track vim_mode in assigns
        current_vim_mode = Map.get(socket.assigns, :vim_mode, false)
        new_vim_mode = !current_vim_mode

        socket
        |> assign(:vim_mode, new_vim_mode)
        |> push_event("vim_mode_changed", %{enabled: new_vim_mode})
      else
        socket
      end

    # Process key through debouncer (skip if we already sent it for vim mode)
    {debouncer, keys_to_process} =
      if key in ["v", "V"] do
        # Already processed above
        {socket.assigns.input_debouncer, []}
      else
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

  # Helper to convert section atoms to breadcrumb paths
  defp section_to_breadcrumb(:home), do: ["Home"]
  defp section_to_breadcrumb(:projects), do: ["Home", "Projects"]
  defp section_to_breadcrumb(:skills), do: ["Home", "Skills"]
  defp section_to_breadcrumb(:experience), do: ["Home", "Experience"]
  defp section_to_breadcrumb(:contact), do: ["Home", "Contact"]
  defp section_to_breadcrumb(:terminal), do: ["Home", "Terminal"]
  defp section_to_breadcrumb(:search_results), do: ["Home", "Search Results"]
  defp section_to_breadcrumb(:performance), do: ["Home", "Performance"]
  defp section_to_breadcrumb(:matrix), do: ["Home", "Matrix"]
  defp section_to_breadcrumb(:ssh), do: ["Home", "SSH Demo"]
  defp section_to_breadcrumb(:analytics), do: ["Home", "Analytics"]
  defp section_to_breadcrumb(:help), do: ["Home", "Help"]
  defp section_to_breadcrumb(:stl_viewer), do: ["Home", "STL Viewer"]
  defp section_to_breadcrumb(_), do: ["Home"]

  # Screen reader announcements for section changes
  defp announce_section_change(:home), do: "Navigated to Home section"
  defp announce_section_change(:projects), do: "Navigated to Projects section. Browse my portfolio projects."
  defp announce_section_change(:skills), do: "Navigated to Skills section. View my technical expertise."
  defp announce_section_change(:experience), do: "Navigated to Experience section. Review my work history."
  defp announce_section_change(:contact), do: "Navigated to Contact section. Get in touch with me."
  defp announce_section_change(:terminal), do: "Navigated to Terminal mode. Interactive command line interface."
  defp announce_section_change(:search_results), do: "Showing search results"
  defp announce_section_change(:performance), do: "Navigated to Performance Dashboard. Real-time metrics and charts."
  defp announce_section_change(:matrix), do: "Navigated to Matrix plugin. Digital rain effect."
  defp announce_section_change(:help), do: "Navigated to Help section. Available commands and keyboard shortcuts."
  defp announce_section_change(:stl_viewer), do: "Navigated to STL 3D Viewer. Interactive 3D model viewer."
  defp announce_section_change(_), do: "Section changed"

  # Handle STL viewer actions from keyboard
  defp handle_stl_viewer_action(socket, {:rotate, direction}) do
    angle =
      case direction do
        :up -> -0.1
        :down -> 0.1
        _ -> 0.1
      end

    push_event(socket, "stl_rotate", %{axis: "y", angle: angle})
  end

  defp handle_stl_viewer_action(socket, {:zoom, direction}) do
    # Simulate zoom by moving camera
    distance =
      case direction do
        :in -> -0.5
        :out -> 0.5
        _ -> 0.5
      end

    push_event(socket, "stl_zoom", %{distance: distance})
  end

  defp handle_stl_viewer_action(socket, {:reset, _}) do
    push_event(socket, "stl_reset", %{})
  end

  defp handle_stl_viewer_action(socket, {:cycle_mode, _}) do
    push_event(socket, "stl_cycle_mode", %{})
  end

  defp handle_stl_viewer_action(socket, _), do: socket

  # Render boot sequence to HTML
  defp render_boot_sequence(step) do
    lines = BootSequence.render(step)

    # Convert lines to simple HTML with monospace styling
    lines
    |> Enum.map(fn line ->
      # Escape HTML and preserve spaces
      "<div class=\"terminal-line\">#{Phoenix.HTML.html_escape(line) |> Phoenix.HTML.safe_to_string()}</div>"
    end)
    |> Enum.join("\n")
  end

  # Configuration function for switching between terminal bridges
end
