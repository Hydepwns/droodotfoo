defmodule DroodotfooWeb.Git.FileBrowserLive do
  @moduledoc """
  Directory browser for repository files.
  Supports both GitHub and Forgejo sources.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Git.Layouts
  alias Droodotfoo.Git

  @impl true
  def mount(params, _session, socket) do
    source = parse_source(params["source"])
    owner = params["owner"]
    repo = params["repo"]
    branch = params["branch"]
    path = params["path"] || []
    path_string = Enum.join(path, "/")

    if connected?(socket), do: send(self(), :load_tree)

    {:ok,
     assign(socket,
       source: source,
       owner: owner,
       repo: repo,
       branch: branch,
       path: path,
       path_string: path_string,
       tree: [],
       loading: true,
       error: nil,
       page_title: if(path_string == "", do: "/#{repo}", else: "/#{repo}/#{path_string}"),
       current_path: "/#{source}/#{owner}/#{repo}/tree/#{branch}"
     )}
  end

  defp parse_source("github"), do: :github
  defp parse_source("forgejo"), do: :forgejo
  defp parse_source(_), do: :github

  @impl true
  def handle_info(:load_tree, socket) do
    %{source: source, owner: owner, repo: repo, branch: branch, path_string: path_string} =
      socket.assigns

    case Git.get_tree(source, owner, repo, branch, path_string) do
      {:ok, tree} ->
        {:noreply, assign(socket, tree: sort_tree(tree), loading: false)}

      {:error, :not_found} ->
        {:noreply, assign(socket, error: "Path not found", loading: false)}

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
          <.breadcrumbs
            source={@source}
            owner={@owner}
            repo={@repo}
            branch={@branch}
            path={@path}
          />
        </h2>

        <div :if={@loading} class="loading">
          Loading...
        </div>

        <div :if={@error} class="text-error">
          Error: {@error}
        </div>

        <div :if={!@loading && !@error}>
          <.tree_listing
            tree={@tree}
            source={@source}
            owner={@owner}
            repo={@repo}
            branch={@branch}
            path_string={@path_string}
          />
        </div>
      </section>
    </Layouts.app>
    """
  end

  defp breadcrumbs(assigns) do
    ~H"""
    <span>
      <.link navigate="/" class="text-muted-alt">{"[<-]"}</.link>
      <span class={source_class(@source)}>{@source}</span>
      <.link navigate={"/#{@source}/#{@owner}/#{@repo}"} class="hover:underline">
        /{@repo}
      </.link>
      <span class="text-muted">/{@branch}</span>
      <span :for={{segment, index} <- Enum.with_index(@path)}>
        /<.link
          navigate={"/#{@source}/#{@owner}/#{@repo}/tree/#{@branch}/#{Enum.take(@path, index + 1) |> Enum.join("/")}"}
          class="hover:underline"
        >
          {segment}
        </.link>
      </span>
    </span>
    """
  end

  defp tree_listing(assigns) do
    parent_path = parent_dir(assigns.path_string)
    assigns = assign(assigns, :parent_path, parent_path)

    ~H"""
    <table class="w-full font-mono text-sm">
      <tbody>
        <tr :if={@path_string != ""} class="border-b border-muted hover:bg-alt">
          <td class="py-2 pr-4 w-8 text-muted">[D]</td>
          <td class="py-2" colspan="2">
            <.link
              navigate={
                if @parent_path == "",
                  do: "/#{@source}/#{@owner}/#{@repo}/tree/#{@branch}",
                  else: "/#{@source}/#{@owner}/#{@repo}/tree/#{@branch}/#{@parent_path}"
              }
              class="link-reset hover:underline"
            >
              ../
            </.link>
          </td>
        </tr>
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

    <p :if={@tree == []} class="text-muted-alt mt-4">
      Empty directory.
    </p>
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

  defp parent_dir(""), do: ""

  defp parent_dir(path) do
    path
    |> String.split("/")
    |> Enum.drop(-1)
    |> Enum.join("/")
  end

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1024 / 1024, 1)} MB"
end
