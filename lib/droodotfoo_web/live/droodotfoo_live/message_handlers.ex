defmodule DroodotfooWeb.DroodotfooLive.MessageHandlers do
  @moduledoc """
  Message handlers for DroodotfooLive.
  Handles all handle_info callbacks for internal messages and process monitoring.
  """

  require Logger

  alias Droodotfoo.{AdaptiveRefresh, BootSequence, InputDebouncer, RaxolApp, TerminalBridge}
  alias DroodotfooWeb.DroodotfooLive.{Helpers, StateProcessors}
  alias DroodotfooWeb.Live.ConnectionRecovery
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [connected?: 1]

  @doc """
  Handle boot sequence progression.
  """
  def handle_info(:boot_next_step, socket) do
    next_step = socket.assigns.boot_step + 1

    if BootSequence.complete?(next_step) do
      # Boot sequence complete, transition to normal terminal
      initial_buffer = RaxolApp.get_buffer(socket.assigns.raxol_pid)
      initial_html = TerminalBridge.terminal_to_html(initial_buffer)
      initial_buffer_hash = :erlang.phash2(initial_buffer)

      # Start normal tick cycle
      Helpers.schedule_next_tick(socket.assigns.adaptive_refresh)

      {:noreply,
       socket
       |> assign(:boot_in_progress, false)
       |> assign(:terminal_html, initial_html)
       |> assign(:last_buffer_hash, initial_buffer_hash)}
    else
      # Advance to next boot step
      boot_html = Helpers.render_boot_sequence(next_step)

      # Schedule next step
      next_delay = BootSequence.delay_for_step(next_step + 1)
      Process.send_after(self(), :boot_next_step, next_delay)

      {:noreply,
       socket
       |> assign(:boot_step, next_step)
       |> assign(:terminal_html, boot_html)}
    end
  end

  # Handle connection status updates.
  def handle_info({:update_connection_status, status}, socket) do
    # Update connection recovery status
    recovery = %{socket.assigns.connection_recovery | status: status}
    {:noreply, assign(socket, :connection_recovery, recovery)}
  end

  # Handle STL viewer quit event.
  def handle_info({:stl_viewer_quit, _viewer_id}, socket) do
    # Navigate back to home when STL viewer quits
    RaxolApp.send_input(socket.assigns.raxol_pid, "q")

    {:noreply,
     socket
     |> assign(:current_section, :home)
     |> assign(:breadcrumb_path, Helpers.section_to_breadcrumb(:home))
     |> assign(:screen_reader_message, Helpers.announce_section_change(:home))}
  end

  # Handle process down notification.
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    recovery = ConnectionRecovery.handle_disconnect(socket.assigns.connection_recovery)
    recovery = ConnectionRecovery.attempt_reconnect(recovery)

    # Schedule reconnection attempt
    :timer.send_after(1000, self(), :attempt_reconnect)

    {:noreply, assign(socket, :connection_recovery, recovery)}
  end

  # Handle reconnection attempts.
  def handle_info(:attempt_reconnect, socket) do
    recovery = socket.assigns.connection_recovery

    if recovery.status == :reconnecting do
      handle_reconnection_attempt(socket, recovery)
    else
      {:noreply, socket}
    end
  end

  # Handle input debounce timeout.
  def handle_info({:debounce_timeout, :input}, socket) do
    {keys, debouncer} = InputDebouncer.handle_timeout(socket.assigns.input_debouncer)
    Enum.each(keys, &RaxolApp.send_input(socket.assigns.raxol_pid, &1))

    {:noreply, assign(socket, :input_debouncer, debouncer)}
  end

  # Handle tick messages for main render cycle.
  def handle_info(:tick, socket) do
    # Skip tick processing during boot sequence
    if socket.assigns.boot_in_progress do
      {:noreply, socket}
    else
      adaptive = socket.assigns.adaptive_refresh

      # Check if we should render based on adaptive refresh rate
      if AdaptiveRefresh.should_render?(adaptive) do
        StateProcessors.process_tick_render(socket, adaptive)
      else
        # Skip this tick, schedule next one
        Helpers.schedule_next_tick(adaptive)
        {:noreply, socket}
      end
    end
  end

  # Catch-all for unexpected messages to prevent crashes.
  def handle_info(msg, socket) do
    # Log unexpected messages in development
    if Mix.env() != :prod do
      Logger.debug("Unexpected message in DroodotfooLive: #{inspect(msg)}")
    end

    {:noreply, socket}
  end

  # Helper functions

  defp handle_reconnection_attempt(socket, recovery) do
    if connected?(socket) do
      process_successful_reconnection(socket, recovery)
    else
      # Still not connected, schedule another attempt
      :timer.send_after(2000, self(), :attempt_reconnect)
      {:noreply, socket}
    end
  end

  defp process_successful_reconnection(socket, recovery) do
    recovery = ConnectionRecovery.handle_reconnect_success(recovery)
    {queued_commands, recovery} = ConnectionRecovery.flush_queued_commands(recovery)

    # Process any queued commands
    Enum.each(queued_commands, fn command ->
      RaxolApp.send_input(socket.assigns.raxol_pid, command)
    end)

    {:noreply,
     socket
     |> assign(:connection_recovery, recovery)
     |> assign(:connection_status, :connected)}
  end
end
