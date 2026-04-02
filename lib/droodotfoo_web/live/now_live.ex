defmodule DroodotfooWeb.NowLive do
  @moduledoc """
  Now page showing current focus and activities.
  Inspired by Derek Sivers' /now page movement (nownownow.com).
  Updated manually to reflect current status.
  """

  use DroodotfooWeb, :live_view
  use DroodotfooWeb.ContributionHelpers
  alias Droodotfoo.Resume.ResumeData
  alias DroodotfooWeb.SEO.JsonLD
  import DroodotfooWeb.ContentComponents
  import DroodotfooWeb.GithubComponents

  @impl true
  def mount(_params, _session, socket) do
    resume = ResumeData.get_resume_data()
    last_updated = ~D[2026-04-02]

    json_ld = [
      JsonLD.breadcrumb_schema([
        {"Home", "/"},
        {"Now", "/now"}
      ])
    ]

    if connected?(socket), do: DroodotfooWeb.ContributionHelpers.init_contributions()

    socket
    |> assign(:resume, resume)
    |> assign(:last_updated, last_updated)
    |> assign(:page_title, "Now")
    |> assign(:current_path, "/now")
    |> assign(:json_ld, json_ld)
    |> assign(DroodotfooWeb.ContributionHelpers.contribution_assigns())
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
        <.contribution_graph
          id="now-contributions"
          grid={@contribution_grid}
          loading={@contributions_loading}
        />

        <hr />

        <div class="text-muted mb-2">
          <strong>Last updated:</strong>
          {Date.to_string(@last_updated)}
        </div>

        <h3 class="mt-2">Running</h3>
        <p>
          Raising for
          <strong><a href="https://xochi.fi" target="_blank" rel="noopener">xochi.fi</a></strong>
          -- a private execution layer on Ethereum with ZK compliance.
          Running
          <strong><a href="https://axol.io" target="_blank" rel="noopener">axol.io</a></strong>
          infrastructure underneath.
        </p>

        <article class="experience-item">
          <div class="experience-header">
            <div class="experience-title">Riddler Solver</div>
            <div class="experience-company">Live on 5 chains</div>
          </div>

          <p class="experience-description">
            Intent solver filling orders in ~2s across Ethereum, Optimism, Base, Arbitrum, and Polygon.
            P95 under 6 seconds.
            <a
              href="https://github.com/lifinance/riddler-solver-client"
              target="_blank"
              rel="noopener"
            >
              Integrated by LI.FI
            </a>
            as a solver client. Also live on Across intents.
          </p>

          <div class="tech-tags mt-1">
            <span class="tech-tag">Ethereum</span>
            <span class="tech-tag">Optimism</span>
            <span class="tech-tag">Base</span>
            <span class="tech-tag">Arbitrum</span>
            <span class="tech-tag">Polygon</span>
          </div>
        </article>

        <article class="experience-item">
          <div class="experience-header">
            <div class="experience-title">Sequencers & Nodes</div>
            <div class="experience-company">Production</div>
          </div>

          <p class="experience-description">
            Aztec sequencer, validators on Ethereum mainnet.
            Sphinx trading system for MEV searcher strategy deployment.
          </p>

          <div class="tech-tags mt-1">
            <span class="tech-tag">Aztec</span>
            <span class="tech-tag">Ethereum</span>
            <span class="tech-tag">MEV</span>
            <span class="tech-tag">Sphinx</span>
          </div>
        </article>

        <p class="mt-2 text-muted">
          Also building FOSS: <strong>mana</strong>
          (Ethereum client), <strong>raxol</strong>
          (OTP-native terminal framework), and <strong>riddler</strong>
          (Xochi's intent solver).
          See <.link navigate={~p"/projects"}>projects</.link>.
        </p>

        <hr />

        <h3 class="mt-2">Learning</h3>
        <p>
          Deep in quant frameworks and MEV strategy deployment:
        </p>

        <details class="experience-details" open>
          <summary class="experience-summary">What I'm reading now →</summary>
          <div class="mt-1">
            <ul>
              <li>
                <strong>Quant trading frameworks</strong>
                - Solver rebalancing, cross-chain inventory management, execution optimization
              </li>
              <li>
                <strong>MEV searcher strategies</strong>
                - Arbitrage, liquidations, backrunning patterns via Sphinx
              </li>
              <li>
                <strong>ZK compliance systems</strong>
                - ZKSAR proof generation, sanctions screening oracles, provider weight tuning
              </li>
              <li>
                <strong>OTP source</strong>
                - gen_server internals, supervisor restart strategies, distributed Erlang
              </li>
              <li>
                <strong>Jido 2.0</strong>
                - BEAM-native agent framework, TEA for AI agents, signal-based coordination
              </li>
            </ul>
          </div>
        </details>

        <div class="tech-tags mt-1">
          <span class="tech-tag">MEV</span>
          <span class="tech-tag">Quant</span>
          <span class="tech-tag">Elixir</span>
          <span class="tech-tag">ZK</span>
          <span class="tech-tag">Sphinx</span>
          <span class="tech-tag">OTP</span>
        </div>

        <hr />

        <h3 class="mt-2">Location & Work</h3>
        <p>
          Based in <strong>{@resume.personal_info.location}</strong>
          (<time>{@resume.personal_info.timezone}</time>).
          Remote.
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
              Open to consulting on Cosmos SDK, Ethereum clients, and node operations.
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
          by Derek Sivers. Updated whenever my focus significantly shifts.
        </p>
      </section>
    </.page_layout>
    """
  end
end
