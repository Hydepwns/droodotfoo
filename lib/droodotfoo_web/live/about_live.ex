defmodule DroodotfooWeb.AboutLive do
  @moduledoc """
  About page with embedded work experience section.
  Simple monospace-web styled page following the-monospace-web principles.
  """

  use DroodotfooWeb, :live_view
  alias Droodotfoo.Resume.ResumeData
  alias DroodotfooWeb.SEO.JsonLD
  import DroodotfooWeb.ContentComponents
  @impl true
  def mount(_params, _session, socket) do
    resume = ResumeData.get_resume_data()
    languages = extract_languages(resume.experience)

    socket
    |> assign(:resume, resume)
    |> assign(:languages, languages)
    |> assign_page_meta(
      "About",
      "/about",
      breadcrumb_json_ld("About", "/about", [JsonLD.person_schema()])
    )
    |> then(&{:ok, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout
      page_title={@resume.personal_info.name}
      page_description={@resume.personal_info.title}
      current_path={@current_path}
    >
      <section class="about-section">
        <h2 class="section-title">About</h2>
        <p>
          Hey, I'm Drew. I spent my twenties in engine rooms, first as a merchant
          mariner, then aboard nuclear submarines. I maintained secondary systems on Virginia-class boats (everything from the toilet up to and not including the reactor), eventually
          moved into test engineering, and ended up doing R&D work unexpectedly.
        </p>
        <p class="mt-1">
          I got into crypto as a protocol specialist at <a
            href="https://explorer.rated.network/o/Blockdaemon?network=mainnet&timeWindow=1d&viewBy=operator&page=1&pageSize=15&idType=nodeOperator"
            target="_blank"
            rel="noopener"
          >Blockdaemon</a>,
          then as a contributor at <a
            href="https://defillama.com/protocol/lido"
            target="_blank"
            rel="noopener"
          >Lido DAO</a>.
          Two of the biggest staking operations. I figured
          out what I wanted to build and left to do it with people I
          trusted.
        </p>
        <p class="mt-1">
          Now I run <a href="https://xochi.fi" target="_blank" rel="noopener">xochi.fi</a>
          and <a href="https://axol.io" target="_blank" rel="noopener">axol.io</a>.
          Xochi (pronounced: 'So-Chee') is a private exchange on Ethereum, it's meant to be a more friendly dark pool experience you can use to trade without
          exposing your orders. ZK proofs handle compliance instead of handing over your data.

          I believe economic and digital privacy must be embedded as first class citizens in a product.

          Where others find dichotomy, axolotls combinate and collaborate.
          We wrote
          <a href="https://github.com/xochi-fi/erc-xochi-zkp" target="_blank" rel="noopener">an
            ERC/EIP</a>
          to formally define our approach. axol.io runs the infra underneath: staking, an ETH client, sequencers, Builder.
        </p>
        <p class="mt-1">
          I'm also building a Gundam. Not a metaphor.
          <a href="https://github.com/DROOdotFOO/raxol" target="_blank" rel="noopener">Raxol</a>
          is the terminal framework behind it. It started as a TUI project, but now it's the agent commerce layer for Xochi: wallets that can act on their own.
        </p>

        <%= if @languages != [] do %>
          <div class="mt-2">
            <h3>Stack</h3>
            <.tech_tags technologies={@languages} />
          </div>
        <% end %>
      </section>

      <hr />

      <section class="experience-section">
        <h2 class="section-title">Experience</h2>

        <%= for exp <- @resume.experience do %>
          <article class="experience-item">
            <div class="experience-header">
              <div class="experience-title">{exp.position}</div>
              <div class="experience-company">{exp.company}</div>
              <div class="experience-date">
                {format_date_range(exp.start_date, exp.end_date)}
              </div>
            </div>

            <%= if exp[:description] do %>
              <p class="experience-description">{exp.description}</p>
            <% end %>

            <%= if exp[:achievements] && length(exp.achievements) > 0 do %>
              <details class="experience-details">
                <summary class="experience-summary">
                  {length(exp.achievements)} key contributions
                </summary>
                <div class="mt-1">
                  <ul>
                    <%= for achievement <- exp.achievements do %>
                      <li>{achievement}</li>
                    <% end %>
                  </ul>
                </div>
              </details>
            <% end %>

            <%= if exp[:technologies] && map_size(exp.technologies) > 0 do %>
              <.tech_tags technologies={
                exp.technologies
                |> Map.values()
                |> List.flatten()
              } />
            <% end %>
          </article>
        <% end %>
      </section>

      <%= if @resume[:education] && length(@resume.education) > 0 do %>
        <hr />

        <section class="education-section">
          <h2 class="section-title">Education</h2>

          <%= for edu <- @resume.education do %>
            <article class="experience-item">
              <div class="experience-header">
                <div class="experience-title">
                  {edu.degree}
                  <%= if edu[:field] do %>
                    , {edu.field}
                  <% end %>
                  <%= if edu[:concentration] do %>
                    ({edu.concentration})
                  <% end %>
                </div>
                <div class="experience-company">{edu.institution}</div>
                <div class="experience-date">
                  <%= if edu[:start_date] && edu[:end_date] do %>
                    {format_date_range(edu.start_date, edu.end_date)}
                  <% end %>
                </div>
              </div>

              <%= if edu[:minor] do %>
                <p class="text-muted">Minor: {edu.minor}</p>
              <% end %>

              <%= if edu[:achievements] && map_size(edu.achievements) > 0 do %>
                <details class="experience-details">
                  <summary class="experience-summary">Achievements</summary>
                  <div class="mt-1">
                    <%= if edu.achievements[:leadership] && length(edu.achievements.leadership) > 0 do %>
                      <div class="mb-1">
                        <strong>Leadership:</strong>
                        <ul>
                          <%= for item <- edu.achievements.leadership do %>
                            <li>{item}</li>
                          <% end %>
                        </ul>
                      </div>
                    <% end %>

                    <%= if edu.achievements[:academic] && length(edu.achievements.academic) > 0 do %>
                      <div class="mb-1">
                        <strong>Academic:</strong>
                        <ul>
                          <%= for item <- edu.achievements.academic do %>
                            <li>{item}</li>
                          <% end %>
                        </ul>
                      </div>
                    <% end %>

                    <%= if edu.achievements[:athletics] && length(edu.achievements.athletics) > 0 do %>
                      <div class="mb-1">
                        <strong>Athletics:</strong>
                        <ul>
                          <%= for item <- edu.achievements.athletics do %>
                            <li>{item}</li>
                          <% end %>
                        </ul>
                      </div>
                    <% end %>
                  </div>
                </details>
              <% end %>
            </article>
          <% end %>
        </section>
      <% end %>

      <%= if @resume[:certifications] && length(@resume.certifications) > 0 do %>
        <hr />

        <section class="certifications-section">
          <h2 class="section-title">Certifications</h2>

          <div class="certifications-grid">
            <%= for cert <- @resume.certifications do %>
              <article class="certification-item">
                <div class="cert-name">{cert.name}</div>
                <div class="cert-issuer">{cert.issuer}</div>
                <%= if cert[:date] do %>
                  <div class="cert-date">{cert.date}</div>
                <% end %>
              </article>
            <% end %>
          </div>
        </section>
      <% end %>
    </.page_layout>
    """
  end
end
