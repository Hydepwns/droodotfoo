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
    last_updated = ~D[2026-04-25]

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
          <.ext_link href="https://xochi.fi" text="xochi.fi" />
          : private exchange & friendly dark pool on Ethereum, ZK proofs for compliance.
          <.ext_link href="https://axol.io" text="axol.io" />
          runs the infra. Raising. The open infrastructure side is funded through
          <.ext_link href="https://qf.giveth.io/project/axolio-xochifi" text="Giveth" />
          (Ethereum Security QF round, closes May 14).
        </p>

        <article class="experience-item">
          <div class="experience-header">
            <div class="experience-title">Riddler</div>
          </div>
          <p class="experience-description">
            Intent solver, ~2s fills across five chains. P95 under 6s.
            <.ext_link
              href="https://github.com/lifinance/riddler-solver-client"
              text="LI.FI integrated it"
            /> as a solver client. Also on Across, Everclear, soon Wormhole and COWswap.
          </p>

          <.tech_tags technologies={["Ethereum", "Optimism", "Base", "Arbitrum", "Polygon"]} />
        </article>

        <article class="experience-item">
          <div class="experience-header">
            <div class="experience-title">axol.io infra</div>
            <div class="experience-company">Production</div>
          </div>

          <p class="experience-description">
            Aztec sequencer, Ethereum validators, MEV searcher
            via Sphinx.
          </p>

          <.tech_tags technologies={["Aztec", "Ethereum", "Sphinx"]} />
        </article>

        <article class="experience-item">
          <div class="experience-header">
            <div class="experience-title">Raxol</div>
            <div class="experience-company">In progress</div>
          </div>

          <p class="experience-description">
            Terminal framework that grew payment rails. Agents can
            hold wallets and settle trades via x402/MPP.
          </p>

          <.tech_tags technologies={["Elixir", "OTP", "x402"]} />
        </article>

        <p class="mt-2 text-muted">
          Other FOSS: mana (Ethereum client), riddler (intent solver).
          See <.link navigate={~p"/projects"}>projects</.link>.
        </p>

        <hr />

        <h3 class="mt-2">Learning</h3>

        <details class="experience-details" open>
          <summary class="experience-summary">Current reading list</summary>
          <div class="mt-1">
            <ul>
              <li>
                MEV/HFT: searcher strategies, arb, liquidations,
                backrunning, latency
              </li>
              <li>
                Quant: solver rebalancing, cross-chain inventory,
                execution optimization
              </li>
              <li>
                Prediction markets: applying the quant work to
                Polymarket
              </li>
              <li>
                ZK compliance: ZKSAR proofs, sanctions screening,
                provider weight tuning
              </li>
              <li>
                OTP internals: gen_server, supervisor restarts,
                distributed Erlang
              </li>
            </ul>
          </div>
        </details>

        <hr />

        <h3 class="mt-2">Location</h3>
        <p>
          {@resume.personal_info.location} ({@resume.personal_info.timezone}). Remote.
        </p>

        <%= if @resume.availability == "open_to_consulting" do %>
          <p class="mt-1 text-muted">
            Open to consulting. Cosmos SDK, Ethereum clients, node ops. <.link navigate={~p"/about"}>Background</.link>.
          </p>
        <% end %>

        <hr />

        <p class="text-muted">
          This is a <.ext_link href="https://nownownow.com/about" text="/now page" />.
        </p>
      </section>
    </.page_layout>
    """
  end
end
