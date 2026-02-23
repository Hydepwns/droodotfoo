defmodule WikiWeb.Layouts do
  @moduledoc """
  Layouts and related functionality for wiki.droo.foo / lib.droo.foo.

  Terminal aesthetic matching droo.foo: Monaspace fonts, sharp corners, 2px borders,
  table-based header with metadata.
  """
  use WikiWeb, :html

  embed_templates "layouts/*"

  @themes [
    {"system", "SYS"},
    {"light", "LIT"},
    {"dark", "DRK"},
    {"synthwave84", "SYN"},
    {"hotline", "HOT"},
    {"matrix", "MTX"},
    {"cyberpunk", "CYB"},
    {"phosphor", "PHO"},
    {"amber", "AMB"},
    {"high-contrast", "HIC"}
  ]

  @doc """
  Renders the app layout with terminal aesthetic matching droo.foo.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current scope"

  attr :current_path, :string, default: ""

  slot :inner_block, required: true

  def app(assigns) do
    assigns =
      assigns
      |> assign(:themes, @themes)
      |> assign(:today, Date.utc_today() |> Date.to_string())
      |> assign(:version, Application.spec(:wiki, :vsn) |> to_string())

    ~H"""
    <div class="page-container">
      <.site_header today={@today} version={@version} />

      <.site_nav current_path={@current_path} />

      <main>
        {render_slot(@inner_block)}
      </main>
    </div>

    <.theme_button />
    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Site header with table layout matching droo.foo.
  """
  attr :today, :string, required: true
  attr :version, :string, required: true

  def site_header(assigns) do
    ~H"""
    <header class="site-header" role="banner">
      <table class="header-table">
        <tr>
          <td class="header-title" colspan="2">
            <.link navigate="/" class="site-title">
              WIKI.DROO.FOO
            </.link>
          </td>
          <td class="header-meta-label">Version</td>
          <td class="header-meta-value header-meta-value-right">v{@version}</td>
        </tr>
        <tr>
          <td class="header-subtitle" colspan="2">Federated wiki mirror</td>
          <td class="header-meta-label">Updated</td>
          <td class="header-meta-value header-meta-value-right">
            <time datetime={@today}>{@today}</time>
          </td>
        </tr>
        <tr>
          <td class="header-meta-label header-author-label">Source</td>
          <td class="header-meta-value" colspan="3">
            <a href="https://droo.foo" target="_blank" rel="noopener noreferrer">
              DROO.FOO
            </a>
          </td>
        </tr>
      </table>
    </header>
    """
  end

  @doc """
  Site navigation with dot-separated links.
  """
  attr :current_path, :string, default: ""

  def site_nav(assigns) do
    ~H"""
    <nav class="site-nav-simple" aria-label="Primary navigation">
      <p>
        <.link navigate="/" aria-current={if @current_path == "/", do: "page", else: false}>
          Home
        </.link>
        <span aria-hidden="true">·</span>
        <.link
          navigate="/search"
          aria-current={if @current_path == "/search", do: "page", else: false}
        >
          Search
        </.link>
        <span aria-hidden="true">·</span>
        <.link
          navigate="/osrs"
          aria-current={if String.starts_with?(@current_path || "", "/osrs"), do: "page", else: false}
        >
          OSRS
        </.link>
        <span aria-hidden="true">·</span>
        <.link
          navigate="/nlab"
          aria-current={if String.starts_with?(@current_path || "", "/nlab"), do: "page", else: false}
        >
          nLab
        </.link>
        <span aria-hidden="true">·</span>
        <a href="https://droo.foo" target="_blank" rel="noopener">
          droo.foo
        </a>
      </p>
    </nav>
    """
  end

  @doc """
  Renders the theme toggle button (fixed position).
  """
  def theme_button(assigns) do
    ~H"""
    <button
      class="theme-toggle"
      id="theme-toggle-btn"
      onclick="window.cycleTheme && window.cycleTheme()"
      data-tooltip="Theme (T)"
      aria-label="Cycle Theme"
    >
      T
    </button>
    """
  end

  @doc """
  Shows the flash group with terminal-style messages.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title="CONNECTION LOST"
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect...
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="SERVER ERROR"
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect...
      </.flash>
    </div>
    """
  end
end
