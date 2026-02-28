defmodule DroodotfooWeb.Git.RepoListLive do
  @moduledoc """
  Repository list page for git.droo.foo.
  Shows repos from GitHub and/or Forgejo with source filtering.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Git.Layouts
  alias Droodotfoo.Git

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: send(self(), :load_repos)

    {:ok,
     assign(socket,
       repos: [],
       source_filter: :all,
       sources: Git.sources(),
       loading: true,
       error: nil,
       comparison: nil,
       page_title: "REPOSITORIES",
       current_path: "/"
     )}
  end

  @impl true
  def handle_info(:load_repos, socket) do
    source = socket.assigns.source_filter

    case Git.list_repos(source: source) do
      {:ok, repos} ->
        repos = Enum.sort_by(repos, & &1.updated_at, :desc)
        {:noreply, assign(socket, repos: repos, loading: false)}

      {:error, reason} ->
        {:noreply, assign(socket, error: inspect(reason), loading: false)}
    end
  end

  @impl true
  def handle_event("filter", %{"source" => source}, socket) do
    source_atom =
      case source do
        "all" -> :all
        "github" -> :github
        "forgejo" -> :forgejo
        _ -> :all
      end

    socket = assign(socket, source_filter: source_atom, loading: true)
    send(self(), :load_repos)
    {:noreply, socket}
  end

  def handle_event("compare", _params, socket) do
    case Git.compare_repos() do
      {:ok, comparison} ->
        {:noreply, assign(socket, comparison: comparison)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to compare repos")}
    end
  end

  def handle_event("close_comparison", _params, socket) do
    {:noreply, assign(socket, comparison: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <section class="section-spaced">
        <h2 class="section-header-bordered">
          REPOSITORIES
        </h2>

        <div class="flex items-center justify-between mb-4">
          <div class="flex gap-2">
            <button
              :for={{key, config} <- @sources}
              :if={config.enabled}
              phx-click="filter"
              phx-value-source={key}
              class={[
                "btn text-sm",
                @source_filter == key && "bg-accent"
              ]}
            >
              {config.name}
            </button>
            <button
              phx-click="filter"
              phx-value-source="all"
              class={["btn text-sm", @source_filter == :all && "bg-accent"]}
            >
              All
            </button>
          </div>
          <button phx-click="compare" class="btn text-sm">
            [Compare Sources]
          </button>
        </div>

        <.comparison_modal :if={@comparison} comparison={@comparison} />

        <div :if={@loading} class="loading">
          Loading repositories...
        </div>

        <div :if={@error} class="text-error">
          Error: {@error}
        </div>

        <div :if={!@loading && !@error} class="space-y-4">
          <.repo_card :for={repo <- @repos} repo={repo} />
        </div>

        <p :if={!@loading && @repos == []} class="text-muted-alt">
          No repositories found.
        </p>
      </section>
    </Layouts.app>
    """
  end

  defp comparison_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black/80 flex items-center justify-center z-50">
      <div class="bg-alt border border-muted p-6 max-w-2xl w-full mx-4 max-h-[80vh] overflow-y-auto">
        <div class="flex justify-between items-start mb-4">
          <h3 class="text-lg font-bold">Source Comparison</h3>
          <button phx-click="close_comparison" class="text-muted hover:text-white">[x]</button>
        </div>

        <div class="grid grid-cols-2 gap-4 mb-4 text-sm">
          <div class="border border-muted p-3">
            <div class="text-muted-alt mb-1">GitHub</div>
            <div class="text-2xl font-bold">{@comparison.github_total}</div>
          </div>
          <div class="border border-muted p-3">
            <div class="text-muted-alt mb-1">Forgejo</div>
            <div class="text-2xl font-bold">{@comparison.forgejo_total}</div>
          </div>
        </div>

        <div class="space-y-4 text-sm">
          <div>
            <h4 class="text-muted-alt mb-2">Mirrored ({length(@comparison.mirrored)})</h4>
            <div class="flex flex-wrap gap-1">
              <span
                :for={name <- @comparison.mirrored}
                class="px-2 py-0.5 bg-green-900 text-green-200"
              >
                {name}
              </span>
              <span :if={@comparison.mirrored == []} class="text-muted">None</span>
            </div>
          </div>

          <div>
            <h4 class="text-muted-alt mb-2">Only on GitHub ({length(@comparison.only_github)})</h4>
            <div class="flex flex-wrap gap-1">
              <span
                :for={name <- @comparison.only_github}
                class="px-2 py-0.5 bg-blue-900 text-blue-200"
              >
                {name}
              </span>
              <span :if={@comparison.only_github == []} class="text-muted">None</span>
            </div>
          </div>

          <div>
            <h4 class="text-muted-alt mb-2">Only on Forgejo ({length(@comparison.only_forgejo)})</h4>
            <div class="flex flex-wrap gap-1">
              <span
                :for={name <- @comparison.only_forgejo}
                class="px-2 py-0.5 bg-purple-900 text-purple-200"
              >
                {name}
              </span>
              <span :if={@comparison.only_forgejo == []} class="text-muted">None</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp repo_card(assigns) do
    ~H"""
    <article class="border border-muted p-4 hover:bg-alt">
      <div class="flex items-start justify-between">
        <div class="flex-1">
          <h3 class="font-bold">
            <.link navigate={"/#{@repo.source}/#{@repo.full_name}"} class="link-reset hover:underline">
              /{@repo.name}
            </.link>
            <span class={[
              "text-xs ml-2 px-1.5 py-0.5",
              @repo.source == :github && "bg-blue-900 text-blue-200",
              @repo.source == :forgejo && "bg-purple-900 text-purple-200"
            ]}>
              {@repo.source}
            </span>
            <span :if={@repo.private} class="text-muted-alt text-sm">[private]</span>
            <span :if={@repo.archived} class="text-muted-alt text-sm">[archived]</span>
          </h3>
          <p :if={@repo.description} class="text-muted-alt mt-1">
            {@repo.description}
          </p>
        </div>
        <div class="text-sm text-muted-alt text-right">
          <div :if={@repo.language}>{@repo.language}</div>
          <div class="flex gap-4 mt-1">
            <span :if={@repo.stars > 0}>* {@repo.stars}</span>
            <span :if={@repo.forks > 0}>Y {@repo.forks}</span>
          </div>
        </div>
      </div>
      <p class="text-sm text-muted mt-2">
        Updated {format_date(@repo.updated_at)}
      </p>
    </article>
    """
  end

  defp format_date(nil), do: "unknown"

  defp format_date(datetime_str) when is_binary(datetime_str) do
    case DateTime.from_iso8601(datetime_str) do
      {:ok, datetime, _} -> format_relative(datetime)
      _ -> datetime_str
    end
  end

  defp format_relative(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      true -> Calendar.strftime(datetime, "%Y-%m-%d")
    end
  end
end
