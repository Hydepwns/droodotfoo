defmodule DroodotfooWeb.PostLive do
  @moduledoc """
  LiveView for displaying individual blog posts.
  """

  use DroodotfooWeb, :live_view
  alias Droodotfoo.Content.{PostFormatter, Posts}

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Posts.get_post(slug) do
      {:ok, post} ->
        {:ok,
         socket
         |> assign(:post, post)
         |> assign(:page_title, post.title)}

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

      <article class="box-single article-spaced">
        {raw(@post.html)}
      </article>

      <footer class="post-footer">
        <a href="/" class="back-link">{PostFormatter.back_link()}</a>
      </footer>
    </div>
    """
  end
end
