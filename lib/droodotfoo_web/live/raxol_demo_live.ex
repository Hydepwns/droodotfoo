defmodule DroodotfooWeb.RaxolDemoLive do
  @moduledoc """
  Demo page showcasing the RaxolWeb.LiveView.TerminalComponent.

  This demonstrates the extracted and generalized terminal rendering
  components that will be contributed back to the Raxol framework.
  """

  use DroodotfooWeb, :live_view
  alias RaxolWeb.LiveView.TerminalComponent

  @impl true
  def mount(_params, _session, socket) do
    # Create a simple demo buffer
    buffer = create_demo_buffer()

    {:ok,
     socket
     |> assign(:buffer, buffer)
     |> assign(:current_theme, :synthwave84)
     |> assign(:crt_mode, false)
     |> assign(:high_contrast, false)
     |> assign(:log_messages, [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="raxol-demo-container"
      style="min-height: 100vh; background: #0a0a0a; color: #e0e0e0; padding: 2rem; font-family: monospace;"
    >
      <div style="max-width: 1100px; margin: 0 auto;">
        <!-- Header -->
        <div style="margin-bottom: 1.5rem; border-bottom: 2px solid #00ff00; padding-bottom: 0.5rem;">
          <pre style="color: #00ff00; margin: 0; line-height: 1.2; text-align: center;">╔══════════════════════════════════════════╗
    ║   RAXOLWEB TERMINAL COMPONENT DEMO      ║
    ╚══════════════════════════════════════════╝</pre>
          <p style="margin-top: 0.5rem; color: #666; text-align: center; font-size: 0.9rem;">
            Extracted terminal rendering components for web UIs
          </p>
        </div>
        <!-- Info Panel -->
        <div style="background: #1a1a1a; border: 1px solid #333; padding: 1rem; margin-bottom: 1rem;">
          <h2 style="color: #00ff00; margin-bottom: 0.75rem; font-size: 1rem;">
            [ IMPLEMENTATION ]
          </h2>

          <div style="margin-bottom: 0.75rem;">
            <h3 style="color: #0ff; margin-bottom: 0.25rem; font-size: 0.95rem;">Modules:</h3>
            <ul style="list-style: none; padding-left: 1rem; color: #888; font-size: 0.85rem;">
              <li style="margin-bottom: 0.15rem;">
                > <code style="color: #ff0">RaxolWeb.Renderer</code> - Buffer-to-HTML + caching
              </li>
              <li style="margin-bottom: 0.15rem;">
                > <code style="color: #ff0">RaxolWeb.Themes</code> - 7 color schemes
              </li>
              <li style="margin-bottom: 0.15rem;">
                > <code style="color: #ff0">RaxolWeb.LiveView.TerminalComponent</code> - LiveView
              </li>
            </ul>
          </div>

          <div style="margin-bottom: 0.75rem;">
            <h3 style="color: #0ff; margin-bottom: 0.25rem; font-size: 0.95rem;">Features:</h3>
            <ul style="list-style: none; padding-left: 1rem; color: #888; font-size: 0.85rem;">
              <li style="margin-bottom: 0.1rem;">+ Virtual DOM diffing</li>
              <li style="margin-bottom: 0.1rem;">+ Smart caching (98%+ hit)</li>
              <li style="margin-bottom: 0.1rem;">+ 1ch grid alignment</li>
              <li style="margin-bottom: 0.1rem;">+ 60fps rendering</li>
              <li style="margin-bottom: 0.1rem;">+ Event handling</li>
              <li style="margin-bottom: 0.1rem;">+ Accessibility</li>
            </ul>
          </div>

          <details style="margin-top: 0.5rem;">
            <summary style="color: #0ff; cursor: pointer; margin-bottom: 0.25rem; font-size: 0.85rem;">
              Buffer Format
            </summary>
            <pre style="background: #0a0a0a; color: #0f0; padding: 0.5rem; overflow-x: auto; border: 1px solid #00ff00; margin-top: 0.25rem; font-size: 0.75rem;"><code><%= buffer_format_example() %></code></pre>
          </details>
        </div>
        <!-- Event Log -->
        <div style="background: #1a1a1a; border: 1px solid #333; padding: 1rem; margin-bottom: 1rem;">
          <h2 style="color: #00ff00; margin-bottom: 0.5rem; font-size: 1rem;">[ EVENT LOG ]</h2>
          <div
            style="background: #0a0a0a; color: #0f0; padding: 0.5rem; font-family: monospace; height: 80px; overflow-y: auto; border: 1px solid #00ff00; font-size: 0.85rem;"
            id="event-log"
          >
            <%= if Enum.empty?(@log_messages) do %>
              <div style="color: #555;">Waiting for events...</div>
            <% else %>
              <%= for msg <- Enum.take(@log_messages, -10) do %>
                <div>{msg}</div>
              <% end %>
            <% end %>
          </div>
        </div>
        <!-- Terminal Rendering with Controls -->
        <div style="background: #1a1a1a; border: 1px solid #333; padding: 1rem;">
          <h2 style="color: #00ff00; margin-bottom: 0.5rem; font-size: 1rem;">
            [ TERMINAL ]
          </h2>
          <!-- Terminal Controls (moved here) -->
          <div style="margin-bottom: 0.75rem; padding: 0.5rem; background: #0a0a0a; border: 1px solid #333;">
            <form phx-change="change_theme" style="margin-bottom: 0.5rem;">
              <label style="display: inline; margin-right: 0.5rem; color: #888; font-size: 0.85rem;">
                Theme:
              </label>
              <select
                name="theme"
                style="padding: 0.25rem 0.4rem; font-family: monospace; background: #0a0a0a; color: #00ff00; border: 1px solid #00ff00; font-size: 0.85rem;"
              >
                <option value="synthwave84" selected={@current_theme == :synthwave84}>
                  Synthwave84
                </option>
                <option value="nord" selected={@current_theme == :nord}>Nord</option>
                <option value="dracula" selected={@current_theme == :dracula}>Dracula</option>
                <option value="monokai" selected={@current_theme == :monokai}>Monokai</option>
                <option value="gruvbox" selected={@current_theme == :gruvbox}>Gruvbox</option>
                <option value="solarized_dark" selected={@current_theme == :solarized_dark}>
                  Solarized Dark
                </option>
                <option value="tokyo_night" selected={@current_theme == :tokyo_night}>
                  Tokyo Night
                </option>
              </select>

              <label style="margin-left: 1rem; color: #888; cursor: pointer; font-size: 0.85rem;">
                <input type="checkbox" phx-click="toggle_crt" checked={@crt_mode} /> CRT
              </label>
              <label style="margin-left: 1rem; color: #888; cursor: pointer; font-size: 0.85rem;">
                <input
                  type="checkbox"
                  phx-click="toggle_high_contrast"
                  checked={@high_contrast}
                /> High Contrast
              </label>
              <button
                phx-click="update_buffer"
                style="margin-left: 1rem; padding: 0.25rem 0.5rem; background: #00ff00; color: #0a0a0a; border: none; font-family: monospace; cursor: pointer; font-weight: bold; font-size: 0.85rem;"
              >
                [ UPDATE ]
              </button>
            </form>
          </div>

          <div style="display: inline-block; border: 2px solid #00ff00;">
            <.live_component
              module={TerminalComponent}
              id="demo-terminal"
              buffer={@buffer}
              theme={@current_theme}
              width={80}
              height={24}
              crt_mode={@crt_mode}
              high_contrast={@high_contrast}
              aria_label="Demo terminal showing RaxolWeb component"
              on_keypress="terminal_key"
              on_cell_click="terminal_click"
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("change_theme", %{"theme" => theme}, socket) do
    theme_atom = String.to_existing_atom(theme)
    log_msg = "[#{timestamp()}] Theme changed to: #{theme}"

    {:noreply,
     socket
     |> assign(:current_theme, theme_atom)
     |> update(:log_messages, &(&1 ++ [log_msg]))}
  end

  def handle_event("toggle_crt", _params, socket) do
    new_mode = !socket.assigns.crt_mode
    log_msg = "[#{timestamp()}] CRT mode: #{new_mode}"

    {:noreply,
     socket
     |> assign(:crt_mode, new_mode)
     |> update(:log_messages, &(&1 ++ [log_msg]))}
  end

  def handle_event("toggle_high_contrast", _params, socket) do
    new_mode = !socket.assigns.high_contrast
    log_msg = "[#{timestamp()}] High contrast mode: #{new_mode}"

    {:noreply,
     socket
     |> assign(:high_contrast, new_mode)
     |> update(:log_messages, &(&1 ++ [log_msg]))}
  end

  def handle_event("update_buffer", _params, socket) do
    # Generate a new random buffer to demonstrate rendering updates
    new_buffer = create_animated_buffer()
    log_msg = "[#{timestamp()}] Buffer updated with new content"

    {:noreply,
     socket
     |> assign(:buffer, new_buffer)
     |> update(:log_messages, &(&1 ++ [log_msg]))}
  end

  def handle_event("terminal_key", %{"key" => key}, socket) do
    log_msg = "[#{timestamp()}] Key pressed: #{key}"
    {:noreply, update(socket, :log_messages, &(&1 ++ [log_msg]))}
  end

  def handle_event("terminal_click", %{"row" => row, "col" => col}, socket) do
    log_msg = "[#{timestamp()}] Cell clicked: row=#{row}, col=#{col}"
    {:noreply, update(socket, :log_messages, &(&1 ++ [log_msg]))}
  end

  # Helpers

  defp create_demo_buffer do
    lines = [
      create_line(
        "╔════════════════════════════════════════════════════════════════════════════╗"
      ),
      create_line("║                                                                          ║"),
      create_line("║                     RAXOL WEB TERMINAL COMPONENT DEMO                    ║"),
      create_line("║                                                                          ║"),
      create_line(
        "╠════════════════════════════════════════════════════════════════════════════╣"
      ),
      create_line("║                                                                          ║"),
      create_line("║  This is a demonstration of the RaxolWeb.LiveView.TerminalComponent      ║"),
      create_line("║                                                                          ║"),
      create_styled_line(
        "║  Features: ══════════════════════════════════════╣",
        :green,
        true
      ),
      create_line("║    • Virtual DOM diffing for optimal performance                         ║"),
      create_line("║    • Smart caching system                                                ║"),
      create_line("║    • 7 built-in themes                                                   ║"),
      create_line("║    • Character-perfect grid alignment                                    ║"),
      create_line("║    • Keyboard and mouse events                                           ║"),
      create_line("║                                                                          ║"),
      create_styled_line("║  Try it out:  ════════════════════════════════════╣", :yellow, true),
      create_line("║    • Change themes using the dropdown above                              ║"),
      create_line("║    • Toggle CRT mode for retro effects                                   ║"),
      create_line("║    • Press keys or click cells to see event handling                     ║"),
      create_line("║                                                                          ║"),
      create_line(
        "╠════════════════════════════════════════════════════════════════════════════╣"
      ),
      create_styled_line(
        "║  Status: Ready ════════════════════════════════════════════════════════════╣",
        :cyan,
        false
      ),
      create_line("║                                                                          ║"),
      create_line(
        "╚════════════════════════════════════════════════════════════════════════════╝"
      )
    ]

    %{lines: lines, width: 80, height: 24}
  end

  defp create_animated_buffer do
    import Enum, only: [random: 1]

    colors = [:red, :green, :yellow, :blue, :magenta, :cyan]
    color = random(colors)

    lines = [
      create_line(
        "╔════════════════════════════════════════════════════════════════════════════╗"
      ),
      create_line(
        "║                                                                            ║"
      ),
      create_styled_line(
        "║                     [ BUFFER UPDATED ]                                     ║",
        color,
        true
      ),
      create_line(
        "║                                                                            ║"
      ),
      create_line(
        "╠════════════════════════════════════════════════════════════════════════════╣"
      ),
      create_line(
        "║                                                                            ║"
      ),
      create_styled_line(
        "║  The buffer content has been dynamically updated!                         ║",
        color,
        false
      ),
      create_line(
        "║                                                                            ║"
      ),
      create_line(
        "║  This demonstrates:                                                        ║"
      ),
      create_line(
        "║    • Virtual DOM diffing detecting changes                                 ║"
      ),
      create_line(
        "║    • Only modified lines are re-rendered                                   ║"
      ),
      create_line(
        "║    • Smooth 60fps rendering capability                                     ║"
      ),
      create_line(
        "║                                                                            ║"
      ),
      create_line(
        "║  Click 'Update Buffer' again to see another update                         ║"
      ),
      create_line(
        "║                                                                            ║"
      )
      | List.duplicate(
          create_line(
            "║                                                                            ║"
          ),
          9
        ) ++
          [
            create_line(
              "╚════════════════════════════════════════════════════════════════════════════╝"
            )
          ]
    ]

    %{lines: lines, width: 80, height: 24}
  end

  defp create_line(text) do
    cells =
      String.graphemes(text)
      |> Enum.map(fn char ->
        %{
          char: char,
          style: %{
            bold: false,
            italic: false,
            underline: false,
            reverse: false,
            fg_color: nil,
            bg_color: nil
          }
        }
      end)

    # Pad to 80 chars
    cells = cells ++ List.duplicate(%{char: " ", style: %{}}, max(0, 80 - length(cells)))

    %{cells: Enum.take(cells, 80)}
  end

  defp create_styled_line(text, color, bold) do
    cells =
      String.graphemes(text)
      |> Enum.map(fn char ->
        %{
          char: char,
          style: %{
            bold: bold,
            italic: false,
            underline: false,
            reverse: false,
            fg_color: color,
            bg_color: nil
          }
        }
      end)

    # Pad to 80 chars
    cells = cells ++ List.duplicate(%{char: " ", style: %{}}, max(0, 80 - length(cells)))

    %{cells: Enum.take(cells, 80)}
  end

  defp timestamp do
    DateTime.utc_now() |> DateTime.to_time() |> Time.to_string() |> String.slice(0, 8)
  end

  defp buffer_format_example do
    """
    %{
      lines: [
        %{
          cells: [
            %{char: "H", style: %{fg_color: :green, bold: true}},
            %{char: "i", style: %{}}
          ]
        }
      ],
      width: 80,
      height: 24
    }
    """
  end
end
