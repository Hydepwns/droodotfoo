defmodule DroodotfooWeb.ContentComponents do
  @moduledoc """
  Shared components for content pages (about, projects, web3, contact, resume).
  Provides consistent layout structure and reusable elements.
  """

  use Phoenix.Component

  @doc """
  Site-wide header with droo.foo branding.
  Appears at the top of all pages, clickable to navigate home.
  Uses table layout inspired by the-monospace-web.
  """
  def site_header(assigns) do
    assigns = assign(assigns, :today, Date.utc_today() |> Date.to_string())

    ~H"""
    <header class="site-header" role="banner">
      <table class="header-table">
        <caption class="sr-only">Site header with metadata</caption>
        <tr>
          <td class="header-title" colspan="2">
            <a href="/" class="site-title" aria-label="DROO.FOO - Return to homepage">DROO.FOO</a>
          </td>
          <td class="header-meta-label">Version</td>
          <td class="header-meta-value header-meta-value-right">v1.0.0</td>
        </tr>
        <tr>
          <td class="header-subtitle" colspan="2">Building axol.io</td>
          <td class="header-meta-label">Updated</td>
          <td class="header-meta-value header-meta-value-right"><time datetime={@today}>{@today}</time></td>
        </tr>
        <tr>
          <td class="header-meta-label header-author-label">Author</td>
          <td class="header-meta-value" colspan="3">
            <a href="https://github.com/hydepwns" target="_blank" rel="noopener noreferrer" aria-label="DROO AMOR on GitHub (opens in new tab)">DROO AMOR</a>
          </td>
        </tr>
      </table>
    </header>
    """
  end

  @doc """
  Standard page layout for content pages.
  Wraps content in consistent container with header and footer navigation.
  """
  attr :page_title, :string, required: true
  attr :page_description, :string, default: nil
  attr :current_path, :string, default: ""
  slot :inner_block, required: true

  def page_layout(assigns) do
    ~H"""
    <div class="page-container">
      <.site_header />

      <.site_nav current_path={@current_path} />

      <.page_header title={@page_title} description={@page_description} />

      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Page header with title and optional description.
  """
  attr :title, :string, required: true
  attr :description, :string, default: nil

  def page_header(assigns) do
    ~H"""
    <header class="page-header">
      <h1>{@title}</h1>
      <%= if @description do %>
        <p class="text-muted">{@description}</p>
      <% end %>
    </header>
    """
  end

  @doc """
  Site navigation menu for homepage.
  """
  attr :current_path, :string, default: ""

  def site_nav(assigns) do
    ~H"""
    <nav class="site-nav-simple" aria-label="Primary navigation">
      <p>
        <a href="/about" aria-current={if @current_path == "/about", do: "page", else: false}>About</a>
        <span aria-hidden="true">·</span>
        <a href="/now" aria-current={if @current_path == "/now", do: "page", else: false}>Now</a>
        <span aria-hidden="true">·</span>
        <a href="/projects" aria-current={if @current_path == "/projects", do: "page", else: false}>Projects</a>
        <span aria-hidden="true">·</span>
        <a href="/posts" aria-current={if String.starts_with?(@current_path, "/posts"), do: "page", else: false}>Writing</a>
        <span aria-hidden="true">·</span>
        <a href="/sitemap" aria-current={if @current_path == "/sitemap", do: "page", else: false}>Sitemap</a>
      </p>
    </nav>
    """
  end

  @doc """
  Section header with optional description.
  """
  attr :title, :string, required: true
  attr :class, :string, default: ""
  slot :inner_block

  def section_header(assigns) do
    ~H"""
    <h2 class={"section-title #{@class}"}>
      {@title}
    </h2>
    <%= if @inner_block != [] do %>
      <div class="section-description">
        {render_slot(@inner_block)}
      </div>
    <% end %>
    """
  end

  @doc """
  Reusable form input field with label and error handling.
  """
  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :type, :string, default: "text"
  attr :value, :string, default: ""
  attr :placeholder, :string, default: ""
  attr :error, :string, default: nil
  attr :required, :boolean, default: false
  attr :rest, :global

  def form_input(assigns) do
    ~H"""
    <div class="form-group">
      <label for={@id} class="form-label">
        {@label}{if @required, do: " *", else: ""}
      </label>
      <input
        type={@type}
        id={@id}
        name={@name}
        value={@value}
        class={["form-input", @error && "error"]}
        placeholder={@placeholder}
        required={@required}
        {@rest}
      />
      <%= if @error do %>
        <div class="error-message">{@error}</div>
      <% end %>
    </div>
    """
  end

  @doc """
  Reusable form textarea field with label and error handling.
  """
  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :value, :string, default: ""
  attr :placeholder, :string, default: ""
  attr :error, :string, default: nil
  attr :required, :boolean, default: false
  attr :rows, :integer, default: 6
  attr :rest, :global

  def form_textarea(assigns) do
    ~H"""
    <div class="form-group">
      <label for={@id} class="form-label">
        {@label}{if @required, do: " *", else: ""}
      </label>
      <textarea
        id={@id}
        name={@name}
        class={["form-textarea", @error && "error"]}
        placeholder={@placeholder}
        rows={@rows}
        required={@required}
        {@rest}
      ><%= @value %></textarea>
      <%= if @error do %>
        <div class="error-message">{@error}</div>
      <% end %>
    </div>
    """
  end

  @doc """
  Status message display for success/error states.
  """
  attr :type, :atom, required: true
  attr :message, :string, required: true

  def status_message(assigns) do
    ~H"""
    <div class={["status-message", "status-#{@type}"]}>
      <div class="status-content">
        {@message}
      </div>
    </div>
    """
  end

  @doc """
  Display-only technology tags.
  Shows a list of technologies as styled tags.
  """
  attr :technologies, :list, default: []

  def tech_tags(assigns) do
    ~H"""
    <%= if @technologies != [] do %>
      <div class="tech-tags">
        <%= for tech <- @technologies do %>
          <span class="tech-tag">{tech}</span>
        <% end %>
      </div>
    <% end %>
    """
  end

  @doc """
  Interactive technology chip buttons.
  Can be clicked and toggled, typically used for filtering.
  """
  attr :technologies, :list, required: true
  attr :selected, :list, default: []
  attr :click_event, :string, required: true

  def tech_chips(assigns) do
    ~H"""
    <div class="tech-chips">
      <%= for tech <- @technologies do %>
        <button
          class={[
            "tech-chip",
            tech in @selected && "selected"
          ]}
          phx-click={@click_event}
          phx-value-tech={tech}
        >
          {tech}
        </button>
      <% end %>
    </div>
    """
  end

  @doc """
  Series navigation component for blog posts.
  Displays links to other posts in the same series.
  """
  attr :current_post, :map, required: true
  attr :series_posts, :list, required: true

  def series_nav(assigns) do
    ~H"""
    <%= if length(@series_posts) > 1 do %>
      <div class="series-nav">
        <div class="series-nav-title">
          Series: {@current_post.series}
        </div>
        <ol>
          <%= for post <- @series_posts do %>
            <li>
              <%= if post.slug == @current_post.slug do %>
                <strong class="series-current">{post.title}</strong> <span class="text-muted">(current)</span>
              <% else %>
                <a href={"/posts/#{post.slug}"}>{post.title}</a>
              <% end %>
            </li>
          <% end %>
        </ol>
      </div>
    <% end %>
    """
  end

  @doc """
  Social media meta tags for Open Graph and Twitter Cards.
  Improves how links appear when shared on social platforms.

  ## Options

    * `:title` - Page title (required)
    * `:description` - Page description (required)
    * `:url` - Canonical URL of the page (required)
    * `:image` - Social card image URL (optional)
    * `:image_alt` - Alt text for the image (optional)
    * `:type` - Open Graph type (default: "website", use "article" for blog posts)
    * `:author` - Author name for articles (optional)
    * `:published_time` - Article publish date in ISO8601 (optional)
    * `:tags` - List of article tags (optional)

  ## Examples

      # For a blog post
      <.social_meta_tags
        title="My Blog Post"
        description="An interesting article"
        url="https://droo.foo/posts/my-post"
        image="https://droo.foo/patterns/my-post"
        image_alt="Visual pattern for: My Blog Post"
        type="article"
        author="DROO AMOR"
        published_time="2025-01-18T00:00:00Z"
        tags={["elixir", "phoenix"]}
      />

      # For a regular page
      <.social_meta_tags
        title="About"
        description="Learn about DROO AMOR"
        url="https://droo.foo/about"
      />
  """
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :url, :string, required: true
  attr :image, :string, default: nil
  attr :image_alt, :string, default: nil
  attr :type, :string, default: "website"
  attr :author, :string, default: nil
  attr :published_time, :string, default: nil
  attr :tags, :list, default: []

  def social_meta_tags(assigns) do
    # Set default image if none provided
    assigns =
      assign(
        assigns,
        :effective_image,
        assigns.image || "https://droo.foo/images/logo-512.png"
      )

    assigns =
      assign(
        assigns,
        :effective_image_alt,
        assigns.image_alt || "DROO.FOO - #{assigns.title}"
      )

    ~H"""
    <!-- Open Graph / Facebook -->
    <meta property="og:type" content={@type} />
    <meta property="og:url" content={@url} />
    <meta property="og:title" content={@title} />
    <meta property="og:description" content={@description} />
    <meta property="og:image" content={@effective_image} />
    <meta property="og:image:alt" content={@effective_image_alt} />
    <meta property="og:site_name" content="DROO.FOO" />
    <meta property="og:locale" content="en_US" />

    <!-- Article-specific meta tags -->
    <%= if @type == "article" do %>
      <%= if @author do %>
        <meta property="article:author" content={@author} />
      <% end %>
      <%= if @published_time do %>
        <meta property="article:published_time" content={@published_time} />
      <% end %>
      <%= for tag <- @tags do %>
        <meta property="article:tag" content={tag} />
      <% end %>
    <% end %>

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:url" content={@url} />
    <meta name="twitter:title" content={@title} />
    <meta name="twitter:description" content={@description} />
    <meta name="twitter:image" content={@effective_image} />
    <meta name="twitter:image:alt" content={@effective_image_alt} />

    <!-- Additional SEO meta tags -->
    <meta name="description" content={@description} />
    <link rel="canonical" href={@url} />
    """
  end
end
