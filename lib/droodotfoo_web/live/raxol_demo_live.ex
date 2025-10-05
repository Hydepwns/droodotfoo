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
    <div class="raxol-demo-container" style="padding: 2rem; max-width: 1200px; margin: 0 auto;">
      <h1 style="font-family: monospace; font-size: 2rem; margin-bottom: 1rem;">
        RaxolWeb Terminal Component Demo
      </h1>

      <p style="margin-bottom: 2rem; color: #666;">
        This demonstrates the extracted terminal rendering components that will be
        contributed to the Raxol framework for web-based terminal UIs.
      </p>

      <!-- Controls -->
      <div style="margin-bottom: 2rem; display: flex; gap: 1rem; flex-wrap: wrap;">
        <div>
          <label style="display: block; margin-bottom: 0.5rem;">Theme:</label>
          <select phx-change="change_theme" name="theme" style="padding: 0.5rem; font-family: monospace;">
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
        </div>

        <div>
          <label style="display: block; margin-bottom: 0.5rem;">
            <input type="checkbox" phx-click="toggle_crt" checked={@crt_mode} /> CRT Mode
          </label>
          <label style="display: block;">
            <input type="checkbox" phx-click="toggle_high_contrast" checked={@high_contrast} />
            High Contrast
          </label>
        </div>

        <div>
          <button phx-click="update_buffer" style="padding: 0.5rem 1rem; font-family: monospace;">
            Update Buffer
          </button>
        </div>
      </div>

      <!-- Terminal Component -->
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
      <!-- Event Log -->
      <div style="margin-top: 2rem;">
        <h3 style="font-family: monospace; margin-bottom: 0.5rem;">Event Log:</h3>
        <div
          style="background: #1a1a1a; color: #0f0; padding: 1rem; font-family: monospace; height: 150px; overflow-y: auto;"
          id="event-log"
        >
          <%= for msg <- Enum.take(@log_messages, -10) do %>
            <div><%= msg %></div>
          <% end %>
        </div>
      </div>

      <!-- Implementation Details -->
      <div style="margin-top: 3rem; padding: 1rem; background: #f5f5f5; border-radius: 4px;">
        <h3 style="margin-bottom: 1rem;">Implementation Details</h3>
        <p style="margin-bottom: 1rem;">
          This component is built from the proven TerminalBridge implementation in droodotfoo
          and extracted into reusable modules:
        </p>
        <ul style="list-style-position: inside; margin-left: 1rem;">
          <li><code>RaxolWeb.Renderer</code> - Core buffer-to-HTML rendering with caching and diffing</li>
          <li><code>RaxolWeb.Themes</code> - 7 built-in terminal color themes</li>
          <li>
            <code>RaxolWeb.LiveView.TerminalComponent</code>
            - Phoenix LiveComponent wrapper
          </li>
        </ul>

        <h4 style="margin-top: 1.5rem; margin-bottom: 0.5rem;">Features:</h4>
        <ul style="list-style-position: inside; margin-left: 1rem;">
          <li>Virtual DOM-style diffing for minimal updates</li>
          <li>Smart caching of common characters and styles</li>
          <li>Character-perfect 1ch monospace grid alignment</li>
          <li>Theme system with CSS generation</li>
          <li>Keyboard and mouse event handling</li>
          <li>CRT mode with scanline effects</li>
          <li>Accessibility features (ARIA, screen readers)</li>
        </ul>

        <h4 style="margin-top: 1.5rem; margin-bottom: 0.5rem;">Buffer Format:</h4>
        <pre style="background: #1a1a1a; color: #0f0; padding: 1rem; overflow-x: auto;"><code><%= buffer_format_example() %></code></pre>
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
      create_line("╔════════════════════════════════════════════════════════════════════════════╗"),
      create_line("║                                                                            ║"),
      create_line("║                     RAXOL WEB TERMINAL COMPONENT DEMO                      ║"),
      create_line("║                                                                            ║"),
      create_line("╠════════════════════════════════════════════════════════════════════════════╣"),
      create_line("║                                                                            ║"),
      create_line("║  This is a demonstration of the RaxolWeb.LiveView.TerminalComponent       ║"),
      create_line("║                                                                            ║"),
      create_styled_line("║  Features:", :green, true),
      create_line("║    • Virtual DOM diffing for optimal performance                          ║"),
      create_line("║    • Smart caching system                                                  ║"),
      create_line("║    • 7 built-in themes                                                     ║"),
      create_line("║    • Character-perfect grid alignment                                      ║"),
      create_line("║    • Keyboard and mouse events                                             ║"),
      create_line("║                                                                            ║"),
      create_styled_line("║  Try it out:", :yellow, true),
      create_line("║    • Change themes using the dropdown above                                ║"),
      create_line("║    • Toggle CRT mode for retro effects                                     ║"),
      create_line("║    • Press keys or click cells to see event handling                       ║"),
      create_line("║                                                                            ║"),
      create_line("╠════════════════════════════════════════════════════════════════════════════╣"),
      create_styled_line("║  Status: Ready                                                           ║", :cyan, false),
      create_line("║                                                                            ║"),
      create_line("╚════════════════════════════════════════════════════════════════════════════╝")
    ]

    %{lines: lines, width: 80, height: 24}
  end

  defp create_animated_buffer do
    import Enum, only: [random: 1]

    colors = [:red, :green, :yellow, :blue, :magenta, :cyan]
    color = random(colors)

    lines = [
      create_line("╔════════════════════════════════════════════════════════════════════════════╗"),
      create_line("║                                                                            ║"),
      create_styled_line("║                     [ BUFFER UPDATED ]                                     ║", color, true),
      create_line("║                                                                            ║"),
      create_line("╠════════════════════════════════════════════════════════════════════════════╣"),
      create_line("║                                                                            ║"),
      create_styled_line("║  The buffer content has been dynamically updated!                         ║", color, false),
      create_line("║                                                                            ║"),
      create_line("║  This demonstrates:                                                        ║"),
      create_line("║    • Virtual DOM diffing detecting changes                                 ║"),
      create_line("║    • Only modified lines are re-rendered                                   ║"),
      create_line("║    • Smooth 60fps rendering capability                                     ║"),
      create_line("║                                                                            ║"),
      create_line("║  Click 'Update Buffer' again to see another update                         ║"),
      create_line("║                                                                            ║")
      | List.duplicate(create_line("║                                                                            ║"), 9) ++
          [create_line("╚════════════════════════════════════════════════════════════════════════════╝")]
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
