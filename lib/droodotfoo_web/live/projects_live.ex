defmodule DroodotfooWeb.ProjectsLive do
  @moduledoc "Projects showcase page"

  use DroodotfooWeb, :live_view
  use DroodotfooWeb.ContributionHelpers
  alias Droodotfoo.GitHub.LanguageColors
  alias Droodotfoo.{Projects, Zed}
  alias DroodotfooWeb.SEO.JsonLD
  import DroodotfooWeb.{ContentComponents, GithubComponents}

  @impl true
  def mount(_params, _session, socket) do
    # Phase 1: Load basic project data immediately (no GitHub API calls)
    projects = Projects.all()

    # Generate JSON-LD (will be updated after GitHub data loads)
    json_ld = [
      JsonLD.breadcrumb_schema([{"Home", "/"}, {"Projects", "/projects"}])
      | Enum.map(projects, &JsonLD.software_schema/1)
    ]

    # Phase 2: Enrich with GitHub data asynchronously after connection
    if connected?(socket) do
      DroodotfooWeb.ContributionHelpers.init_contributions()
      send(self(), :enrich_github_data)
    end

    {:ok,
     socket
     |> assign(
       projects: projects,
       page_title: "Projects",
       current_path: "/projects",
       json_ld: json_ld,
       loading_github: true
     )
     |> assign(DroodotfooWeb.ContributionHelpers.contribution_assigns())}
  end

  @impl true
  def handle_info(:enrich_github_data, socket) do
    enriched_projects =
      Projects.with_github_data()
      |> enrich_zed_downloads()

    json_ld = [
      JsonLD.breadcrumb_schema([{"Home", "/"}, {"Projects", "/projects"}])
      | Enum.map(enriched_projects, &JsonLD.software_schema/1)
    ]

    {:noreply,
     assign(socket,
       projects: enriched_projects,
       json_ld: json_ld,
       loading_github: false
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout
      page_title="Projects"
      page_description="What I'm building and maintaining"
      current_path={@current_path}
    >
      <.contribution_graph
        id="projects-contributions"
        grid={@contribution_grid}
        loading={@contributions_loading}
      />

      <div class="projects-grid">
        <%= for project <- @projects do %>
          <.project_card project={project} />
        <% end %>
      </div>
    </.page_layout>
    """
  end

  defp project_card(%{project: project} = assigns) do
    {stars, lang, updated} = extract_github_meta(project)

    assigns =
      assigns
      |> assign(:stars, stars)
      |> assign(:lang, lang)
      |> assign(:lang_color, LanguageColors.get_color(lang))
      |> assign(:updated, updated)
      |> assign(:status_info, status_info(project.status))

    ~H"""
    <article class="project-card" id={@project.id}>
      <header class="project-card-header">
        <div class="project-title-row">
          <h3 class="project-name">
            <a
              :if={@project.github_url}
              href={@project.github_url}
              target="_blank"
              rel="noopener noreferrer"
            >
              {@project.name}
            </a>
            <span :if={!@project.github_url}>{@project.name}</span>
          </h3>
          <span class={"project-status #{@status_info.class}"}>{@status_info.label}</span>
        </div>

        <div class="project-meta">
          <span class="project-lang">
            <span class="lang-dot" style={"background: #{@lang_color}"}></span>
            {@lang}
          </span>
          <span :if={@stars != "-" && @stars != "..."} class="project-stars">
            * {@stars}
          </span>
          <span :if={@updated != "-" && @updated != "..."} class="project-updated">
            updated {@updated}
          </span>
        </div>
      </header>

      <p class="project-description">{@project.description}</p>

      <footer :if={length(@project.tech_stack) > 1} class="project-tech">
        <span :for={tech <- Enum.take(@project.tech_stack, 5)} class="tech-tag">
          {tech}
        </span>
      </footer>
    </article>
    """
  end

  # Zed extension IDs mapped to project names
  @zed_extensions %{"synthwave84_zed" => "synthwave84"}

  defp enrich_zed_downloads(projects) do
    Enum.map(projects, fn project ->
      case Map.get(@zed_extensions, project.id) do
        nil ->
          project

        ext_id ->
          case Zed.download_count(ext_id) do
            {:ok, count} ->
              desc = "#{project.description} (#{Zed.format_count(count)} installs)"
              %{project | description: desc}

            _ ->
              project
          end
      end
    end)
  end

  defp extract_github_meta(%{github_data: %{status: :ok}} = project) do
    stars =
      case project.github_data.repo_info do
        %{stars: s} -> to_string(s)
        _ -> "-"
      end

    lang = primary_language(project)

    updated =
      case project.github_data.latest_commit do
        %{date: date} -> format_time_ago(date)
        _ -> "-"
      end

    {stars, lang, updated}
  end

  defp extract_github_meta(%{github_data: %{status: :loading}} = project) do
    {"...", primary_language(project), "..."}
  end

  defp extract_github_meta(project) do
    {"-", primary_language(project), "-"}
  end

  defp primary_language(%{github_data: %{status: :ok, languages: langs}}) when is_map(langs) do
    case Enum.sort_by(langs, fn {_, bytes} -> -bytes end) do
      [{lang, _} | _] -> lang
      _ -> "-"
    end
  end

  defp primary_language(%{tech_stack: [lang | _]}), do: lang
  defp primary_language(_), do: "-"

  defp status_info(:active), do: %{label: "active", class: "status-active"}
  defp status_info(:completed), do: %{label: "done", class: "status-done"}
  defp status_info(:archived), do: %{label: "archived", class: "status-archived"}

  defp format_time_ago(datetime) when is_binary(datetime) do
    case DateTime.from_iso8601(datetime) do
      {:ok, dt, _} -> DateTime.utc_now() |> DateTime.diff(dt) |> format_duration()
      _ -> "-"
    end
  end

  defp format_time_ago(_), do: "-"

  defp format_duration(s) when s < 60, do: "now"
  defp format_duration(s) when s < 3600, do: "#{div(s, 60)}m"
  defp format_duration(s) when s < 86_400, do: "#{div(s, 3600)}h"
  defp format_duration(s) when s < 2_592_000, do: "#{div(s, 86_400)}d"
  defp format_duration(s) when s < 31_536_000, do: "#{div(s, 2_592_000)}mo"
  defp format_duration(s), do: "#{div(s, 31_536_000)}y"
end
