defmodule DroodotfooWeb.Git.Layouts do
  @moduledoc """
  Layouts for git.droo.foo - Git repository browser.

  Terminal aesthetic matching droo.foo: Monaspace fonts, sharp corners, 2px borders,
  table-based header with metadata.
  """
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: DroodotfooWeb.Endpoint,
    router: DroodotfooWeb.Router,
    statics: DroodotfooWeb.static_paths()

  import Phoenix.Controller, only: [get_csrf_token: 0]

  alias DroodotfooWeb.Git.CoreComponents
  alias Phoenix.LiveView.JS

  embed_templates "layouts/*"

  @doc """
  Renders the app layout with terminal aesthetic.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
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

      <main>
        {render_slot(@inner_block)}
      </main>
    </div>

    <.theme_button />
    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Site header with table layout.
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
              GIT.DROO.FOO
            </.link>
          </td>
          <td class="header-meta-label">Version</td>
          <td class="header-meta-value header-meta-value-right">v{@version}</td>
        </tr>
        <tr>
          <td class="header-subtitle" colspan="2">Repository browser</td>
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
          Repositories
        </.link>
        <span aria-hidden="true">.</span>
        <a href="https://git.droo.foo" target="_blank" rel="noopener">
          Forgejo
        </a>
        <span aria-hidden="true">.</span>
        <a href="https://droo.foo" target="_blank" rel="noopener">
          droo.foo
        </a>
      </p>
    </nav>
    """
  end

  @doc """
  Renders the theme toggle button.
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
  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"

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
