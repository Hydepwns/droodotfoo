defmodule DroodotfooWeb.AboutLive do
  @moduledoc """
  About page with embedded work experience section.
  Simple monospace-web styled page following the-monospace-web principles.
  """

  use DroodotfooWeb, :live_view
  alias Droodotfoo.Resume.ResumeData
  import DroodotfooWeb.ContentComponents
  import DroodotfooWeb.ViewHelpers

  @impl true
  def mount(_params, _session, socket) do
    resume = ResumeData.get_resume_data()

    socket
    |> assign(:resume, resume)
    |> assign(:page_title, "About")
    |> then(&{:ok, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout
      page_title={@resume.personal_info.name}
      page_description={@resume.personal_info.title}
    >
      <section class="about-section">
        <h2 class="section-title">About</h2>
        <p>{@resume.summary}</p>

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

      <hr class="section-divider" />

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

            <%= if exp[:summary] do %>
              <p class="experience-description">{exp.summary}</p>
            <% end %>

            <%= if exp[:achievements] && length(exp.achievements) > 0 do %>
              <div class="mt-1">
                <strong>Key Achievements:</strong>
                <ul>
                  <%= for achievement <- exp.achievements do %>
                    <li>{achievement}</li>
                  <% end %>
                </ul>
              </div>
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
        <hr class="section-divider" />

        <section class="education-section">
          <h2 class="section-title">Education</h2>

          <%= for edu <- @resume.education do %>
            <article class="mb-2">
              <div class="experience-title">{edu.degree}</div>
              <div class="experience-company">{edu.institution}</div>
              <div class="experience-date">
                <%= if edu[:graduation_year] do %>
                  {edu.graduation_year}
                <% end %>
              </div>
            </article>
          <% end %>
        </section>
      <% end %>
    </.page_layout>
    """
  end

  # format_date_range helper now imported from ViewHelpers
end
