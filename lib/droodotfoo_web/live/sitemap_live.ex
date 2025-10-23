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
    <.page_layout page_title="Sitemap" page_description="Visual map of all pages on droo.foo" current_path={@current_path}>
      <section class="about-section">
        <p class="mb-2">
          Complete site structure for quick navigation. Click any link to jump to that page.
        </p>

        <ul class="tree">
          <li>
            <strong>droo.foo</strong>
            <ul>
              <li><a href="/">Home</a></li>
              <li><a href="/about">About</a></li>
              <li><a href="/now">Now</a></li>
              <li><a href="/projects">Projects</a></li>
              <li>
                <a href="/posts">Writing</a>
                <span class="text-muted"> ({length(@posts)} posts)</span>
              </li>
              <li><a href="/sitemap">Sitemap</a></li>
            </ul>
          </li>
        </ul>

        <%= if length(@posts) > 0 do %>
          <details class="mt-2">
            <summary style="cursor: pointer; user-select: none;">
              <strong>All Posts</strong> ({length(@posts)})
            </summary>
            <ul class="mt-1" style="list-style: none; padding-left: 0;">
              <%= for post <- @posts do %>
                <li style="padding-left: 2ch; margin-bottom: 0.25rem;">
                  <a href={"/posts/#{post.slug}"}>{post.title}</a>
                  <span class="text-muted"> - {Date.to_string(post.date)}</span>
                </li>
              <% end %>
            </ul>
          </details>
        <% end %>

        <hr class="section-divider" />

        <h3>Feeds & Meta</h3>
        <ul>
          <li>
            <a href="/feed.xml">RSS Feed</a> - Subscribe to blog updates
          </li>
          <li>
            <a href="/sitemap.xml">XML Sitemap</a> - For search engines
          </li>
        </ul>
      </section>
    </.page_layout>
    """
  end
end
