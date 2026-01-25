defmodule DroodotfooWeb.NowLive do
  @moduledoc """
  Now page showing current focus and activities.
  Inspired by Derek Sivers' /now page movement (nownownow.com).
  Updated manually to reflect current status.
  """

  use DroodotfooWeb, :live_view
  alias Droodotfoo.Resume.ResumeData
  alias DroodotfooWeb.SEO.JsonLD
  import DroodotfooWeb.ContentComponents

  @impl true
  def mount(_params, _session, socket) do
    resume = ResumeData.get_resume_data()
    last_updated = ~D[2025-01-23]

    json_ld = [
      JsonLD.breadcrumb_schema([
        {"Home", "/"},
        {"Now", "/now"}
      ])
    ]

    socket
    |> assign(:resume, resume)
    |> assign(:last_updated, last_updated)
    |> assign(:page_title, "Now")
    |> assign(:current_path, "/now")
    |> assign(:json_ld, json_ld)
    |> then(&{:ok, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout
      page_title="Now"
      page_description="What I'm currently focused on"
      current_path={@current_path}
    >
      <section class="about-section">
        <div class="text-muted mb-2">
          <strong>Last updated:</strong>
          {Date.to_string(@last_updated)}
        </div>

        <h3 class="mt-2">Running</h3>
        <p>
          Running <strong><a href="https://axol.io" target="_blank" rel="noopener">axol.io</a></strong>.
          Sequencers and nodes across Ethereum L2s and mainnet:
        </p>

        <article class="experience-item">
          <div class="experience-header">
            <div class="experience-title">Sequencers & Nodes</div>
            <div class="experience-company">Production</div>
          </div>

          <p class="experience-description">
            Running validator infrastructure for transaction ordering and state transitions.
            Currently operating on Aztec, Base, Optimism, and Ethereum mainnet.
          </p>

          <div class="tech-tags mt-1">
            <span class="tech-tag">Aztec</span>
            <span class="tech-tag">Base</span>
            <span class="tech-tag">Optimism</span>
            <span class="tech-tag">Ethereum</span>
          </div>
        </article>

        <p class="mt-2 text-muted">
          Also building FOSS: <strong>mana</strong>
          (Ethereum client), <strong>raxol</strong>
          (terminal UI framework), and <strong>riddler</strong>
          (cross-chain solver).
          See <.link navigate={~p"/projects"}>projects</.link>.
        </p>

        <hr />

        <h3 class="mt-2">Learning</h3>
        <p>
          Reading production source code to understand tradeoffs in validator infrastructure
          and cross-chain messaging:
        </p>

        <details class="experience-details" open>
          <summary class="experience-summary">What I'm reading now →</summary>
          <div class="mt-1">
            <ul>
              <li>
                <strong>go-ethereum (geth)</strong>
                - Core client implementation, EVM execution, and state management
              </li>
              <li>
                <strong>ibc-go</strong>
                - IBC protocol implementation in Cosmos SDK, packet routing and state proofs
              </li>
              <li>
                <strong>Hyperlane</strong>
                - Bridge architecture, validator sets, and cross-chain message passing
              </li>
              <li>
                <strong>OTP source</strong>
                - gen_server internals, supervisor restart strategies, and distributed Erlang
              </li>
              <li>
                <strong>Solver rebalancer architectures</strong>
                - cross-chain inventory management and quant trading systems
              </li>
            </ul>
          </div>
        </details>

        <div class="tech-tags mt-1">
          <span class="tech-tag">Ethereum</span>
          <span class="tech-tag">Cosmos SDK</span>
          <span class="tech-tag">Elixir</span>
          <span class="tech-tag">Rust</span>
          <span class="tech-tag">IBC</span>
          <span class="tech-tag">EVM</span>
        </div>

        <hr />

        <h3 class="mt-2">Location & Work</h3>
        <p>
          Based in <strong>{@resume.personal_info.location}</strong>
          (<time>{@resume.personal_info.timezone}</time>).
          Remote. Mostly protocol research, open-source work, and running validators.
        </p>

        <%= if @resume.focus_areas && length(@resume.focus_areas) > 0 do %>
          <div class="mt-1">
            <strong>Current focus areas:</strong>
            <div class="tech-tags mt-1">
              <%= for area <- @resume.focus_areas do %>
                <span class="tech-tag">{area}</span>
              <% end %>
            </div>
          </div>
        <% end %>

        <%= if @resume.availability == "open_to_consulting" do %>
          <hr />

          <h3 class="mt-2">Availability</h3>
          <div class="experience-item">
            <p>
              Open to consulting on validator infrastructure and protocol work.
              Mostly Cosmos SDK, Ethereum clients, and node operations.
            </p>
            <p class="text-muted mt-1">
              <.link navigate={~p"/about"}>Experience here</.link> if you want to work together.
            </p>
          </div>
        <% end %>

        <hr />

        <p class="text-muted">
          <strong>About /now pages:</strong>
          This page follows the
          <a
            href="https://nownownow.com/about"
            target="_blank"
            rel="noopener"
          >
            /now page movement
          </a>
          by Derek Sivers. It's manually updated whenever my focus significantly shifts.
          Think of it as a snapshot of what has my attention right now.
        </p>
      </section>
    </.page_layout>
    """
  end
end
