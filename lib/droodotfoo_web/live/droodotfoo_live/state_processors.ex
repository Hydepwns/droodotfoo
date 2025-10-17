defmodule DroodotfooWeb.DroodotfooLive.StateProcessors do
  @moduledoc """
  State processing pipeline for DroodotfooLive.
  Handles tick rendering and state change detection/processing.
  """

  alias Droodotfoo.{AdaptiveRefresh, RaxolApp, TerminalBridge}
  alias DroodotfooWeb.DroodotfooLive.{ActionHandlers, Helpers}
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [push_event: 3]

  @doc """
  Process tick render cycle with dirty checking and performance tracking.
  """
  def process_tick_render(socket, adaptive) do
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

    # Process all state changes
    socket = process_state_changes(socket)

    # Only record metrics for actual renders
    if should_update do
      Droodotfoo.PerformanceMonitor.record_render_time(render_time)
      # Push event to JS to verify grid alignment
      push_event(socket, "terminal_updated", %{})
    end

    # Schedule next tick based on adaptive refresh rate
    Helpers.schedule_next_tick(adaptive)

    {:noreply,
     socket
     |> assign(:terminal_html, html)
     |> assign(:last_render_time, render_time)
     |> assign(:adaptive_refresh, adaptive)
     |> assign(
       :last_buffer_hash,
       if(should_update, do: buffer_hash, else: socket.assigns.last_buffer_hash)
     )}
  end

  @doc """
  Process all state changes in a pipeline.
  """
  def process_state_changes(socket) do
    socket
    |> process_section_changes()
    |> process_theme_changes()
    |> process_stl_actions()
    |> process_spotify_actions()
    |> process_web3_actions()
    |> process_crt_mode_changes()
    |> process_high_contrast_changes()
  end

  @doc """
  Process section changes and update breadcrumb/screen reader.
  """
  def process_section_changes(socket) do
    current_section = RaxolApp.get_current_section(socket.assigns.raxol_pid)
    section_changed = current_section != socket.assigns.current_section

    if section_changed do
      breadcrumb = Helpers.section_to_breadcrumb(current_section)
      sr_message = Helpers.announce_section_change(current_section)

      socket
      |> assign(:current_section, current_section)
      |> assign(:breadcrumb_path, breadcrumb)
      |> assign(:loading, false)
      |> assign(:screen_reader_message, sr_message)
      |> push_event("section_changed", %{section: Atom.to_string(current_section)})
    else
      socket
    end
  end

  @doc """
  Process theme changes and push to client.
  """
  def process_theme_changes(socket) do
    theme_change = RaxolApp.get_theme_change(socket.assigns.raxol_pid)

    if theme_change do
      socket
      |> assign(:current_theme, theme_change)
      |> push_event("theme_changed", %{theme: theme_change})
    else
      socket
    end
  end

  @doc """
  Process STL viewer actions from RaxolApp.
  """
  def process_stl_actions(socket) do
    stl_action = RaxolApp.get_stl_viewer_action(socket.assigns.raxol_pid)

    if stl_action do
      ActionHandlers.handle_stl_viewer_action(socket, stl_action)
    else
      socket
    end
  end

  @doc """
  Process Spotify actions from RaxolApp.
  """
  def process_spotify_actions(socket) do
    spotify_action = RaxolApp.get_spotify_action(socket.assigns.raxol_pid)

    if spotify_action do
      ActionHandlers.handle_spotify_action(socket, spotify_action)
    else
      socket
    end
  end

  @doc """
  Process Web3 actions from RaxolApp.
  """
  def process_web3_actions(socket) do
    web3_action = RaxolApp.get_web3_action(socket.assigns.raxol_pid)

    if web3_action do
      ActionHandlers.handle_web3_action(socket, web3_action)
    else
      socket
    end
  end

  @doc """
  Process CRT mode changes.
  """
  def process_crt_mode_changes(socket) do
    crt_mode = RaxolApp.get_crt_mode(socket.assigns.raxol_pid)

    if crt_mode != socket.assigns[:crt_mode] do
      assign(socket, :crt_mode, crt_mode)
    else
      socket
    end
  end

  @doc """
  Process high contrast mode changes.
  """
  def process_high_contrast_changes(socket) do
    high_contrast_mode = RaxolApp.get_high_contrast_mode(socket.assigns.raxol_pid)

    if high_contrast_mode != socket.assigns[:high_contrast_mode] do
      assign(socket, :high_contrast_mode, high_contrast_mode)
    else
      socket
    end
  end
end
