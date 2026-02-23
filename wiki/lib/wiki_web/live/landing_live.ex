defmodule WikiWeb.LandingLive do
  @moduledoc """
  Landing page for wiki.droo.foo - Terminal aesthetic matching droo.foo.
  """

  use WikiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "WIKI", current_path: "/")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <section class="section-spaced">
        <h2 class="section-header-bordered">
          SOURCES
        </h2>

        <.source_item
          href="/osrs"
          title="OSRS Wiki"
          description="Old School RuneScape items, monsters, quests, and guides"
          pattern={:osrs}
        />
        <.source_item
          href="/nlab"
          title="nLab"
          description="Mathematics and physics - category theory, homotopy theory"
          pattern={:nlab}
        />
        <.source_item
          href="/wikipedia"
          title="Wikipedia"
          description="Selected articles from the free encyclopedia"
          pattern={:wikipedia}
        />
      </section>

      <section class="section-spaced">
        <h2 class="section-header-bordered">
          SEARCH
        </h2>
        <p>
          <.link navigate="/search">
            Search across all sources
          </.link>
          - keyword, semantic, and hybrid search modes available.
        </p>
      </section>

      <section class="section-spaced">
        <h2 class="section-header-bordered">
          CONNECT
        </h2>
        <p>
          Part of the <a href="https://droo.foo" target="_blank" rel="noopener">droo.foo</a> network.
          See also: <a href="https://lib.droo.foo" target="_blank" rel="noopener">lib.droo.foo</a> (document library).
        </p>
      </section>
    </Layouts.app>
    """
  end

  attr :href, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :pattern, :atom, required: true

  defp source_item(assigns) do
    ~H"""
    <article class="post-item-with-image">
      <div class="post-item-content">
        <h3>
          <.link navigate={@href} class="link-reset">
            {@title}
          </.link>
        </h3>
        <p class="text-muted-alt">{@description}</p>
      </div>
      <div class="post-item-image">
        <.source_pattern pattern={@pattern} />
      </div>
    </article>
    """
  end

  attr :pattern, :atom, required: true

  defp source_pattern(%{pattern: :osrs} = assigns) do
    # OSRS: Crossed swords pattern (gaming/RPG)
    ~H"""
    <svg viewBox="0 0 120 80" xmlns="http://www.w3.org/2000/svg">
      <rect width="120" height="80" fill="var(--background-color-alt)" />
      <g stroke="var(--text-color)" stroke-width="2" fill="none" opacity="0.6">
        <line x1="30" y1="15" x2="90" y2="65" />
        <line x1="90" y1="15" x2="30" y2="65" />
        <polygon points="30,15 25,20 30,25 35,20" fill="var(--text-color)" />
        <polygon points="90,15 85,20 90,25 95,20" fill="var(--text-color)" />
        <polygon points="30,65 25,60 30,55 35,60" fill="var(--text-color)" />
        <polygon points="90,65 85,60 90,55 95,60" fill="var(--text-color)" />
      </g>
      <text x="60" y="45" text-anchor="middle" font-family="var(--font-family)" font-size="10" fill="var(--text-color)" opacity="0.4">OSRS</text>
    </svg>
    """
  end

  defp source_pattern(%{pattern: :nlab} = assigns) do
    # nLab: Commutative diagram pattern (math/category theory)
    ~H"""
    <svg viewBox="0 0 120 80" xmlns="http://www.w3.org/2000/svg">
      <rect width="120" height="80" fill="var(--background-color-alt)" />
      <g stroke="var(--text-color)" stroke-width="1.5" fill="none" opacity="0.6">
        <circle cx="30" cy="25" r="8" />
        <circle cx="90" cy="25" r="8" />
        <circle cx="30" cy="55" r="8" />
        <circle cx="90" cy="55" r="8" />
        <line x1="38" y1="25" x2="82" y2="25" marker-end="url(#arrow)" />
        <line x1="30" y1="33" x2="30" y2="47" marker-end="url(#arrow)" />
        <line x1="90" y1="33" x2="90" y2="47" marker-end="url(#arrow)" />
        <line x1="38" y1="55" x2="82" y2="55" marker-end="url(#arrow)" />
      </g>
      <defs>
        <marker id="arrow" markerWidth="6" markerHeight="6" refX="5" refY="3" orient="auto">
          <path d="M0,0 L6,3 L0,6 Z" fill="var(--text-color)" opacity="0.6" />
        </marker>
      </defs>
      <text x="60" y="44" text-anchor="middle" font-family="var(--font-family)" font-size="8" fill="var(--text-color)" opacity="0.4">nLab</text>
    </svg>
    """
  end

  defp source_pattern(%{pattern: :wikipedia} = assigns) do
    # Wikipedia: Globe/book pattern (encyclopedia)
    ~H"""
    <svg viewBox="0 0 120 80" xmlns="http://www.w3.org/2000/svg">
      <rect width="120" height="80" fill="var(--background-color-alt)" />
      <g stroke="var(--text-color)" stroke-width="1.5" fill="none" opacity="0.6">
        <circle cx="60" cy="40" r="25" />
        <ellipse cx="60" cy="40" rx="25" ry="10" />
        <ellipse cx="60" cy="40" rx="10" ry="25" />
        <line x1="35" y1="40" x2="85" y2="40" />
        <line x1="60" y1="15" x2="60" y2="65" />
      </g>
      <text x="60" y="75" text-anchor="middle" font-family="var(--font-family)" font-size="8" fill="var(--text-color)" opacity="0.4">WIKI</text>
    </svg>
    """
  end

  defp source_pattern(assigns) do
    # Fallback: Simple grid pattern
    ~H"""
    <svg viewBox="0 0 120 80" xmlns="http://www.w3.org/2000/svg">
      <rect width="120" height="80" fill="var(--background-color-alt)" />
      <g stroke="var(--text-color)" stroke-width="1" opacity="0.3">
        <line x1="0" y1="20" x2="120" y2="20" />
        <line x1="0" y1="40" x2="120" y2="40" />
        <line x1="0" y1="60" x2="120" y2="60" />
        <line x1="30" y1="0" x2="30" y2="80" />
        <line x1="60" y1="0" x2="60" y2="80" />
        <line x1="90" y1="0" x2="90" y2="80" />
      </g>
    </svg>
    """
  end
end
