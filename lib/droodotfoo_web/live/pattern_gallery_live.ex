defmodule DroodotfooWeb.PatternGalleryLive do
  @moduledoc """
  LiveView for displaying a gallery of all available pattern styles.
  Useful for previewing and selecting pattern styles for blog posts.
  """

  use DroodotfooWeb, :live_view
  import DroodotfooWeb.ContentComponents

  @pattern_styles [
    %{name: "waves", description: "Flowing sine waves - organic and smooth"},
    %{name: "noise", description: "TV static effect - digital noise"},
    %{name: "lines", description: "Parallel or radial lines - clean and minimal"},
    %{name: "dots", description: "Halftone dot matrix - classic print aesthetic"},
    %{name: "circuit", description: "Circuit board traces - technical look"},
    %{name: "glitch", description: "Corrupted data effect - digital artifact"},
    %{name: "geometric", description: "Classic shapes - timeless design"},
    %{name: "grid", description: "Cellular pattern - mathematical rhythm"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Pattern Gallery")
     |> assign(:current_path, "/pattern-gallery")
     |> assign(:slug, "example-post")
     |> assign(:animate, true)
     |> assign(:pattern_styles, @pattern_styles)}
  end

  @impl true
  def handle_event("update_slug", %{"slug" => slug}, socket) do
    {:noreply, assign(socket, :slug, slug)}
  end

  @impl true
  def handle_event("toggle_animate", _params, socket) do
    {:noreply, assign(socket, :animate, !socket.assigns.animate)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout page_title="Pattern Gallery" current_path={@current_path}>
      <div class="pattern-gallery-container">
        <div class="gallery-controls">
          <div style="margin-bottom: 1rem;">
            <label for="slug-input" class="form-label">
              Test Slug (change to see different patterns):
            </label>
            <input
              type="text"
              id="slug-input"
              name="slug"
              value={@slug}
              phx-change="update_slug"
              class="form-input"
              placeholder="example-post"
              style="max-width: 300px;"
            />
            <p class="text-muted" style="margin-top: 0.5rem;">
              Each slug generates unique variations of each pattern style
            </p>
          </div>

          <div>
            <label style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer;">
              <input
                type="checkbox"
                checked={@animate}
                phx-click="toggle_animate"
                style="cursor: pointer;"
              />
              <span>Enable animations</span>
            </label>
          </div>
        </div>

        <div class="pattern-grid">
          <%= for style <- @pattern_styles do %>
            <div class="pattern-card">
              <div class="pattern-preview">
                <img
                  src={"/patterns/#{@slug}?style=#{style.name}&animate=#{@animate}"}
                  alt={"#{style.name} pattern"}
                  loading="lazy"
                />
              </div>
              <div class="pattern-info">
                <h3 class="pattern-name">{String.upcase(style.name)}</h3>
                <p class="pattern-description">{style.description}</p>
                <code class="pattern-code">pattern_style: {style.name}</code>
              </div>
            </div>
          <% end %>
        </div>

        <div class="gallery-usage">
          <h2>How to Use</h2>
          <p>Add any of these pattern styles to your post frontmatter:</p>
          <pre><code>---
title: "My Post"
pattern_style: waves
---</code></pre>
          <p>Or let the system auto-select a pattern based on your post slug (deterministic).</p>
        </div>
      </div>
    </.page_layout>
    """
  end
end
