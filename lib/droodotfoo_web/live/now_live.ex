defmodule DroodotfooWeb.NowLive do
  @moduledoc """
  Now page showing current focus and activities.
  Inspired by Derek Sivers' /now page movement (nownownow.com).
  Updated manually to reflect current status.
  """

  use DroodotfooWeb, :live_view
  use DroodotfooWeb.ContributionHelpers
  alias Droodotfoo.Resume.ResumeData
  import DroodotfooWeb.ContentComponents
  import DroodotfooWeb.GithubComponents

  @impl true
  def mount(_params, _session, socket) do
    resume = ResumeData.get_resume_data()
    last_updated = ~D[2026-04-11]

    if connected?(socket), do: DroodotfooWeb.ContributionHelpers.init_contributions()

    socket
    |> assign(:resume, resume)
    |> assign(:last_updated, last_updated)
    |> assign_page_meta("Now", "/now", breadcrumb_json_ld("Now", "/now"))
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
          Launching
          <strong><a href="https://xochi.fi" target="_blank" rel="noopener">xochi.fi</a></strong>
          -- a private execution layer on Ethereum with ZK compliance.
          Looking for a VC to lead the round.
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

          <.tech_tags technologies={["Ethereum", "Optimism", "Base", "Arbitrum", "Polygon"]} />
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

          <.tech_tags technologies={["Aztec", "Ethereum", "MEV", "Sphinx"]} />
        </article>

        <article class="experience-item">
          <div class="experience-header">
            <div class="experience-title">Raxol Agentic Commerce</div>
            <div class="experience-company">Launched</div>
          </div>

          <p class="experience-description">
            Agent-to-agent payments via x402 and MPP.
            OTP-native terminal framework with built-in payment rails for AI agents.
          </p>

          <.tech_tags technologies={["x402", "MPP", "Elixir", "OTP"]} />
        </article>

        <p class="mt-2 text-muted">
          Also building FOSS: <strong>mana</strong>
          (Ethereum client), <strong>riddler</strong>
          (Xochi's intent solver).
          See <.link navigate={~p"/projects"}>projects</.link>.
        </p>

        <hr />

        <h3 class="mt-2">Learning</h3>
        <p>
          Deep in MEV, HFT, and applied math for on-chain markets:
        </p>

        <details class="experience-details" open>
          <summary class="experience-summary">What I'm studying now →</summary>
          <div class="mt-1">
            <ul>
              <li>
                <strong>MEV and HFT</strong>
                - Searcher strategies, arbitrage, liquidations, backrunning via Sphinx, latency optimization
              </li>
              <li>
                <strong>Quant frameworks</strong>
                - Solver rebalancing, cross-chain inventory management, execution optimization
              </li>
              <li>
                <strong>Prediction markets</strong>
                - Applying quant math to Polymarket alongside the MEV searcher
              </li>
              <li>
                <strong>ZK compliance systems</strong>
                - ZKSAR proof generation, sanctions screening oracles, provider weight tuning
              </li>
              <li>
                <strong>OTP source</strong>
                - gen_server internals, supervisor restart strategies, distributed Erlang
              </li>
            </ul>
          </div>
        </details>

        <.tech_tags technologies={[
          "MEV",
          "HFT",
          "Quant",
          "Polymarket",
          "Elixir",
          "ZK",
          "Sphinx",
          "OTP"
        ]} />

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
            <.tech_tags technologies={@resume.focus_areas} />
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
