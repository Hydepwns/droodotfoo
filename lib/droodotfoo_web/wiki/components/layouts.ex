defmodule DroodotfooWeb.Wiki.Layouts do
  @moduledoc """
  Layouts and related functionality for wiki.droo.foo / lib.droo.foo.

  Terminal aesthetic matching droo.foo: Monaspace fonts, sharp corners, 2px borders,
  table-based header with metadata.
  """
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: DroodotfooWeb.Endpoint,
    router: DroodotfooWeb.Router,
    statics: DroodotfooWeb.static_paths()

  import Phoenix.Controller, only: [get_csrf_token: 0]
  import Phoenix.HTML, only: [raw: 1]

  alias DroodotfooWeb.Wiki.CoreComponents
  alias Phoenix.LiveView.JS

  embed_templates "layouts/*"

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
      |> assign(:today, Date.utc_today() |> Date.to_string())
      |> assign(:version, Application.spec(:droodotfoo, :vsn) |> to_string())

    ~H"""
    <div class="page-container">
      <.site_header today={@today} version={@version} />

      <.site_nav current_path={@current_path} />

      <main id="main-content" role="main">
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
  Breadcrumb navigation for wiki pages.
  """
  attr :items, :list,
    required: true,
    doc: "List of {label, path} tuples, last item is current page"

  def breadcrumbs(assigns) do
    ~H"""
    <nav class="breadcrumbs" aria-label="Breadcrumb">
      <ol class="breadcrumb-list">
        <li :for={{label, path, is_last} <- annotate_items(@items)} class="breadcrumb-item">
          <.link :if={!is_last} navigate={path} class="breadcrumb-link">
            {label}
          </.link>
          <span :if={is_last} class="breadcrumb-current" aria-current="page">
            {label}
          </span>
          <span :if={!is_last} class="breadcrumb-sep" aria-hidden="true">/</span>
        </li>
      </ol>
    </nav>
    """
  end

  defp annotate_items(items) do
    len = length(items)

    items
    |> Enum.with_index(1)
    |> Enum.map(fn {{label, path}, idx} -> {label, path, idx == len} end)
  end

  @doc """
  Table of contents component for article pages.
  Only renders if there are 2+ headings.
  """
  attr :headings, :list, required: true, doc: "List of heading maps with :level, :text, :id"

  def table_of_contents(assigns) do
    ~H"""
    <nav :if={length(@headings) >= 2} class="toc" aria-label="Table of contents">
      <details open>
        <summary class="toc-title">CONTENTS</summary>
        <ol class="toc-list">
          <li :for={heading <- @headings} class={"toc-item toc-level-#{heading.level}"}>
            <a href={"##{heading.id}"} class="toc-link">
              {heading.text}
            </a>
          </li>
        </ol>
      </details>
    </nav>
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
        <span aria-hidden="true">.</span>
        <.link
          navigate="/search"
          aria-current={if @current_path == "/search", do: "page", else: false}
        >
          Search
        </.link>
        <span aria-hidden="true">.</span>
        <.link
          navigate="/osrs"
          aria-current={if String.starts_with?(@current_path || "", "/osrs"), do: "page", else: false}
        >
          OSRS
        </.link>
        <span aria-hidden="true">.</span>
        <.link
          navigate="/nlab"
          aria-current={if String.starts_with?(@current_path || "", "/nlab"), do: "page", else: false}
        >
          nLab
        </.link>
        <span aria-hidden="true">.</span>
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
      <CoreComponents.flash kind={:info} flash={@flash} />
      <CoreComponents.flash kind={:error} flash={@flash} />

      <CoreComponents.flash
        id="client-error"
        kind={:error}
        title="CONNECTION LOST"
        phx-disconnected={
          CoreComponents.show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")
        }
        phx-connected={CoreComponents.hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect...
      </CoreComponents.flash>

      <CoreComponents.flash
        id="server-error"
        kind={:error}
        title="SERVER ERROR"
        phx-disconnected={
          CoreComponents.show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")
        }
        phx-connected={CoreComponents.hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect...
      </CoreComponents.flash>
    </div>
    """
  end
end
