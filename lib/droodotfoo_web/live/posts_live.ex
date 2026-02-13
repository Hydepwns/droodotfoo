defmodule DroodotfooWeb.PostsLive do
  @moduledoc """
  LiveView for listing all blog posts.
  """

  use DroodotfooWeb, :live_view
  alias Droodotfoo.Content.Posts
  alias DroodotfooWeb.SEO.JsonLD
  import DroodotfooWeb.ContentComponents

  @impl true
  def mount(_params, _session, socket) do
    posts = Posts.list_posts()

    # Generate JSON-LD schemas for posts listing
    json_ld = [
      JsonLD.breadcrumb_schema([
        {"Home", "/"},
        {"Writing", "/posts"}
      ])
    ]

    {:ok,
     socket
     |> assign(:posts, posts)
     |> assign(:page_title, "Writing")
     |> assign(:current_path, "/posts")
     |> assign(:json_ld, json_ld)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout
      page_title="Writing"
      page_description="Notes on building things"
      current_path={@current_path}
    >
      <%= if @posts == [] do %>
        <p class="text-muted">No posts yet.</p>
      <% else %>
        <div class="posts-list">
          <%= for post <- @posts do %>
            <article class="post-item-with-image">
              <div class="post-item-content">
                <h3 class="mb-0-5">
                  <.link navigate={~p"/posts/#{post.slug}"} class="link-reset">
                    {post.title}
                  </.link>
                </h3>
                <p class="text-muted-alt">
                  {Date.to_string(post.date)} · {post.read_time} min read
                </p>
                <%= if post.description do %>
                  <p>{post.description}</p>
                <% end %>
                <%= if post.tags != [] do %>
                  <div class="post-tags">
                    <%= for tag <- post.tags do %>
                      <span class="tech-tag">{tag}</span>
                    <% end %>
                  </div>
                <% end %>
              </div>
              <div class="post-item-image">
                <object
                  data={"#{Posts.social_image_url(post)}?animate=true"}
                  type="image/svg+xml"
                  aria-label={"Pattern for #{post.title}"}
                  role="img"
                  width="1200"
                  height="630"
                >
                  <img
                    src={Posts.social_image_url(post)}
                    alt={"Pattern for #{post.title}"}
                    width="1200"
                    height="630"
                    loading="lazy"
                    decoding="async"
                  />
                </object>
              </div>
            </article>
          <% end %>
        </div>
      <% end %>
    </.page_layout>
    """
  end
end
