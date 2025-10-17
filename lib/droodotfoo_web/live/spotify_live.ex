defmodule DroodotfooWeb.SpotifyLive do
  @moduledoc """
  LiveView for Spotify music player using Astro components.
  """

  use DroodotfooWeb, :live_view

  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Spotify Player")
     |> assign(:current_track, nil)
     |> assign(:is_playing, false)
     |> assign(:volume, 50)
     |> assign(:position, 0)
     |> assign(:duration, 0)
     |> assign(:playlist, nil)
     |> assign(:is_authenticated, false)
     |> assign(:error, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="spotify-page">
      <div class="spotify-container">
        <!-- Astro Spotify Widget Component -->
        <div
          id="astro-spotify-widget"
          phx-hook="AstroSpotifyWidgetHook"
          data-component-id="spotify-widget"
          class="spotify-widget-wrapper"
        >
          <!-- Astro component will be injected here -->
        </div>
        
    <!-- Control Panel -->
        <div class="spotify-controls">
          <div class="control-group">
            <h3>Playlist Controls</h3>
            <input
              type="text"
              id="playlist-id"
              placeholder="Enter playlist ID"
              phx-keydown="load_playlist"
              phx-key="Enter"
            />
            <button phx-click="load_playlist" phx-value-id="">Load Playlist</button>
          </div>

          <div class="control-group">
            <h3>Player Controls</h3>
            <button phx-click="play_pause">
              {if @is_playing, do: "Pause", else: "Play"}
            </button>
            <button phx-click="next_track">Next</button>
            <button phx-click="previous_track">Previous</button>
            <button phx-click="reset_volume">Reset Volume</button>
          </div>

          <div class="control-group">
            <h3>Authentication</h3>
            <%= if @is_authenticated do %>
              <button phx-click="logout">Logout</button>
            <% else %>
              <button phx-click="authenticate">Login to Spotify</button>
            <% end %>
          </div>
        </div>
        
    <!-- Current Track Information -->
        <%= if @current_track do %>
          <div class="track-info">
            <h3>Now Playing</h3>
            <div class="track-details">
              <div class="track-name">{@current_track.name}</div>
              <div class="artist-name">{@current_track.artists}</div>
              <div class="album-name">{@current_track.album}</div>
            </div>
          </div>
        <% end %>
        
    <!-- Error Display -->
        <%= if @error do %>
          <div class="error-message">
            <h3>Error</h3>
            <p>{@error}</p>
          </div>
        <% end %>
        
    <!-- Keyboard Controls Help -->
        <div class="keyboard-help">
          <h3>Keyboard Controls</h3>
          <ul>
            <li><kbd>Space</kbd> - Play/Pause</li>
            <li><kbd>→</kbd> - Next track</li>
            <li><kbd>←</kbd> - Previous track</li>
            <li><kbd>↑</kbd> - Volume up</li>
            <li><kbd>↓</kbd> - Volume down</li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("play_pause", _params, socket) do
    push_event(socket, "spotify_command", %{
      command: %{type: if(socket.assigns.is_playing, do: "pause", else: "play")}
    })

    {:noreply, assign(socket, :is_playing, !socket.assigns.is_playing)}
  end

  def handle_event("next_track", _params, socket) do
    push_event(socket, "spotify_command", %{
      command: %{type: "next"}
    })

    {:noreply, socket}
  end

  def handle_event("previous_track", _params, socket) do
    push_event(socket, "spotify_command", %{
      command: %{type: "previous"}
    })

    {:noreply, socket}
  end

  def handle_event("load_playlist", %{"id" => playlist_id}, socket) do
    if playlist_id != "" do
      push_event(socket, "spotify_command", %{
        command: %{type: "load_playlist", playlistId: playlist_id}
      })

      {:noreply, assign(socket, :playlist, playlist_id)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("load_playlist", _params, socket) do
    # Get playlist ID from input field
    playlist_id =
      case JS.exec("document.getElementById('playlist-id').value") do
        "" -> nil
        id -> id
      end

    if playlist_id do
      push_event(socket, "spotify_command", %{
        command: %{type: "load_playlist", playlistId: playlist_id}
      })

      {:noreply, assign(socket, :playlist, playlist_id)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("reset_volume", _params, socket) do
    push_event(socket, "spotify_command", %{
      command: %{type: "volume", level: 50}
    })

    {:noreply, assign(socket, :volume, 50)}
  end

  def handle_event("authenticate", _params, socket) do
    push_event(socket, "spotify_auth", %{
      action: "authenticate"
    })

    {:noreply, socket}
  end

  def handle_event("logout", _params, socket) do
    push_event(socket, "spotify_auth", %{
      action: "logout"
    })

    {:noreply,
     socket
     |> assign(:is_authenticated, false)
     |> assign(:current_track, nil)
     |> assign(:is_playing, false)}
  end

  # Handle events from Astro component
  def handle_event("track_changed", %{"track" => track}, socket) do
    {:noreply,
     socket
     |> assign(:current_track, track)
     |> assign(:is_authenticated, true)}
  end

  def handle_event("state_changed", %{"state" => state}, socket) do
    {:noreply,
     socket
     |> assign(:is_playing, !state.paused)
     |> assign(:position, state.position)
     |> assign(:duration, state.duration)}
  end

  def handle_event("spotify_error", %{"error" => error}, socket) do
    {:noreply, put_flash(socket, :error, "Spotify error: #{error}")}
  end
end
