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

  # Cell click handler for navigation

  def handle_event("cell_click", %{"row" => row, "col" => col}, socket) do
    # Debug logging
    Logger.debug("Cell clicked at row=#{row}, col=#{col}")

    # Handle cell click - navigation menu is at rows 15-22, cols 0-29
    # Navigation layout (after removing Tools section):
    # Row 15 (offset 0) = Home (idx 0)
    # Row 16 (offset 1) = Experience (idx 1)
    # Row 17 (offset 2) = Contact (idx 2)
    # Row 18 (offset 3) = "─ Fun ───" (section header - SKIP)
    # Row 19 (offset 4) = Games (idx 3)
    # Row 20 (offset 5) = Spotify (idx 4)
    # Row 21 (offset 6) = STL Viewer (idx 5)
    # Row 22 (offset 7) = Web3 (idx 6)

    nav_start_row = 15
    nav_end_row = 22
    nav_start_col = 0
    nav_end_col = 29

    if row >= nav_start_row and row <= nav_end_row and
         col >= nav_start_col and col <= nav_end_col do
      # Calculate which menu item was clicked, accounting for section header at offset 3
      offset = row - nav_start_row

      menu_idx =
        cond do
          # Rows 0-2: Direct mapping
          offset <= 2 -> offset
          # Row 3: Section header - ignore click
          offset == 3 -> nil
          # Rows 4-7: Subtract 1 to account for section header
          offset >= 4 -> offset - 1
        end

      if menu_idx do
        Logger.debug("Navigation clicked at offset=#{offset}, menu_idx=#{menu_idx}")

        # Send cursor movement and selection to RaxolApp
        # First move cursor to the item
        RaxolApp.send_input(socket.assigns.raxol_pid, "cursor_set:#{menu_idx}")
        # Then select it
        RaxolApp.send_input(socket.assigns.raxol_pid, "Enter")

        # Mark as dirty for immediate render
        adaptive = AdaptiveRefresh.mark_dirty(socket.assigns.adaptive_refresh)
        {:noreply, assign(socket, :adaptive_refresh, adaptive)}
      else
        Logger.debug("Section header clicked at offset=#{offset} - ignoring")
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("recalculate_grid", _params, socket) do
    # Trigger grid recalculation after font size change
    buffer = RaxolApp.get_buffer(socket.assigns.raxol_pid)

    # Use terminal bridge for HTML generation
    html_content = TerminalBridge.terminal_to_html(buffer)

    # Send updated HTML to client
    {:noreply, push_event(socket, "update_grid", %{html: html_content})}
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
end
