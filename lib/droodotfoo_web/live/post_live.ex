defmodule DroodotfooWeb.PostLive do
  @moduledoc """
  LiveView for displaying individual blog posts.
  """

  use DroodotfooWeb, :live_view
  alias Droodotfoo.Content.PostManager

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case PostManager.get_post(slug) do
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
    ~H"""
    <div class="monospace-container">
      <header class="box-thick">
        <nav>
          <a href="/" class="back-link">&lt;- Back to Home</a>
        </nav>
        <h1><%= @post.title %></h1>
        <p class="text-muted">
          <%= Date.to_string(@post.date) %> | <%= @post.read_time %> min read
        </p>
        <%= if length(@post.tags) > 0 do %>
          <p class="text-muted">
            Tags: <%= Enum.join(@post.tags, ", ") %>
          </p>
        <% end %>
      </header>

      <article class="box-single">
        <%= raw(@post.html) %>
      </article>

      <footer>
        <a href="/" class="back-link">Back to Home</a>
      </footer>
    </div>
    """
  end
end
