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
      <!-- Terminal Toggle Button (visible on desktop, hidden on mobile) -->
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
        <header class="post-header" style="margin-bottom: 1.5rem; padding: 0rem;">
          <div class="post-header-grid">
            <div class="post-header-content">
              <h1
                class="post-title"
                style="font-size: 3rem; margin-top: 0.25rem; margin-bottom: 0.25rem; text-align: left;"
              >
                DROO.FOO
              </h1>
              <p class="post-description" style="margin: 0; padding: 0;">
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
                    DROO AMOR
                  </a>
                </span>
              </div>
            </div>
          </div>
        </header>

        <%= if length(@latest_posts) > 0 do %>
          <section style="margin-bottom: 2rem;">
            <h2 style="border-bottom: 2px solid var(--border-color); padding-bottom: 0.5rem; margin-bottom: 1rem;">
              LATEST
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
            LINKS
          </h2>
          <ul style="list-style: none; padding: 0;">
            <li style="margin-bottom: 0.5rem;">
              <a href="#" phx-click="toggle_terminal" style="text-decoration: none;">
                → Open Terminal (press backtick)
              </a>
            </li>
          </ul>

          <h3 style="margin-top: 1.5rem; margin-bottom: 0.5rem;">CONNECT</h3>
          <hr style="border: none; border-top: 2px solid var(--border-color); margin-bottom: 1rem;" />
          <div class="social-links" style="display: flex; gap: 1rem; flex-wrap: wrap;">
            <a
              href="https://github.com/Hydepwns"
              target="_blank"
              rel="noopener"
              class="social-icon"
              aria-label="GitHub"
              title="GitHub"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="28"
                height="28"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
              </svg>
            </a>

            <a
              href="https://x.com/MF_DROO"
              target="_blank"
              rel="noopener"
              class="social-icon"
              aria-label="Twitter/X"
              title="Twitter/X"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="28"
                height="28"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
              </svg>
            </a>

            <a
              href="https://www.linkedin.com/in/drew-hiro/"
              target="_blank"
              rel="noopener"
              class="social-icon"
              aria-label="LinkedIn"
              title="LinkedIn"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="28"
                height="28"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" />
              </svg>
            </a>

            <a
              href="https://t.me/MF_DROO"
              target="_blank"
              rel="noopener"
              class="social-icon"
              aria-label="Telegram"
              title="Telegram"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="28"
                height="28"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z" />
              </svg>
            </a>

            <a href="mailto:drew@axol.io" class="social-icon" aria-label="Email" title="Email">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="28"
                height="28"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M0 3v18h24v-18h-24zm6.623 7.929l-4.623 5.712v-9.458l4.623 3.746zm-4.141-5.929h19.035l-9.517 7.713-9.518-7.713zm5.694 7.188l3.824 3.099 3.83-3.104 5.612 6.817h-18.779l5.513-6.812zm9.208-1.264l4.616-3.741v9.348l-4.616-5.607z" />
              </svg>
            </a>

            <a
              href="https://discord.com/users/mf_droo"
              target="_blank"
              rel="noopener"
              class="social-icon"
              aria-label="Discord"
              title="Discord"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="28"
                height="28"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z" />
              </svg>
            </a>
          </div>
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
