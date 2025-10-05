defmodule DroodotfooWeb.STLViewerDemoLive do
  @moduledoc """
  Demo page for RaxolWeb.LiveView.STLViewerComponent

  Demonstrates the new Raxol-based STL viewer component with:
  - Buffer-based HUD rendering
  - RaxolWeb.Renderer optimizations
  - Three.js canvas overlay
  - Keyboard controls (j/k/h/l/r/m/q)
  """

  use DroodotfooWeb, :live_view
  alias RaxolWeb.LiveView.STLViewerComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "STL Viewer Demo - RaxolWeb")
     |> assign(:model_url, "/models/cube.stl")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="stl-viewer-demo">
      <style>
        .stl-viewer-demo {
          min-height: 100vh;
          background: #1a1a2e;
          color: #eee;
          padding: 2rem;
          font-family: 'Monaspace Argon', monospace;
        }

        .stl-viewer-demo h1 {
          font-size: 2rem;
          margin-bottom: 0.5rem;
          color: #00d9ff;
        }

        .stl-viewer-demo p {
          margin-bottom: 1.5rem;
          color: #aaa;
        }

        .demo-controls {
          margin-top: 2rem;
          padding: 1rem;
          background: #16213e;
          border: 1px solid #00d9ff;
          border-radius: 4px;
        }

        .demo-controls h2 {
          font-size: 1.2rem;
          margin-bottom: 0.5rem;
          color: #00ffaa;
        }

        .demo-controls code {
          background: #0f3460;
          padding: 0.2rem 0.4rem;
          border-radius: 2px;
          color: #ffd700;
        }
      </style>

      <h1>RaxolWeb STL Viewer Component</h1>
      <p>3D model viewer with terminal-style HUD, powered by RaxolWeb.Renderer</p>

      <.live_component
        module={STLViewerComponent}
        id="demo-viewer"
        model_url={@model_url}
        width={65}
        height={18}
        theme={:synthwave84}
      />

      <div class="demo-controls">
        <h2>Features</h2>
        <ul>
          <li><code>RaxolWeb.Renderer</code> - Smart caching and virtual DOM diffing for HUD</li>
          <li><code>Three.js</code> - Hardware-accelerated 3D rendering</li>
          <li><code>Phoenix LiveView</code> - Real-time state synchronization</li>
          <li>Character-perfect monospace grid alignment</li>
        </ul>

        <h2 style="margin-top: 1rem;">Keyboard Controls</h2>
        <ul>
          <li><code>j/k</code> - Rotate model</li>
          <li><code>h/l</code> - Zoom in/out</li>
          <li><code>r</code> - Reset camera</li>
          <li><code>m</code> - Cycle render mode (solid/wireframe/points)</li>
          <li><code>q</code> - Quit viewer</li>
        </ul>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("handle_stl_command", %{"command" => command}, socket) do
    # Commands are handled by the component
    # This would be where you'd process commands if needed by parent
    IO.inspect(command, label: "STL Command")
    {:noreply, socket}
  end

  def handle_event("handle_stl_quit", _params, socket) do
    # Handle quit - for demo, just log it
    IO.puts("STL Viewer quit requested")
    {:noreply, socket}
  end

  @impl true
  def handle_info({:stl_viewer_quit, _viewer_id}, socket) do
    # Handle quit message from component
    IO.puts("STL Viewer closed")
    {:noreply, socket}
  end
end
