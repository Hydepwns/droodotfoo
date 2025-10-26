defmodule DroodotfooWeb.ProjectsLive do
  @moduledoc "Projects showcase page"

  use DroodotfooWeb, :live_view
  alias Droodotfoo.{Projects, GitHub}
  alias Droodotfoo.GitHub.LanguageColors
  alias DroodotfooWeb.SEO.JsonLD
  import DroodotfooWeb.{ContentComponents, ViewHelpers}

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
      send(self(), :enrich_github_data)
    end

    {:ok,
     assign(socket,
       projects: projects,
       page_title: "Projects",
       current_path: "/projects",
       json_ld: json_ld,
       loading_github: true
     )}
  end

  @impl true
  def handle_info(:enrich_github_data, socket) do
    # Fetch GitHub data in background
    enriched_projects = Projects.with_github_data()

    # Update JSON-LD with enriched project data
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
  def handle_event("refresh_github_data", %{"github_url" => url}, socket) do
    with {:ok, {owner, repo}} <- GitHub.Client.parse_github_url(url) do
      GitHub.force_refresh(owner, repo)
      {:noreply, assign(socket, :projects, Projects.with_github_data())}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout
      page_title="Projects"
      page_description="Open source work and contributions"
      current_path={@current_path}
    >
      <div class="projects-grid">
        <article :for={project <- @projects} class="project-card">
          <div class="project-content-grid">
            <div class="project-left">
              <h2 class="project-title">{project.name}</h2>
              <p class="text-muted project-description-text">{project.description}</p>

              <details :if={project.highlights != []} class="project-details">
                <summary class="project-summary">Details</summary>
                <div class="project-description">
                  <ul>
                    <li :for={highlight <- project.highlights}>{highlight}</li>
                  </ul>
                </div>
              </details>

              <div class="mt-1">
                <%= if project.topics != [] do %>
                  <div class="project-topics">
                    <span :for={topic <- project.topics} class="topic-tag">{topic}</span>
                  </div>
                <% else %>
                  <.tech_tags technologies={project.tech_stack || []} />
                <% end %>
              </div>
            </div>

            <div class="project-right">
              <.github_stats project={project} />
            </div>
          </div>
        </article>
      </div>
    </.page_layout>
    """
  end

  defp github_stats(%{project: %{github_data: %{status: :ok}}} = assigns) do
    ~H"""
    <div :if={@project.github_data.languages} class="language-breakdown">
      <div
        :for={{lang, pct} <- format_language_bars(@project.github_data.languages)}
        class="language-bar"
      >
        <span class="lang-name">{lang}</span>
        <span class="lang-bar-fill" style={"color: #{LanguageColors.get_color(lang)}"}>
          {String.duplicate("█", percentage_to_bars(pct))}
        </span>
        <span class="lang-percentage">{pct}%</span>
      </div>
    </div>

    <div :if={repo = @project.github_data.repo_info} class="github-meta text-muted mt-1">
      ★ {repo.stars} ⑂ {repo.forks}
      <span :if={repo.updated_at}> | Updated  {format_time_ago(repo.updated_at)}</span>
    </div>

    <div :if={commit = @project.github_data.latest_commit} class="latest-commit text-muted">
      Latest: {commit.message} ({format_time_ago(commit.date)})
    </div>

    <div :if={cached = @project.github_data.cached_at} class="cache-timestamp text-muted">
      <small>Cached {format_cached_time(cached)}</small>
    </div>

    <a
      :if={@project.github_url}
      href={@project.github_url}
      target="_blank"
      rel="noopener noreferrer"
      class="github-link mt-1"
    >
      GitHub →
    </a>
    """
  end

  defp github_stats(%{project: %{github_data: %{status: :loading}}} = assigns) do
    ~H"""
    <div class="github-loading">
      <div class="loading-skeleton"></div>
      <div class="loading-skeleton"></div>
      <div class="loading-skeleton"></div>
    </div>
    """
  end

  defp github_stats(%{project: %{github_data: %{status: status}}} = assigns)
       when status in [:unauthorized, :not_found, :rate_limited, :error] do
    can_retry = status in [:not_found, :rate_limited, :error]
    has_url = !is_nil(assigns.project.github_url)
    assigns = assign(assigns, :show_retry, can_retry && has_url)

    ~H"""
    <div class="github-error text-muted">
      <span>{error_message(@project.github_data.status)}</span>
      <button
        :if={@show_retry}
        phx-click="refresh_github_data"
        phx-value-github_url={@project.github_url}
        class="refresh-button"
      >
        Retry →
      </button>
    </div>
    """
  end

  defp github_stats(assigns) do
    ~H"""
    <div class="project-meta text-muted">
      <span>{format_status(@project.status)}</span>
      <span :if={@project.year}> |  {@project.year}</span>
    </div>
    """
  end

  defp error_message(:unauthorized), do: "[Private - stats unavailable]"
  defp error_message(:not_found), do: "[Repository not found]"
  defp error_message(:rate_limited), do: "[Rate limited - refreshes hourly]"
  defp error_message(:error), do: "[GitHub data unavailable]"

  defp format_time_ago(datetime) when is_binary(datetime) do
    with {:ok, dt, _} <- DateTime.from_iso8601(datetime) do
      DateTime.utc_now() |> DateTime.diff(dt) |> format_duration()
    else
      _ -> "recently"
    end
  end

  defp format_time_ago(_), do: "recently"

  defp format_cached_time(ms) when is_integer(ms) do
    (System.system_time(:millisecond) - ms) |> div(1000) |> format_duration()
  end

  defp format_cached_time(_), do: "recently"

  defp format_duration(s) when s < 60, do: "just now"
  defp format_duration(s) when s < 3600, do: "#{div(s, 60)}m ago"
  defp format_duration(s) when s < 86400, do: "#{div(s, 3600)}h ago"
  defp format_duration(s) when s < 2_592_000, do: "#{div(s, 86400)}d ago"
  defp format_duration(s) when s < 31_536_000, do: "#{div(s, 2_592_000)}mo ago"
  defp format_duration(s), do: "#{div(s, 31_536_000)}y ago"

  defp format_language_bars(langs) when is_map(langs) do
    total = langs |> Map.values() |> Enum.sum()

    if total > 0 do
      langs
      |> Enum.sort_by(fn {_, bytes} -> -bytes end)
      |> Enum.take(3)
      |> Enum.map(fn {lang, bytes} -> {lang, Float.round(bytes / total * 100, 1)} end)
    else
      []
    end
  end

  defp format_language_bars(_), do: []

  defp percentage_to_bars(pct), do: max(1, round(pct / 5))
end
