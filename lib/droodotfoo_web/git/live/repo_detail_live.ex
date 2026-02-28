defmodule DroodotfooWeb.Git.RepoDetailLive do
  @moduledoc """
  Repository detail page showing files and metadata.
  Supports both GitHub and Forgejo sources.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Git.Layouts
  alias Droodotfoo.Git

  @impl true
  def mount(%{"source" => source, "owner" => owner, "repo" => repo_name}, _session, socket) do
    source_atom = parse_source(source)

    if connected?(socket), do: send(self(), :load_repo)

    {:ok,
     assign(socket,
       source: source_atom,
       owner: owner,
       repo_name: repo_name,
       repo: nil,
       tree: [],
       branches: [],
       loading: true,
       error: nil,
       page_title: "/#{repo_name}",
       current_path: "/#{source}/#{owner}/#{repo_name}"
     )}
  end

  defp parse_source("github"), do: :github
  defp parse_source("forgejo"), do: :forgejo
  defp parse_source(_), do: :github

  @impl true
  def handle_info(:load_repo, socket) do
    %{source: source, owner: owner, repo_name: repo_name} = socket.assigns

    with {:ok, repo} <- Git.get_repo(source, owner, repo_name),
         {:ok, tree} <- Git.get_tree(source, owner, repo_name, repo.default_branch),
         {:ok, branches} <- Git.list_branches(source, owner, repo_name) do
      {:noreply,
       assign(socket,
         repo: repo,
         tree: sort_tree(tree),
         branches: branches,
         loading: false
       )}
    else
      {:error, :not_found} ->
        {:noreply, assign(socket, error: "Repository not found", loading: false)}

      {:error, reason} ->
        {:noreply, assign(socket, error: inspect(reason), loading: false)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <section class="section-spaced">
        <h2 class="section-header-bordered">
          <.link navigate="/" class="text-muted-alt">{"[<-]"}</.link>
          <span class={source_class(@source)}>{@source}</span> /{@repo_name}
        </h2>

        <div :if={@loading} class="loading">
          Loading repository...
        </div>

        <div :if={@error} class="text-error">
          Error: {@error}
        </div>

        <div :if={!@loading && @repo}>
          <div class="mb-6">
            <p :if={@repo.description} class="text-muted-alt mb-2">
              {@repo.description}
            </p>
            <div class="flex gap-6 text-sm text-muted">
              <span :if={@repo.language}>{@repo.language}</span>
              <span>* {@repo.stars} stars</span>
              <span>Y {@repo.forks} forks</span>
              <span>Branch: {@repo.default_branch}</span>
            </div>
          </div>

          <div class="flex gap-4 mb-6">
            <.link
              navigate={"/#{@source}/#{@owner}/#{@repo_name}/tree/#{@repo.default_branch}"}
              class="btn"
            >
              [Browse Files]
            </.link>
            <.link
              navigate={"/#{@source}/#{@owner}/#{@repo_name}/commits/#{@repo.default_branch}"}
              class="btn"
            >
              [Commits]
            </.link>
            <a href={@repo.clone_url} class="btn" target="_blank">
              [Clone URL]
            </a>
            <a href={@repo.html_url} class="btn" target="_blank">
              [View on {@source}]
            </a>
          </div>

          <h3 class="section-header-bordered">FILES</h3>
          <.tree_listing
            tree={@tree}
            source={@source}
            owner={@owner}
            repo={@repo_name}
            branch={@repo.default_branch}
          />
        </div>
      </section>
    </Layouts.app>
    """
  end

  defp tree_listing(assigns) do
    ~H"""
    <table class="w-full font-mono text-sm">
      <tbody>
        <tr :for={entry <- @tree} class="border-b border-muted hover:bg-alt">
          <td class="py-2 pr-4 w-8 text-muted">
            {if entry.type == :dir, do: "[D]", else: "[F]"}
          </td>
          <td class="py-2">
            <.link
              :if={entry.type == :dir}
              navigate={"/#{@source}/#{@owner}/#{@repo}/tree/#{@branch}/#{entry.path}"}
              class="link-reset hover:underline"
            >
              {entry.name}/
            </.link>
            <.link
              :if={entry.type == :file}
              navigate={"/#{@source}/#{@owner}/#{@repo}/blob/#{@branch}/#{entry.path}"}
              class="link-reset hover:underline"
            >
              {entry.name}
            </.link>
          </td>
          <td class="py-2 text-right text-muted">
            {if entry.type == :file && entry.size, do: format_size(entry.size), else: ""}
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  defp source_class(:github), do: "text-xs px-1.5 py-0.5 bg-blue-900 text-blue-200 mr-1"
  defp source_class(:forgejo), do: "text-xs px-1.5 py-0.5 bg-purple-900 text-purple-200 mr-1"
  defp source_class(_), do: ""

  defp sort_tree(tree) do
    Enum.sort_by(tree, fn entry ->
      {if(entry.type == :dir, do: 0, else: 1), String.downcase(entry.name)}
    end)
  end

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1024 / 1024, 1)} MB"
end
