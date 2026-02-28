defmodule DroodotfooWeb.Wiki.LandingLive do
  @moduledoc """
  Landing page for wiki.droo.foo - Terminal aesthetic matching droo.foo.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Wiki.Layouts

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
          source={:osrs}
        />
        <.source_item
          href="/nlab"
          title="nLab"
          description="Mathematics and physics - category theory, homotopy theory"
          source={:nlab}
        />
        <.source_item
          href="/wikipedia"
          title="Wikipedia"
          description="Selected articles from the free encyclopedia"
          source={:wikipedia}
        />
        <.source_item
          href="/machines"
          title="Vintage Machinery"
          description="Industrial equipment, machine tools, and manufacturing history"
          source={:vintage_machinery}
        />
        <.source_item
          href="/art"
          title="WikiArt"
          description="Visual arts encyclopedia - paintings, artists, and movements"
          source={:wikiart}
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
          Part of the <a href="https://droo.foo" target="_blank" rel="noopener">droo.foo</a>
          network.
          See also: <a href="https://lib.droo.foo" target="_blank" rel="noopener">lib.droo.foo</a>
          (document library).
        </p>
      </section>
    </Layouts.app>
    """
  end

  attr :href, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :source, :atom, required: true

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
        <.source_pattern source={@source} />
      </div>
    </article>
    """
  end

  # Pattern styles for each source - uses the same PatternGenerator as blog posts
  @source_patterns %{
    osrs: "isometric",
    nlab: "topology",
    wikipedia: "constellation",
    vintage_machinery: "circuit",
    wikiart: "aurora"
  }

  attr :source, :atom, required: true

  defp source_pattern(assigns) do
    style = Map.get(@source_patterns, assigns.source, "geometric")
    # Use source name as slug for deterministic pattern
    slug = "wiki-#{assigns.source}"
    pattern_url = "/patterns/#{slug}?style=#{style}&animate=true"
    assigns = assign(assigns, :pattern_url, pattern_url)

    ~H"""
    <object
      data={@pattern_url}
      type="image/svg+xml"
      aria-label={"Pattern for #{@source}"}
      role="img"
    >
      <img
        src={@pattern_url}
        alt={"Pattern for #{@source}"}
        loading="lazy"
        decoding="async"
      />
    </object>
    """
  end
end
