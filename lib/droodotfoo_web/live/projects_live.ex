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
    |> then(&{:ok, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout page_title="Projects" page_description="Selected portfolio work and contributions">
      <div class="projects-grid">
        <%= for project <- @projects do %>
          <article class="project-card">
            <header>
              <h2 class="project-title">{project.name}</h2>
              <%= if project.tagline do %>
                <p class="text-muted">{project.tagline}</p>
              <% end %>
            </header>

            <div class="project-description">
              <p>{project.description}</p>

              <%= if project.highlights && length(project.highlights) > 0 do %>
                <ul>
                  <%= for highlight <- project.highlights do %>
                    <li>{highlight}</li>
                  <% end %>
                </ul>
              <% end %>
            </div>

            <.tech_tags technologies={project.tech_stack || []} />

            <footer class="project-footer mt-1">
              <div class="project-meta text-muted">
                <span>
                  {format_status(project.status)}
                </span>
                <%= if project.year do %>
                  <span> |  {project.year}</span>
                <% end %>
              </div>

              <div class="project-links mt-1">
                <%= if project.github_url do %>
                  <a href={project.github_url} target="_blank" rel="noopener noreferrer">
                    [Github]
                  </a>
                <% end %>
                <%= if project.demo_url do %>
                  <a href={project.demo_url} target="_blank" rel="noopener noreferrer">
                    [Live Demo]
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
