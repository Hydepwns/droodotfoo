defmodule DroodotfooWeb.DroodotfooLive do
  @moduledoc """
  Main LiveView module for the droo.foo interactive terminal interface.

  This module has been refactored into focused submodules:
  - EventHandlers - All handle_event callbacks and input processing
  - MessageHandlers - All handle_info callbacks
  - StateProcessors - State change detection and processing pipeline
  - ActionHandlers - STL viewer, Spotify, and Web3 action handlers
  - Helpers - Utility functions (breadcrumbs, announcements, boot sequence)
  """

  use DroodotfooWeb, :live_view

  alias Droodotfoo.{AdaptiveRefresh, BootSequence, InputDebouncer, InputRateLimiter, RaxolApp}
  alias Droodotfoo.Content.Posts
  alias DroodotfooWeb.DroodotfooLive.{EventHandlers, Helpers, MessageHandlers}
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
      boot_html = Helpers.render_boot_sequence(0)

      # Load latest posts for homepage
      latest_posts =
        try do
          Posts.list_posts() |> Enum.take(5)
        rescue
          _ -> []
        end

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
       |> assign(:screen_reader_message, "Welcome to droo.foo")
       |> assign(:terminal_visible, false)
       |> assign(:latest_posts, latest_posts)}
    else
      # Not connected yet, show blank screen but still load posts
      latest_posts =
        try do
          Posts.list_posts() |> Enum.take(5)
        rescue
          _ -> []
        end

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
       |> assign(:screen_reader_message, "Welcome to droo.foo")
       |> assign(:terminal_visible, false)
       |> assign(:latest_posts, latest_posts)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="site-container" role="main">
      <!-- Terminal Toggle Button (always visible) -->
      <button
        class="terminal-toggle"
        phx-click="toggle_terminal"
        data-tooltip="Terminal (`)"
        aria-label="Toggle Terminal (backtick key)"
      >
        {if @terminal_visible, do: "×", else: "`"}
      </button>
      
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
      
    <!-- Terminal Overlay (always rendered, visibility controlled by CSS) -->
      <div class={"terminal-overlay #{if @terminal_visible, do: "active", else: ""}"}>
        <div
          class={"terminal-wrapper #{if @crt_mode, do: "crt-mode", else: ""} #{if @high_contrast_mode, do: "high-contrast", else: ""}"}
          id="terminal-wrapper"
          role="application"
          aria-label="Interactive terminal interface"
          phx-hook="TerminalHook"
          phx-window-keydown="key_press"
          tabindex="0"
        >
          <!-- Terminal buffer HTML -->
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
      </div>
      
    <!-- Homepage View (always rendered) -->
      <div class="monospace-container">
        <header class="post-header" style="margin-bottom: 2rem;">
          <div class="post-header-grid">
            <div class="post-header-content">
              <h1 class="post-title" style="font-size: 2rem;">DROO.FOO</h1>
              <p class="post-description">
                Building axol.io
              </p>
            </div>
            <div class="post-header-meta">
              <div class="meta-row">
                <span class="meta-label">Version</span>
                <span class="meta-value">v1.0.0</span>
              </div>
              <div class="meta-row">
                <span class="meta-label">Updated</span>
                <span class="meta-value">{Date.to_string(Date.utc_today())}</span>
              </div>
              <div class="meta-row">
                <span class="meta-label">Author</span>
                <span class="meta-value">
                  <a
                    href="https://github.com/hydepwns"
                    target="_blank"
                    rel="noopener"
                    style="color: inherit; text-decoration: underline;"
                  >
                    Hydepwns
                  </a>
                </span>
              </div>
            </div>
          </div>
        </header>

        <%= if length(@latest_posts) > 0 do %>
          <section style="margin-bottom: 2rem;">
            <h2 style="border-bottom: 2px solid var(--border-color); padding-bottom: 0.5rem; margin-bottom: 1rem;">
              LATEST POSTS
            </h2>
            <%= for post <- @latest_posts do %>
              <article class="box-single" style="margin-bottom: 1rem;">
                <h3 style="margin-bottom: 0.5rem;">
                  <a
                    href={"/posts/#{post.slug}"}
                    style="text-decoration: none; color: var(--text-color);"
                  >
                    {post.title}
                  </a>
                </h3>
                <p style="color: var(--text-color-alt); font-size: 0.875rem; margin-bottom: 0.5rem;">
                  {Date.to_string(post.date)} • {post.read_time} min read
                </p>
                <p>{post.description}</p>
              </article>
            <% end %>
          </section>
        <% end %>

        <section style="margin-bottom: 2rem;">
          <h2 style="border-bottom: 2px solid var(--border-color); padding-bottom: 0.5rem; margin-bottom: 1rem;">
            QUICK LINKS
          </h2>
          <ul style="list-style: none; padding: 0;">
            <li style="margin-bottom: 0.5rem;">
              <a href="#" phx-click="toggle_terminal" style="text-decoration: none;">
                → Open Terminal (or press backtick)
              </a>
            </li>
            <li style="margin-bottom: 0.5rem;">
              <a
                href="https://github.com/hydepwns"
                target="_blank"
                rel="noopener"
                style="text-decoration: none;"
              >
                → GitHub Profile
              </a>
            </li>
          </ul>
        </section>

        <footer class="instructions-box" style="margin-top: auto;">
          <span id="site-footer" phx-update="ignore">No tracking/analytics</span>
        </footer>
      </div>
    </div>
    """
  end

  # Delegate all handle_info callbacks to MessageHandlers module

  @impl true
  def handle_info(msg, socket), do: MessageHandlers.handle_info(msg, socket)

  # Delegate all handle_event callbacks to EventHandlers module

  @impl true
  def handle_event(event, params, socket), do: EventHandlers.handle_event(event, params, socket)
end
