defmodule DroodotfooWeb.DroodotfooLive.EventHandlers do
  @moduledoc """
  Event handlers for DroodotfooLive.
  Handles all LiveView events (handle_event callbacks) and keyboard input processing.
  """

  require Logger

  alias Droodotfoo.{AdaptiveRefresh, InputDebouncer, InputRateLimiter, RaxolApp, TerminalBridge}
  alias Droodotfoo.Web3.Auth
  alias DroodotfooWeb.DroodotfooLive.Helpers
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [push_event: 3]

  # Event handlers for settings and preferences

  def handle_event("set_vim_mode", %{"enabled" => enabled}, socket) do
    # Set vim mode from client (loaded from localStorage)
    RaxolApp.send_input(
      socket.assigns.raxol_pid,
      if(enabled, do: "set_vim_on", else: "set_vim_off")
    )

    {:noreply, assign(socket, :vim_mode, enabled)}
  end

  def handle_event("restore_section", %{"section" => section_str}, socket) do
    # Restore section from localStorage
    section_atom = String.to_existing_atom(section_str)
    breadcrumb = Helpers.section_to_breadcrumb(section_atom)

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

  def handle_event("set_theme", %{"theme" => theme}, socket) do
    # Set theme from client (loaded from localStorage)
    {:noreply, assign(socket, :current_theme, theme)}
  end

  def handle_event("change_theme", %{"theme" => theme}, socket) do
    # Theme changed via dropdown
    {:noreply,
     socket
     |> assign(:current_theme, theme)
     |> push_event("theme_changed", %{theme: theme})}
  end

  def handle_event("toggle_terminal", _params, socket) do
    new_state = !socket.assigns.terminal_visible

    {:noreply,
     socket
     |> assign(:terminal_visible, new_state)
     |> push_event("save_terminal_pref", %{visible: new_state})}
  end

  def handle_event("set_terminal_visible", %{"visible" => visible}, socket) do
    # Restore terminal visibility from localStorage
    {:noreply, assign(socket, :terminal_visible, visible)}
  end

  # STL Viewer event handlers (from hook)

  def handle_event(
        "model_loaded",
        %{"triangles" => _triangles, "vertices" => _vertices, "bounds" => _bounds},
        socket
      ) do
    # Event handled successfully - component manages its own state
    {:noreply, socket}
  end

  def handle_event("model_error", %{"error" => _error}, socket) do
    # Event handled successfully - component manages its own state
    {:noreply, socket}
  end

  # Region click handler - new data-driven approach

  def handle_event("region_click", %{"region_id" => region_id}, socket) do
    Logger.debug("Region clicked: #{region_id}")

    # Get clickable regions from RaxolApp
    clickable_regions = RaxolApp.get_clickable_regions(socket.assigns.raxol_pid)

    # Validate that this is a valid region
    case Map.get(clickable_regions.regions, String.to_existing_atom(region_id)) do
      nil ->
        Logger.warning("Unknown region clicked: #{region_id}")
        {:noreply, socket}

      region ->
        # Handle different region types
        case region.type do
          :navigation ->
            handle_navigation_click(socket, region, region_id)

          :action ->
            handle_action_click(socket, region, region_id)

          :content ->
            handle_content_click(socket, region, region_id)

          _ ->
            Logger.debug("Unknown region type clicked: #{region_id}")
            {:noreply, socket}
        end
    end
  rescue
    ArgumentError ->
      Logger.warning("Invalid region ID: #{region_id}")
      {:noreply, socket}
  end

  # Legacy cell click handler - kept for backwards compatibility
  # This is now only used as a fallback when clicking non-clickable cells

  def handle_event("cell_click", %{"row" => row, "col" => col}, socket) do
    Logger.debug("Non-region cell clicked at row=#{row}, col=#{col} (fallback handler)")
    {:noreply, socket}
  end

  def handle_event("recalculate_grid", _params, socket) do
    # Trigger grid recalculation after font size change
    buffer = RaxolApp.get_buffer(socket.assigns.raxol_pid)
    clickable_regions = RaxolApp.get_clickable_regions(socket.assigns.raxol_pid)

    # Use terminal bridge for HTML generation with clickable regions
    html_content = TerminalBridge.terminal_to_html(buffer, clickable_regions)

    # Send updated HTML to client
    {:noreply, push_event(socket, "update_grid", %{html: html_content})}
  end

  # Viewport dimensions update handler (for responsive scrolling)
  def handle_event("update_viewport", %{"viewport_height" => height}, socket)
      when is_integer(height) and height > 0 do
    # Send viewport height to RaxolApp for dynamic scroll calculations
    RaxolApp.set_viewport_height(socket.assigns.raxol_pid, height)

    Logger.debug("Viewport height updated: #{height} rows")
    {:noreply, socket}
  end

  def handle_event("update_viewport", _params, socket) do
    # Invalid viewport data, ignore silently
    {:noreply, socket}
  end

  # Mouse wheel scroll event handler
  def handle_event("scroll_content", %{"delta" => delta}, socket) do
    require Logger

    # Debug logging
    Logger.debug(
      "Scroll event - terminal_visible: #{socket.assigns.terminal_visible}, boot_in_progress: #{socket.assigns.boot_in_progress}"
    )

    # Only process scroll events when terminal is visible and not in boot
    if socket.assigns.terminal_visible and not socket.assigns.boot_in_progress do
      # Send multiple j/k keypresses based on delta magnitude for smooth scrolling
      # delta is the number of lines to scroll (positive = down, negative = up)
      lines_to_scroll = abs(delta)
      key = if delta > 0, do: "j", else: "k"

      current_section = RaxolApp.get_current_section(socket.assigns.raxol_pid)

      Logger.debug(
        "Sending #{lines_to_scroll} x '#{key}' keypresses, current_section: #{current_section}"
      )

      # Send multiple keypresses for smooth scrolling (up to 10 lines per wheel event)
      # This gives much better feedback than a single PageDown/PageUp
      for _ <- 1..min(lines_to_scroll, 10) do
        RaxolApp.send_input(socket.assigns.raxol_pid, key)
      end

      # Mark buffer as dirty for immediate render
      adaptive = AdaptiveRefresh.mark_dirty(socket.assigns.adaptive_refresh)

      # Force immediate render by sending tick message
      send(self(), :tick)

      {:noreply, assign(socket, :adaptive_refresh, adaptive)}
    else
      Logger.debug("Scroll blocked - terminal not visible or boot in progress")
      {:noreply, socket}
    end
  end

  # Keyboard event handler

  def handle_event("key_press", %{"key" => key}, socket) do
    # Backtick always toggles terminal, even during boot
    # Escape always closes terminal if visible
    cond do
      key == "`" ->
        handle_backtick_key(socket)

      key == "Escape" and socket.assigns.terminal_visible ->
        handle_escape_key(socket)

      true ->
        handle_other_key(key, socket)
    end
  end

  # Web3 wallet event handler

  def handle_event(
        "web3_connect_success",
        %{
          "address" => address,
          "chainId" => chain_id,
          "signature" => signature,
          "nonce" => nonce
        },
        socket
      ) do
    # Verify the signature and recover the address
    case Auth.verify_signature(address, nonce, signature) do
      {:ok, verified_address} ->
        # Store the wallet session
        Droodotfoo.Web3.start_session(verified_address, chain_id)

        # Update RaxolApp state
        RaxolApp.set_web3_wallet(socket.assigns.raxol_pid, verified_address, chain_id)

        {:noreply, socket}

      {:error, _reason} ->
        # Authentication failed
        {:noreply,
         push_event(socket, "web3_auth_failed", %{error: "Signature verification failed"})}
    end
  end

  # Input processing helpers

  defp handle_backtick_key(socket) do
    new_state = !socket.assigns.terminal_visible

    {:noreply,
     socket
     |> assign(:terminal_visible, new_state)
     |> push_event("save_terminal_pref", %{visible: new_state})}
  end

  defp handle_escape_key(socket) do
    # Escape closes the terminal if it's visible
    {:noreply,
     socket
     |> assign(:terminal_visible, false)
     |> push_event("save_terminal_pref", %{visible: false})}
  end

  defp handle_other_key(key, socket) do
    # Only process other keys if terminal is visible
    if socket.assigns.terminal_visible do
      process_key_input(key, socket)
    else
      {:noreply, socket}
    end
  end

  defp process_key_input(key, socket) do
    # Block input during boot sequence
    if socket.assigns.boot_in_progress do
      {:noreply, socket}
    else
      process_key_with_rate_limiting(key, socket)
    end
  end

  defp process_key_with_rate_limiting(key, socket) do
    # Check rate limiting first
    {allowed?, rate_limiter} = InputRateLimiter.allow_event?(socket.assigns.rate_limiter)
    socket = assign(socket, :rate_limiter, rate_limiter)

    if allowed? do
      process_key_validation(key, socket)
    else
      # Event blocked by rate limiter
      {:noreply, socket}
    end
  end

  defp process_key_validation(key, socket) do
    # Validate input key
    if valid_input_key?(key) do
      # Record activity in adaptive refresh
      adaptive = AdaptiveRefresh.record_activity(socket.assigns.adaptive_refresh)
      process_valid_input(key, socket, adaptive)
    else
      {:noreply, socket}
    end
  end

  defp valid_input_key?(nil), do: false
  defp valid_input_key?(""), do: false

  defp valid_input_key?(key) when is_binary(key) do
    # Whitelist of allowed keys
    # Note: lowercase 't' removed from special keys - now handled as regular alphanumeric
    # This allows 't' to work in command bar without triggering theme toggle
    valid_keys = [
      "j",
      "k",
      "h",
      "l",
      "/",
      "Enter",
      "Escape",
      "Tab",
      "ArrowUp",
      "ArrowDown",
      "ArrowLeft",
      "ArrowRight",
      "PageDown",
      "PageUp",
      "Backspace",
      " ",
      ":",
      "q",
      "v",
      "V",
      "T",
      "g",
      "G",
      "?",
      "r",
      "m",
      "d",
      "u"
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

  # Region click handlers for different types

  defp handle_navigation_click(socket, region, region_id) do
    menu_idx = region.metadata[:index] || region.metadata["index"]
    Logger.debug("Navigation region #{region_id} clicked, index=#{menu_idx}")

    # Send cursor movement and selection to RaxolApp
    RaxolApp.send_input(socket.assigns.raxol_pid, "cursor_set:#{menu_idx}")
    RaxolApp.send_input(socket.assigns.raxol_pid, "Enter")

    # Mark as dirty for immediate render
    adaptive = AdaptiveRefresh.mark_dirty(socket.assigns.adaptive_refresh)
    {:noreply, assign(socket, :adaptive_refresh, adaptive)}
  end

  defp handle_action_click(socket, region, region_id) do
    Logger.debug("Action region #{region_id} clicked, action=#{region.action}")

    # Parse action and execute
    case region.action do
      "play:" <> game_type ->
        # Launch game by sending command
        RaxolApp.send_input(socket.assigns.raxol_pid, ":")
        RaxolApp.send_input(socket.assigns.raxol_pid, game_type)
        RaxolApp.send_input(socket.assigns.raxol_pid, "Enter")

        adaptive = AdaptiveRefresh.mark_dirty(socket.assigns.adaptive_refresh)
        {:noreply, assign(socket, :adaptive_refresh, adaptive)}

      "web3:connect" ->
        # Trigger Web3 wallet connection
        # The Web3 hook will handle the actual connection
        {:noreply, push_event(socket, "web3_connect_requested", %{})}

      "focus_command_bar" ->
        # Focus the command bar by sending Tab key
        RaxolApp.send_input(socket.assigns.raxol_pid, "Tab")

        adaptive = AdaptiveRefresh.mark_dirty(socket.assigns.adaptive_refresh)
        {:noreply, assign(socket, :adaptive_refresh, adaptive)}

      "navigate:" <> destination ->
        Logger.debug("Navigate to #{destination}")
        # Handle navigation actions
        {:noreply, socket}

      _ ->
        Logger.debug("Unknown action: #{region.action}")
        {:noreply, socket}
    end
  end

  defp handle_content_click(socket, region, region_id) do
    Logger.debug("Content region #{region_id} clicked")

    # Handle content region clicks (projects, links, etc.)
    case region.action do
      "view:project:" <> idx_str ->
        # View project details
        idx = String.to_integer(idx_str)
        Logger.debug("View project at index #{idx}")

        # Send navigation to project detail view
        RaxolApp.send_input(socket.assigns.raxol_pid, "Enter")

        adaptive = AdaptiveRefresh.mark_dirty(socket.assigns.adaptive_refresh)
        {:noreply, assign(socket, :adaptive_refresh, adaptive)}

      _ ->
        Logger.debug("Unknown content action: #{region.action}")
        {:noreply, socket}
    end
  end
end
