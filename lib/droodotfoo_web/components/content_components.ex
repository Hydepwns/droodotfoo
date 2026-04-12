defmodule DroodotfooWeb.ContentComponents do
  @moduledoc """
  Shared components for content pages (about, projects, web3, contact, resume).
  Provides consistent layout structure and reusable elements.
  """

  use DroodotfooWeb, :html

  @doc """
  Site-wide header with droo.foo branding.
  Appears at the top of all pages, clickable to navigate home.
  Uses table layout inspired by the-monospace-web.
  """
  def site_header(assigns) do
    assigns = assign(assigns, :today, Date.utc_today() |> Date.to_string())
    assigns = assign(assigns, :version, Application.spec(:droodotfoo, :vsn) |> to_string())

    ~H"""
    <header class="site-header" role="banner">
      <table class="header-table">
        <caption class="sr-only">Site header with metadata</caption>
        <tr>
          <td class="header-title" colspan="2">
            <.link navigate={~p"/"} class="site-title" aria-label="DROO.FOO - Return to homepage">
              DROO.FOO
            </.link>
          </td>
          <td class="header-meta-label">Version</td>
          <td class="header-meta-value header-meta-value-right">v{@version}</td>
        </tr>
        <tr>
          <td class="header-subtitle" colspan="2">Engineer building his Gundam</td>
          <td class="header-meta-label">Updated</td>
          <td class="header-meta-value header-meta-value-right">
            <time datetime={@today}>{@today}</time>
          </td>
        </tr>
        <tr>
          <td class="header-meta-label header-author-label">Author</td>
          <td class="header-meta-value" colspan="3">
            <a
              href="https://github.com/DROOdotFOO/droodotfoo"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="DROO on GitHub - droodotfoo repository (opens in new tab)"
            >
              DROO
            </a>
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

      <hr />
      <.connect_links />
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
        <.link
          navigate={~p"/about"}
          aria-current={if @current_path == "/about", do: "page", else: false}
        >
          About
        </.link>
        <span aria-hidden="true">·</span>
        <.link navigate={~p"/now"} aria-current={if @current_path == "/now", do: "page", else: false}>
          Now
        </.link>
        <span aria-hidden="true">·</span>
        <.link
          navigate={~p"/projects"}
          aria-current={if @current_path == "/projects", do: "page", else: false}
        >
          Projects
        </.link>
        <span aria-hidden="true">·</span>
        <.link
          navigate={~p"/posts"}
          aria-current={if String.starts_with?(@current_path, "/posts"), do: "page", else: false}
        >
          Writing
        </.link>
        <span aria-hidden="true">·</span>
        <.link
          navigate={~p"/contact"}
          aria-current={if @current_path == "/contact", do: "page", else: false}
        >
          Contact
        </.link>
        <span aria-hidden="true">·</span>
        <.link
          navigate={~p"/sitemap"}
          aria-current={if @current_path == "/sitemap", do: "page", else: false}
        >
          Sitemap
        </.link>
      </p>
    </nav>
    """
  end

  @doc """
  Compact connect/social links bar with SVG icons.
  """
  def connect_links(assigns) do
    ~H"""
    <footer class="connect-bar" aria-label="Connect">
      <div class="social-links">
        <a href="https://github.com/DROOdotFOO" target="_blank" rel="noopener" aria-label="GitHub">
          <svg viewBox="0 0 24 24" width="28" height="28" fill="currentColor" aria-hidden="true">
            <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
          </svg>
        </a>
        <a href="https://x.com/DROOdotFOO" target="_blank" rel="noopener" aria-label="X (Twitter)">
          <svg viewBox="0 0 24 24" width="28" height="28" fill="currentColor" aria-hidden="true">
            <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
          </svg>
        </a>
        <a
          href="https://www.linkedin.com/in/droodotfoo"
          target="_blank"
          rel="noopener"
          aria-label="LinkedIn"
        >
          <svg viewBox="0 0 24 24" width="28" height="28" fill="currentColor" aria-hidden="true">
            <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
          </svg>
        </a>
        <a href="https://t.me/DROOdotFOO" target="_blank" rel="noopener" aria-label="Telegram">
          <svg viewBox="0 0 24 24" width="28" height="28" fill="currentColor" aria-hidden="true">
            <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z" />
          </svg>
        </a>
        <a href="mailto:drew@axol.io" aria-label="Email">
          <svg viewBox="0 0 24 24" width="28" height="28" fill="currentColor" aria-hidden="true">
            <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z" />
          </svg>
        </a>
        <a
          href="https://discord.com/users/droodotfoo"
          target="_blank"
          rel="noopener"
          aria-label="Discord"
        >
          <svg viewBox="0 0 24 24" width="28" height="28" fill="currentColor" aria-hidden="true">
            <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z" />
          </svg>
        </a>
      </div>
    </footer>
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
  Shows a list of technologies as styled tags with language-colored dots.
  """
  attr :technologies, :list, default: []

  def tech_tags(assigns) do
    ~H"""
    <%= if @technologies != [] do %>
      <div class="tech-tags">
        <%= for tech <- @technologies do %>
          <span class="tech-tag">
            <span :if={lang_known?(tech)} class="lang-dot" style={"background: #{lang_color(tech)}"}>
            </span>
            {tech}
          </span>
        <% end %>
      </div>
    <% end %>
    """
  end

  defp lang_color(tech) do
    Droodotfoo.GitHub.LanguageColors.get_color(tech)
  end

  defp lang_known?(tech) do
    Droodotfoo.GitHub.LanguageColors.get_color(tech) != "#858585"
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
                <strong class="series-current">{post.title}</strong>
                <span class="text-muted">(current)</span>
              <% else %>
                <.link navigate={~p"/posts/#{post.slug}"}>{post.title}</.link>
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
