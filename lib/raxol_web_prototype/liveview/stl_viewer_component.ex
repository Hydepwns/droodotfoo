defmodule RaxolWeb.LiveView.STLViewerComponent do
  @moduledoc """
  A Phoenix LiveView component for rendering 3D STL models with terminal-style HUD.

  This component provides high-performance 3D model rendering using Three.js
  with a Raxol-rendered text overlay for controls and model information.

  ## Features

  - Three.js-based 3D rendering (solid, wireframe, points modes)
  - Terminal-style HUD overlay using RaxolWeb.Renderer
  - Keyboard controls (j/k rotate, h/l zoom, r reset, m mode, q quit)
  - Model information display (triangles, vertices, bounds)
  - Smart caching and virtual DOM diffing for HUD updates
  - Character-perfect monospace grid alignment

  ## Basic Usage

      <.live_component
        module={RaxolWeb.LiveView.STLViewerComponent}
        id="stl-viewer"
        model_url="/models/cube.stl"
      />

  ## Full Example

      <.live_component
        module={RaxolWeb.LiveView.STLViewerComponent}
        id="stl-viewer"
        model_url={@model_url}
        width={65}
        height={18}
        theme={:synthwave84}
        on_command="handle_stl_command"
        on_quit="handle_stl_quit"
      />

      # In your LiveView
      def handle_event("handle_stl_command", %{"command" => cmd}, socket) do
        # Process STL viewer commands (rotate, zoom, mode, etc.)
        {:noreply, socket}
      end

      def handle_event("handle_stl_quit", _params, socket) do
        # Handle viewer quit
        {:noreply, socket}
      end

  ## State

  The component manages:
  - Model loading state
  - Render mode (:solid, :wireframe, :points)
  - Model info (triangles, vertices, bounds)
  - Error messages
  """

  use Phoenix.LiveComponent
  alias RaxolWeb.Renderer
  alias Droodotfoo.StlViewerState

  @impl true
  def mount(socket) do
    renderer = Renderer.new()

    {:ok,
     socket
     |> assign(:renderer, renderer)
     |> assign(:viewer_state, StlViewerState.new())}
  end

  @impl true
  def update(assigns, socket) do
    # Extract configuration
    width = Map.get(assigns, :width, 65)
    height = Map.get(assigns, :height, 18)
    theme = Map.get(assigns, :theme, :synthwave84)
    model_url = Map.get(assigns, :model_url)

    # Update viewer state if model_url changed
    viewer_state =
      if model_url && model_url != socket.assigns[:current_model_url] do
        StlViewerState.load_model(socket.assigns.viewer_state, model_url)
      else
        socket.assigns.viewer_state
      end

    # Build HUD buffer
    buffer = build_hud_buffer(viewer_state, width, height)

    # Render buffer to HTML
    {html, new_renderer} = Renderer.render(socket.assigns.renderer, buffer)

    {:ok,
     socket
     |> assign(:id, assigns.id)
     |> assign(:viewer_state, viewer_state)
     |> assign(:terminal_html, html)
     |> assign(:renderer, new_renderer)
     |> assign(:width, width)
     |> assign(:height, height)
     |> assign(:theme, theme)
     |> assign(:current_model_url, model_url)
     |> assign(:on_command, Map.get(assigns, :on_command))
     |> assign(:on_quit, Map.get(assigns, :on_quit))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={"stl-viewer-wrapper-#{@id}"}
      class="stl-viewer-wrapper"
      phx-hook="STLViewerHook"
      phx-window-keydown="keypress"
      phx-target={@myself}
      tabindex="0"
      role="application"
      aria-label="3D Model Viewer"
    >
      <style>
        .stl-viewer-wrapper {
          position: relative;
          font-family: 'Monaspace Argon', 'JetBrains Mono', monospace;
          font-size: 14px;
          line-height: 1.2;
        }

        .stl-viewer-wrapper .raxol-terminal {
          position: relative;
          z-index: 1;
        }

        .stl-viewer-wrapper .raxol-line {
          display: block;
          white-space: pre;
          height: 1.2em;
        }

        .stl-viewer-wrapper .raxol-cell {
          display: inline;
          width: 1ch;
        }

        #stl-canvas-container-<%= @id %> {
          position: absolute;
          z-index: 2;
          pointer-events: all;
        }

        .raxol-bold {
          font-weight: bold;
        }

        .raxol-fg-green {
          color: #00ffaa;
        }

        .raxol-fg-cyan {
          color: #00d9ff;
        }

        .raxol-fg-yellow {
          color: #ffd700;
        }

        .raxol-fg-red {
          color: #ff3366;
        }
      </style>

      <!-- HUD Overlay (Raxol-rendered) -->
      <%= Phoenix.HTML.raw(@terminal_html) %>

      <!-- 3D Canvas Container (positioned by hook) -->
      <div id={"stl-canvas-container-#{@id}"}></div>
    </div>
    """
  end

  @impl true
  def handle_event("keypress", %{"key" => key}, socket) do
    viewer_state = socket.assigns.viewer_state

    {new_state, command} =
      case key do
        "j" ->
          {viewer_state, {:rotate, :y, 0.1}}

        "k" ->
          {viewer_state, {:rotate, :y, -0.1}}

        "h" ->
          {viewer_state, {:zoom, -0.5}}

        "l" ->
          {viewer_state, {:zoom, 0.5}}

        "r" ->
          {StlViewerState.reset_camera(viewer_state), :reset}

        "m" ->
          new_mode =
            case viewer_state.render_mode do
              :solid -> :wireframe
              :wireframe -> :points
              :points -> :solid
            end

          {StlViewerState.set_render_mode(viewer_state, new_mode), {:mode, new_mode}}

        "q" ->
          if socket.assigns.on_quit do
            send(self(), {:stl_viewer_quit, socket.assigns.id})
          end

          {viewer_state, :quit}

        _ ->
          {viewer_state, nil}
      end

    socket =
      if command do
        # Send command to JavaScript hook
        socket
        |> push_event("stl_command", %{command: format_command(command)})
        |> assign(:viewer_state, new_state)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("model_loaded", %{"triangles" => triangles, "vertices" => vertices, "bounds" => bounds}, socket) do
    model_info = %{
      triangles: triangles,
      vertices: vertices,
      bounds: %{
        width: bounds["width"],
        height: bounds["height"],
        depth: bounds["depth"]
      }
    }

    new_state = StlViewerState.set_model_info(socket.assigns.viewer_state, model_info)

    {:noreply, assign(socket, :viewer_state, new_state)}
  end

  def handle_event("model_error", %{"error" => error}, socket) do
    new_state = StlViewerState.set_error(socket.assigns.viewer_state, error)

    {:noreply, assign(socket, :viewer_state, new_state)}
  end

  # Private Functions

  defp build_hud_buffer(viewer_state, width, height) do
    status = StlViewerState.status_message(viewer_state)
    info_lines = StlViewerState.format_model_info(viewer_state)

    # Build HUD lines
    hud_lines = [
      build_border_line("┌─ STL Viewer ", "─", "┐", width),
      build_padded_line("", width),
      build_padded_line("  #{status}", width)
    ] ++
    Enum.map(info_lines, fn line -> build_padded_line("  #{line}", width) end) ++
    [
      build_padded_line("", width),
      build_padded_line("  Controls: j/k rotate • h/l zoom • r reset • m mode • q quit", width),
      build_padded_line("", width),
      build_padded_line("  ┌─ 3D Viewport ────────────────────────────────────────────┐", width),
      build_padded_line("  │                                                          │", width),
      build_padded_line("  │                                                          │", width),
      build_padded_line("  │                                                          │", width),
      build_padded_line("  │                   [DROO.FOO]                             │", width),
      build_padded_line("  │                                                          │", width),
      build_padded_line("  │                                                          │", width),
      build_padded_line("  │                                                          │", width),
      build_padded_line("  └──────────────────────────────────────────────────────────┘", width),
      build_padded_line("", width),
      build_border_line("└", "─", "┘", width)
    ]

    # Pad to full height
    lines =
      if length(hud_lines) < height do
        hud_lines ++ List.duplicate(build_empty_line(width), height - length(hud_lines))
      else
        Enum.take(hud_lines, height)
      end

    %{
      lines: lines,
      width: width,
      height: height
    }
  end

  defp build_border_line(left, fill, right, width) do
    fill_count = width - String.length(left) - String.length(right)
    content = left <> String.duplicate(fill, fill_count) <> right

    %{cells: string_to_cells(content)}
  end

  defp build_padded_line(content, width) do
    padded = String.pad_trailing(content, width - 2)
    line = "│" <> padded <> "│"

    %{cells: string_to_cells(line)}
  end

  defp build_empty_line(width) do
    %{cells: string_to_cells(String.duplicate(" ", width))}
  end

  defp string_to_cells(string) do
    string
    |> String.graphemes()
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
  end

  defp format_command({:rotate, axis, angle}) do
    %{type: "rotate", axis: Atom.to_string(axis), angle: angle}
  end

  defp format_command({:zoom, distance}) do
    %{type: "zoom", distance: distance}
  end

  defp format_command(:reset) do
    %{type: "reset"}
  end

  defp format_command({:mode, mode}) do
    %{type: "mode", mode: Atom.to_string(mode)}
  end

  defp format_command(:quit) do
    %{type: "quit"}
  end

  defp format_command(_), do: %{type: "unknown"}
end
