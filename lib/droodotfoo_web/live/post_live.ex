defmodule DroodotfooWeb.PostLive do
  @moduledoc """
  LiveView for displaying individual blog posts.
  """

  use DroodotfooWeb, :live_view
  alias Droodotfoo.Content.{PostFormatter, Posts}
  alias DroodotfooWeb.SEO.JsonLD

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Posts.get_post(slug) do
      {:ok, post} ->
        # Generate social sharing image URL (pattern or featured image)
        social_image_url = Posts.social_image_url(post)
        full_image_url = URI.merge("https://droo.foo", social_image_url) |> to_string()

        # Published time in ISO8601 format for article metadata
        published_time = DateTime.new!(post.date, ~T[00:00:00], "Etc/UTC") |> DateTime.to_iso8601()

        # Modified time if available
        modified_time =
          if post.modified_time do
            DateTime.new!(post.modified_time, ~T[00:00:00], "Etc/UTC") |> DateTime.to_iso8601()
          else
            nil
          end

        # Use first tag as article section for better categorization
        article_section = List.first(post.tags)

        # Get series posts if this post is part of a series
        series_posts =
          if post.series do
            Posts.get_series_posts(post.series)
          else
            []
          end

        # Generate JSON-LD schemas
        json_ld = [
          JsonLD.article_schema(post),
          JsonLD.breadcrumb_schema([
            {"Home", "/"},
            {"Posts", "/posts"},
            {post.title, "/posts/#{slug}"}
          ])
        ]

        {:ok,
         socket
         |> assign(:post, post)
         |> assign(:series_posts, series_posts)
         |> assign(:page_title, post.title)
         |> assign(:meta_description, post.description)
         |> assign(:og_title, post.title)
         |> assign(:og_description, post.description)
         |> assign(:og_type, "article")
         |> assign(:og_image, full_image_url)
         |> assign(:twitter_image, full_image_url)
         |> assign(:published_time, published_time)
         |> assign(:modified_time, modified_time)
         |> assign(:article_section, article_section)
         |> assign(:article_tags, post.tags)
         |> assign(:current_path, "/posts/#{slug}")
         |> assign(:json_ld, json_ld)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Post not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def render(assigns) do
    header = PostFormatter.format_header(assigns.post)
    assigns = assign(assigns, :header, header)

    ~H"""
    <!-- Reading Progress Bar -->
    <div class="reading-progress-container" id="reading-progress" phx-hook="ReadingProgressHook">
      <div class="reading-progress-bar"></div>
    </div>

    <div class="monospace-container">
      <nav class="post-nav">
        <a href="/" class="back-link">{PostFormatter.back_link()}</a>
      </nav>

      <header class="post-header post-header-large">
        <div class="post-header-grid">
          <div class="post-header-content">
            <h1 class="post-title post-title-large">
              {@header.title}
            </h1>
            <%= if @header.description do %>
              <p class="post-description">{@header.description}</p>
            <% end %>
          </div>
          <div class="post-header-meta">
            <%= for {label, value} <- @header.metadata do %>
              <div class="meta-row">
                <span class="meta-label">{label}</span>
                <span class="meta-value">{value}</span>
              </div>
            <% end %>
          </div>
        </div>
      </header>

      <article class="box-single article-spaced" id="post-content" phx-hook="CodeCopyHook">
        {raw(@post.html)}
      </article>

      <footer class="post-footer">
        <a href="/" class="back-link">{PostFormatter.back_link()}</a>
      </footer>
    </div>
    """
  end
end
