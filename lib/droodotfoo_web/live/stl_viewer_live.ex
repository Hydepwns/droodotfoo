defmodule DroodotfooWeb.STLViewerLive do
  @moduledoc """
  LiveView for STL 3D model viewer using Astro components.
  """

  use DroodotfooWeb, :live_view

  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "STL 3D Viewer")
     |> assign(:current_model, nil)
     |> assign(:model_info, nil)
     |> assign(:render_mode, "solid")
     |> assign(:auto_rotate, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="stl-viewer-page">
      <div class="stl-viewer-container">
        <!-- Astro STL Viewer Component -->
        <div
          id="astro-stl-viewer"
          phx-hook="AstroSTLViewerHook"
          data-component-id="stl-viewer"
          class="stl-viewer-wrapper"
        >
          <!-- Astro component will be injected here -->
        </div>
        
    <!-- Control Panel -->
        <div class="stl-controls">
          <div class="control-group">
            <label>Model URL:</label>
            <input
              type="text"
              id="model-url"
              placeholder="/models/cube.stl"
              phx-keydown="load_model"
              phx-key="Enter"
            />
            <button phx-click="load_model" phx-value-url="">Load Model</button>
          </div>

          <div class="control-group">
            <label>Render Mode:</label>
            <select phx-change="change_render_mode">
              <option value="solid" selected={@render_mode == "solid"}>Solid</option>
              <option value="wireframe" selected={@render_mode == "wireframe"}>Wireframe</option>
              <option value="points" selected={@render_mode == "points"}>Points</option>
            </select>
          </div>

          <div class="control-group">
            <button phx-click="reset_camera">Reset Camera</button>
            <button phx-click="cycle_mode">Cycle Mode</button>
            <button phx-click="toggle_rotate" phx-value-enabled={@auto_rotate}>
              {if @auto_rotate, do: "Stop Rotate", else: "Auto Rotate"}
            </button>
          </div>
        </div>
        
    <!-- Model Information -->
        <%= if @model_info do %>
          <div class="model-info">
            <h3>Model Information</h3>
            <p>Triangles: {@model_info.triangles}</p>
            <p>Vertices: {@model_info.vertices}</p>
            <p>
              Bounds: {@model_info.bounds.width} × {@model_info.bounds.height} × {@model_info.bounds.depth}
            </p>
          </div>
        <% end %>
        
    <!-- Keyboard Controls Help -->
        <div class="keyboard-help">
          <h3>Keyboard Controls</h3>
          <ul>
            <li><kbd>J/K</kbd> - Rotate up/down</li>
            <li><kbd>H/L</kbd> - Rotate left/right</li>
            <li><kbd>+/-</kbd> - Zoom in/out</li>
            <li><kbd>R</kbd> - Reset view</li>
            <li><kbd>M</kbd> - Cycle render modes</li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("load_model", %{"url" => url}, socket) do
    if url != "" do
      # Send command to Astro component
      push_event(socket, "stl_command", %{
        command: %{type: "load", url: url}
      })

      {:noreply, assign(socket, :current_model, url)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("load_model", _params, socket) do
    # Get URL from input field
    url =
      case JS.exec("document.getElementById('model-url').value") do
        "" -> "/models/cube.stl"
        input_url -> input_url
      end

    push_event(socket, "stl_command", %{
      command: %{type: "load", url: url}
    })

    {:noreply, assign(socket, :current_model, url)}
  end

  def handle_event("change_render_mode", %{"value" => mode}, socket) do
    push_event(socket, "stl_command", %{
      command: %{type: "mode", mode: mode}
    })

    {:noreply, assign(socket, :render_mode, mode)}
  end

  def handle_event("reset_camera", _params, socket) do
    push_event(socket, "stl_command", %{
      command: %{type: "reset"}
    })

    {:noreply, socket}
  end

  def handle_event("cycle_mode", _params, socket) do
    new_mode =
      case socket.assigns.render_mode do
        "solid" -> "wireframe"
        "wireframe" -> "points"
        "points" -> "solid"
        _ -> "solid"
      end

    push_event(socket, "stl_command", %{
      command: %{type: "mode", mode: new_mode}
    })

    {:noreply, assign(socket, :render_mode, new_mode)}
  end

  def handle_event("toggle_rotate", _params, socket) do
    new_rotate = !socket.assigns.auto_rotate

    push_event(socket, "stl_command", %{
      command: %{type: "rotate", enabled: new_rotate}
    })

    {:noreply, assign(socket, :auto_rotate, new_rotate)}
  end

  # Handle events from Astro component
  def handle_event("model_loaded", model_info, socket) do
    {:noreply, assign(socket, :model_info, model_info)}
  end

  def handle_event("model_error", %{"error" => error}, socket) do
    {:noreply, put_flash(socket, :error, "Model loading error: #{error}")}
  end
end
