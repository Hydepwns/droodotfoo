defmodule DroodotfooWeb.Git.CommitsLive do
  @moduledoc """
  Commit history page with pagination.
  Supports both GitHub and Forgejo sources.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Git.Layouts
  alias Droodotfoo.Git

  @page_size 30

  @impl true
  def mount(params, _session, socket) do
    source = parse_source(params["source"])
    owner = params["owner"]
    repo = params["repo"]
    branch = params["branch"]

    if connected?(socket), do: send(self(), :load_commits)

    {:ok,
     assign(socket,
       source: source,
       owner: owner,
       repo: repo,
       branch: branch,
       commits: [],
       page: 1,
       has_more: false,
       loading: true,
       loading_more: false,
       error: nil,
       page_title: "Commits - #{repo}",
       current_path: "/#{source}/#{owner}/#{repo}/commits/#{branch}"
     )}
  end

  defp parse_source("github"), do: :github
  defp parse_source("forgejo"), do: :forgejo
  defp parse_source(_), do: :github

  @impl true
  def handle_info(:load_commits, socket) do
    %{source: source, owner: owner, repo: repo, branch: branch} = socket.assigns

    case Git.get_commits(source, owner, repo, branch, limit: @page_size + 1) do
      {:ok, commits} ->
        has_more = length(commits) > @page_size
        commits = Enum.take(commits, @page_size)
        {:noreply, assign(socket, commits: commits, has_more: has_more, loading: false)}

      {:error, reason} ->
        {:noreply, assign(socket, error: inspect(reason), loading: false)}
    end
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    %{source: source, owner: owner, repo: repo, branch: branch, page: page, commits: commits} =
      socket.assigns

    next_page = page + 1
    socket = assign(socket, loading_more: true)

    case Git.get_commits(source, owner, repo, branch, limit: @page_size + 1, page: next_page) do
      {:ok, new_commits} ->
        has_more = length(new_commits) > @page_size
        new_commits = Enum.take(new_commits, @page_size)

        {:noreply,
         assign(socket,
           commits: commits ++ new_commits,
           page: next_page,
           has_more: has_more,
           loading_more: false
         )}

      {:error, _reason} ->
        {:noreply, assign(socket, loading_more: false)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <section class="section-spaced">
        <h2 class="section-header-bordered">
          <.link navigate="/" class="text-muted-alt">{"[<-]"}</.link>
          <span class={source_class(@source)}>{@source}</span>
          <.link navigate={"/#{@source}/#{@owner}/#{@repo}"} class="hover:underline">
            /{@repo}
          </.link>
          / COMMITS / {@branch}
        </h2>

        <div :if={@loading} class="loading">
          Loading commits...
        </div>

        <div :if={@error} class="text-error">
          Error: {@error}
        </div>

        <div :if={!@loading && !@error}>
          <.commits_table commits={@commits} />

          <div :if={@has_more} class="mt-4 text-center">
            <button
              phx-click="load_more"
              disabled={@loading_more}
              class="btn"
            >
              {if @loading_more, do: "Loading...", else: "[Load More]"}
            </button>
          </div>

          <p :if={@commits == []} class="text-muted-alt">
            No commits found.
          </p>
        </div>
      </section>
    </Layouts.app>
    """
  end

  defp commits_table(assigns) do
    ~H"""
    <table class="w-full font-mono text-sm">
      <thead class="text-left text-muted border-b border-muted">
        <tr>
          <th class="py-2 pr-4 w-20">SHA</th>
          <th class="py-2 pr-4">Message</th>
          <th class="py-2 pr-4 w-32">Author</th>
          <th class="py-2 w-28 text-right">Date</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={commit <- @commits} class="border-b border-muted hover:bg-alt">
          <td class="py-2 pr-4">
            <code class="text-accent">{commit.short_sha}</code>
          </td>
          <td class="py-2 pr-4">
            <span class="block truncate max-w-lg" title={commit.message}>
              {first_line(commit.message)}
            </span>
          </td>
          <td class="py-2 pr-4 text-muted">
            {commit.author}
          </td>
          <td class="py-2 text-right text-muted">
            {format_date(commit.date)}
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  defp source_class(:github), do: "text-xs px-1.5 py-0.5 bg-blue-900 text-blue-200 mr-1"
  defp source_class(:forgejo), do: "text-xs px-1.5 py-0.5 bg-purple-900 text-purple-200 mr-1"
  defp source_class(_), do: ""

  defp first_line(message) do
    message
    |> String.split("\n", parts: 2)
    |> List.first()
    |> String.slice(0, 80)
  end

  defp format_date(nil), do: "-"

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
