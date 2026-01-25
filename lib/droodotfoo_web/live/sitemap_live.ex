defmodule DroodotfooWeb.SitemapLive do
  @moduledoc """
  Visual sitemap page with tree structure for easy site navigation.
  Shows all pages in a hierarchical ASCII art tree.
  """

  use DroodotfooWeb, :live_view
  alias Droodotfoo.Content.Posts
  import DroodotfooWeb.ContentComponents

  @impl true
  def mount(_params, _session, socket) do
    posts =
      try do
        Posts.list_posts()
      rescue
        _ -> []
      end

    socket
    |> assign(:posts, posts)
    |> assign(:page_title, "Sitemap")
    |> assign(:current_path, "/sitemap")
    |> then(&{:ok, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout
      page_title="Sitemap"
      page_description="Visual map of all pages on droo.foo"
      current_path={@current_path}
    >
      <section class="about-section">
        <p class="mb-2">
          Complete site structure for quick navigation. Click any link to jump to that page.
        </p>

        <div class="ascii-tree">
          <div><strong>droo.foo</strong></div>
          <div>├── <.link navigate={~p"/"}>Home</.link></div>
          <div>├── <.link navigate={~p"/about"}>About</.link></div>
          <div>├── <.link navigate={~p"/now"}>Now</.link></div>
          <div>├── <.link navigate={~p"/projects"}>Projects</.link></div>
          <div>
            ├── <.link navigate={~p"/posts"}>Writing</.link>
            <span class="text-muted">({length(@posts)} posts)</span>
          </div>
          <div>├── <.link navigate={~p"/pattern-gallery"}>Pattern Gallery</.link></div>
          <div>└── <.link navigate={~p"/sitemap"}>Sitemap</.link></div>
        </div>

        <%= if length(@posts) > 0 do %>
          <details class="mt-2">
            <summary style="cursor: pointer; user-select: none;">
              <strong>All Posts</strong> ({length(@posts)})
            </summary>
            <div class="ascii-tree mt-1">
              <%= for {post, idx} <- Enum.with_index(@posts, 1) do %>
                <div>
                  {if idx == length(@posts), do: "└── ", else: "├── "}<.link navigate={
                    ~p"/posts/#{post.slug}"
                  }>{post.title}</.link>
                  <span class="text-muted">- {Date.to_string(post.date)}</span>
                </div>
              <% end %>
            </div>
          </details>
        <% end %>

        <hr />

        <h3>Feeds & Meta</h3>
        <div class="ascii-tree">
          <div>
            ├── <a href="/feed.xml">RSS Feed</a>
            <span class="text-muted">- Subscribe to blog updates</span>
          </div>
          <div>
            ├── <a href="/sitemap.xml">XML Sitemap</a>
            <span class="text-muted">- For search engines</span>
          </div>
          <div>
            └── <a href="/llms.txt">LLMs.txt</a>
            <span class="text-muted">- Structured content for language models</span>
          </div>
        </div>
      </section>
    </.page_layout>
    """
  end
end
