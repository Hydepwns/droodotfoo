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
    <header class="box-single site-header">
      <table class="header-table">
        <tr>
          <td class="header-title" colspan="2">
            <a href="/" class="site-title">DROO.FOO</a>
          </td>
          <td class="header-meta-label">Version</td>
          <td class="header-meta-value header-meta-value-right">v1.0.0</td>
        </tr>
        <tr>
          <td class="header-subtitle" colspan="2">Building axol.io</td>
          <td class="header-meta-label">Updated</td>
          <td class="header-meta-value header-meta-value-right">{@today}</td>
        </tr>
        <tr>
          <td class="header-meta-label header-author-label">Author</td>
          <td class="header-meta-value" colspan="3">
            <a href="https://github.com/hydepwns" target="_blank" rel="noopener">DROO AMOR</a>
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
  slot :inner_block, required: true

  def page_layout(assigns) do
    ~H"""
    <div class="page-container">
      <.site_header />

      <.page_header title={@page_title} description={@page_description} />

      {render_slot(@inner_block)}

      <hr class="section-divider" />

      <.page_footer />
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
  Standard page footer with navigation links.
  """
  def page_footer(assigns) do
    ~H"""
    <footer class="page-footer">
      <nav class="footer-nav">
        <a href="/">← Home</a>
        <span class="nav-separator">|</span>
        <a href="/about">About</a>
        <span class="nav-separator">|</span>
        <a href="/projects">Projects</a>
        <span class="nav-separator">|</span>
        <a href="/resume">Resume</a>
      </nav>
    </footer>
    """
  end

  @doc """
  Site navigation menu for homepage.
  """
  def site_nav(assigns) do
    ~H"""
    <nav class="site-nav-simple">
      <p>
        <a href="/about">About</a>
        · <a href="/projects">Projects</a>
        · <a href="/resume">Resume</a>
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
end
