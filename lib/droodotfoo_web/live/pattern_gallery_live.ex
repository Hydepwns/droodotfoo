defmodule DroodotfooWeb.PatternGalleryLive do
  @moduledoc """
  LiveView for displaying a gallery of all available pattern styles.
  Useful for previewing and selecting pattern styles for blog posts.
  """

  use DroodotfooWeb, :live_view
  import DroodotfooWeb.ContentComponents

  @pattern_styles [
    %{name: "waves", description: "Flowing sine waves"},
    %{name: "noise", description: "TV static noise"},
    %{name: "lines", description: "Parallel or radial lines"},
    %{name: "dots", description: "Halftone dot matrix"},
    %{name: "circuit", description: "Circuit board traces"},
    %{name: "glitch", description: "Corrupted data effect"},
    %{name: "geometric", description: "Circles, triangles, squares"},
    %{name: "grid", description: "Cellular grid pattern"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Pattern Gallery")
     |> assign(:current_path, "/pattern-gallery")
     |> assign(:slug, "example-post")
     # Disabled by default to reduce GPU load
     |> assign(:animate, false)
     # Track which pattern is being previewed
     |> assign(:preview_pattern, nil)
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
  def handle_event("preview_pattern", %{"style" => style}, socket) do
    {:noreply, assign(socket, :preview_pattern, style)}
  end

  @impl true
  def handle_event("close_preview", _params, socket) do
    {:noreply, assign(socket, :preview_pattern, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout
      page_title="Pattern Gallery"
      page_description="Browse and preview all SVG pattern styles used for social sharing images"
      current_path={@current_path}
    >
      <div class="pattern-gallery-container">
        <div class="gallery-controls">
          <div style="margin-bottom: 1rem;">
            <label for="slug-input" class="form-label">
              Preview Slug (generates unique variations):
            </label>
            <input
              type="text"
              id="slug-input"
              name="slug"
              value={@slug}
              phx-change="update_slug"
              phx-debounce="500"
              class="form-input"
              placeholder="my-blog-post-slug"
              style="max-width: 400px;"
            />
            <p class="text-muted" style="margin-top: 0.5rem;">
              Type any slug (e.g., "crypto", "elixir") to see variations. Same slug = same pattern (deterministic).
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
                <object
                  data={"/patterns/#{@slug}?style=#{style.name}&animate=#{@animate}"}
                  type="image/svg+xml"
                  aria-label={"#{style.name} pattern"}
                >
                  <img
                    src={"/patterns/#{@slug}?style=#{style.name}&animate=#{@animate}"}
                    alt={"#{style.name} pattern"}
                    loading="lazy"
                  />
                </object>
              </div>
              <div class="pattern-info">
                <h3 class="pattern-name">{String.upcase(style.name)}</h3>
                <p class="pattern-description">{style.description}</p>
                <code class="pattern-code">pattern_style: {style.name}</code>
                <button
                  phx-click="preview_pattern"
                  phx-value-style={style.name}
                  class="preview-button"
                >
                  Preview Animated
                </button>
              </div>
            </div>
          <% end %>
        </div>

        <%= if @preview_pattern do %>
          <div class="pattern-modal" phx-click="close_preview">
            <div class="pattern-modal-content" phx-click="close_preview">
              <button class="modal-close" phx-click="close_preview" aria-label="Close preview">
                ×
              </button>
              <div class="pattern-modal-header">
                <h2>{String.upcase(@preview_pattern)} Pattern</h2>
                <p class="text-muted">Animated preview</p>
              </div>
              <div class="pattern-modal-preview">
                <object
                  data={"/patterns/#{@slug}?style=#{@preview_pattern}&animate=true"}
                  type="image/svg+xml"
                  aria-label={"#{@preview_pattern} pattern animated"}
                >
                  <img
                    src={"/patterns/#{@slug}?style=#{@preview_pattern}&animate=true"}
                    alt={"#{@preview_pattern} pattern animated"}
                  />
                </object>
              </div>
            </div>
          </div>
        <% end %>

        <div class="gallery-usage">
          <h2>How to Use</h2>
          <p>Add a pattern style to your post frontmatter:</p>
          <pre><code>---
          title: "My Post"
          pattern_style: waves
          ---</code></pre>
          <p>Without a pattern_style, the system auto-selects based on post slug.</p>
        </div>
      </div>
    </.page_layout>
    """
  end
end
