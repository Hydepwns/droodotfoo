defmodule DroodotfooWeb.ProjectsLive do
  @moduledoc """
  Projects showcase page.
  Displays portfolio and defense projects in monospace-web style.
  """

  use DroodotfooWeb, :live_view
  alias Droodotfoo.Projects
  import DroodotfooWeb.ContentComponents
  import DroodotfooWeb.ViewHelpers

  @impl true
  def mount(_params, _session, socket) do
    projects = Projects.all()

    socket
    |> assign(:projects, projects)
    |> assign(:page_title, "Projects")
    |> assign(:current_path, "/projects")
    |> then(&{:ok, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout page_title="Projects" page_description="Selected portfolio work and contributions" current_path={@current_path}>
      <div class="projects-grid">
        <%= for project <- @projects do %>
          <article class="project-card">
            <header>
              <h2 class="project-title">{project.name}</h2>
              <p class="text-muted">{project.description}</p>
            </header>

            <%= if project.highlights && length(project.highlights) > 0 do %>
              <details class="project-details">
                <summary class="project-summary">Details</summary>
                <div class="project-description">
                  <ul>
                    <%= for highlight <- project.highlights do %>
                      <li>{highlight}</li>
                    <% end %>
                  </ul>
                </div>
              </details>
            <% end %>

            <%= if project.topics && length(project.topics) > 0 do %>
              <div class="project-topics mt-1">
                <%= for topic <- project.topics do %>
                  <span class="topic-tag">{topic}</span>
                <% end %>
              </div>
            <% else %>
              <.tech_tags technologies={project.tech_stack || []} />
            <% end %>

            <footer class="project-footer mt-1">
              <div class="project-meta text-muted">
                <span>
                  {format_status(project.status)}
                </span>
                <%= if project.year do %>
                  <span> |  {project.year}</span>
                <% end %>
                <%= if project.github_url do %>
                  <span> | </span>
                  <a
                    href={project.github_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    aria-label="GitHub"
                    class="github-link"
                  >
                    <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
                      <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
                    </svg>
                  </a>
                <% end %>
              </div>
            </footer>
          </article>
        <% end %>
      </div>
    </.page_layout>
    """
  end

  # format_status helper now imported from ViewHelpers
end
