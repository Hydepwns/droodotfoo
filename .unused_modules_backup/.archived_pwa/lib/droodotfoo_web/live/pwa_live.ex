defmodule DroodotfooWeb.PWALive do
  @moduledoc """
  LiveView for PWA functionality using Astro components.
  """

  use DroodotfooWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "PWA Manager")
     |> assign(:is_installed, false)
     |> assign(:can_install, false)
     |> assign(:has_service_worker, false)
     |> assign(:has_update, false)
     |> assign(:error, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pwa-page">
      <div class="pwa-container">
        <!-- Astro PWA Install Component -->
        <div
          id="astro-pwa-install"
          phx-hook="AstroPWAHook"
          data-component-id="pwa-install"
          class="pwa-widget-wrapper"
        >
          <!-- Astro component will be injected here -->
        </div>
        
    <!-- PWA Status Dashboard -->
        <div class="pwa-dashboard">
          <h2>PWA Status</h2>

          <div class="pwa-status-grid">
            <div class="pwa-status-item">
              <span class="pwa-status-label">Installed:</span>
              <span class={"pwa-status-value #{if @is_installed, do: "status-true", else: "status-false"}"}>
                {if @is_installed, do: "Yes", else: "No"}
              </span>
            </div>

            <div class="pwa-status-item">
              <span class="pwa-status-label">Can Install:</span>
              <span class={"pwa-status-value #{if @can_install, do: "status-true", else: "status-false"}"}>
                {if @can_install, do: "Yes", else: "No"}
              </span>
            </div>

            <div class="pwa-status-item">
              <span class="pwa-status-label">Service Worker:</span>
              <span class={"pwa-status-value #{if @has_service_worker, do: "status-true", else: "status-false"}"}>
                {if @has_service_worker, do: "Active", else: "Inactive"}
              </span>
            </div>

            <div class="pwa-status-item">
              <span class="pwa-status-label">Update Available:</span>
              <span class={"pwa-status-value #{if @has_update, do: "status-warning", else: "status-false"}"}>
                {if @has_update, do: "Yes", else: "No"}
              </span>
            </div>
          </div>
        </div>
        
    <!-- PWA Controls -->
        <div class="pwa-controls">
          <h3>PWA Controls</h3>

          <div class="pwa-control-group">
            <button
              phx-click="install_pwa"
              disabled={!@can_install}
              class="pwa-control-btn"
            >
              Install App
            </button>

            <button
              phx-click="update_pwa"
              disabled={!@has_update}
              class="pwa-control-btn"
            >
              Update App
            </button>

            <button
              phx-click="clear_cache"
              class="pwa-control-btn pwa-control-btn--danger"
            >
              Clear Cache
            </button>

            <button
              phx-click="refresh_status"
              class="pwa-control-btn"
            >
              Refresh Status
            </button>
          </div>
        </div>
        
    <!-- PWA Information -->
        <div class="pwa-info">
          <h3>PWA Information</h3>
          <div class="pwa-info-content">
            <p>
              Progressive Web Apps (PWAs) provide a native app-like experience
              in your browser. This page demonstrates PWA installation and
              management capabilities.
            </p>

            <h4>Features:</h4>
            <ul>
              <li>[+] Install as a native app</li>
              <li>[~] Automatic updates</li>
              <li>[*] Offline functionality</li>
              <li>[>] Fast loading</li>
              <li>[#] Background sync</li>
            </ul>

            <h4>Browser Support:</h4>
            <p>
              PWA features are supported in modern browsers including Chrome,
              Firefox, Safari, and Edge. Some features may vary by browser.
            </p>
          </div>
        </div>
        
    <!-- Error Display -->
        <%= if @error do %>
          <div class="pwa-error">
            <h3>Error</h3>
            <p>{@error}</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("install_pwa", _params, socket) do
    push_event(socket, "pwa_command", %{
      command: %{type: "install"}
    })

    {:noreply, socket}
  end

  def handle_event("update_pwa", _params, socket) do
    push_event(socket, "pwa_command", %{
      command: %{type: "update"}
    })

    {:noreply, assign(socket, :has_update, false)}
  end

  def handle_event("clear_cache", _params, socket) do
    push_event(socket, "pwa_command", %{
      command: %{type: "clear_cache"}
    })

    {:noreply, put_flash(socket, :info, "Cache cleared successfully")}
  end

  def handle_event("refresh_status", _params, socket) do
    push_event(socket, "pwa_command", %{
      command: %{type: "get_status"}
    })

    {:noreply, socket}
  end

  # Handle events from Astro component
  def handle_event("pwa_install_available", %{"canInstall" => can_install}, socket) do
    {:noreply, assign(socket, :can_install, can_install)}
  end

  def handle_event("pwa_installed", %{"isInstalled" => is_installed}, socket) do
    {:noreply,
     socket
     |> assign(:is_installed, is_installed)
     |> assign(:can_install, false)
     |> put_flash(:info, "App installed successfully!")}
  end

  def handle_event("pwa_update_available", %{"hasUpdate" => has_update}, socket) do
    {:noreply,
     socket
     |> assign(:has_update, has_update)
     |> put_flash(:info, "Update available! Click 'Update App' to install.")}
  end

  def handle_event("pwa_status_changed", status, socket) do
    {:noreply,
     socket
     |> assign(:is_installed, status["isInstalled"] || false)
     |> assign(:can_install, status["canInstall"] || false)
     |> assign(:has_service_worker, status["hasServiceWorker"] || false)}
  end

  def handle_event("pwa_error", %{"error" => error}, socket) do
    {:noreply,
     socket
     |> assign(:error, error)
     |> put_flash(:error, "PWA Error: #{error}")}
  end
end
