defmodule DroodotfooWeb.AboutLive do
  @moduledoc """
  About page with embedded work experience section.
  Simple monospace-web styled page following the-monospace-web principles.
  """

  use DroodotfooWeb, :live_view
  alias Droodotfoo.Resume.ResumeData
  alias DroodotfooWeb.SEO.JsonLD
  import DroodotfooWeb.ContentComponents
  import DroodotfooWeb.ViewHelpers

  @impl true
  def mount(_params, _session, socket) do
    resume = ResumeData.get_resume_data()

    # Generate JSON-LD schemas for about page
    json_ld = [
      JsonLD.person_schema(),
      JsonLD.breadcrumb_schema([
        {"Home", "/"},
        {"About", "/about"}
      ])
    ]

    socket
    |> assign(:resume, resume)
    |> assign(:page_title, "About")
    |> assign(:current_path, "/about")
    |> assign(:json_ld, json_ld)
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
          I build blockchain infrastructure at axol.io. Before that, defense systems
          where uptime requirements were strict and bugs had operational consequences.
          Before that, startups where shipping broken code and fixing it fast was the norm.
        </p>

        <h3 class="mt-2">What I've learned</h3>
        <p>
          Startups taught me to ship fast and iterate. Defense taught me to make things
          not break. Blockchain requires both: move quickly, but bugs are expensive and
          immutable. No rollback makes you careful about what "done" means.
        </p>

        <p class="mt-2">{@resume.summary}</p>

        <%= if @resume[:focus_areas] && length(@resume.focus_areas) > 0 do %>
          <div class="mt-2">
            <h3>Focus Areas</h3>
            <ul>
              <%= for area <- @resume.focus_areas do %>
                <li>{area}</li>
              <% end %>
            </ul>
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
                <summary class="experience-summary">Details</summary>
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

  # format_date_range helper now imported from ViewHelpers
end
