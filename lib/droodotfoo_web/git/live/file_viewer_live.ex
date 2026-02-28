defmodule DroodotfooWeb.Git.FileViewerLive do
  @moduledoc """
  File content viewer with line numbers.
  Supports both GitHub and Forgejo sources.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Git.Layouts
  alias Droodotfoo.Git

  @max_file_size 500_000

  @impl true
  def mount(params, _session, socket) do
    source = parse_source(params["source"])
    owner = params["owner"]
    repo = params["repo"]
    branch = params["branch"]
    path = params["path"] || []
    path_string = Enum.join(path, "/")
    filename = List.last(path) || ""

    if connected?(socket), do: send(self(), :load_file)

    {:ok,
     assign(socket,
       source: source,
       owner: owner,
       repo: repo,
       branch: branch,
       path: path,
       path_string: path_string,
       filename: filename,
       content: nil,
       file_size: nil,
       too_large: false,
       binary: false,
       loading: true,
       error: nil,
       page_title: filename,
       current_path: "/#{source}/#{owner}/#{repo}/blob/#{branch}/#{path_string}"
     )}
  end

  defp parse_source("github"), do: :github
  defp parse_source("forgejo"), do: :forgejo
  defp parse_source(_), do: :github

  @impl true
  def handle_info(:load_file, socket) do
    %{source: source, owner: owner, repo: repo, branch: branch, path_string: path_string} =
      socket.assigns

    case Git.get_file(source, owner, repo, branch, path_string) do
      {:ok, %{content: content, size: size}} ->
        cond do
          size > @max_file_size ->
            {:noreply, assign(socket, too_large: true, file_size: size, loading: false)}

          binary?(content) ->
            {:noreply, assign(socket, binary: true, file_size: size, loading: false)}

          true ->
            {:noreply, assign(socket, content: content, file_size: size, loading: false)}
        end

      {:error, :is_directory} ->
        {:noreply,
         push_navigate(socket,
           to: "/#{source}/#{owner}/#{repo}/tree/#{branch}/#{path_string}"
         )}

      {:error, :not_found} ->
        {:noreply, assign(socket, error: "File not found", loading: false)}

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
          Loading file...
        </div>

        <div :if={@error} class="text-error">
          Error: {@error}
        </div>

        <div :if={@too_large} class="bg-alt border border-muted p-4 text-center">
          <p class="text-muted-alt mb-2">
            File too large to display ({format_size(@file_size)})
          </p>
          <p class="text-sm text-muted">
            Maximum viewable size: {format_size(@max_file_size)}
          </p>
        </div>

        <div :if={@binary} class="bg-alt border border-muted p-4 text-center">
          <p class="text-muted-alt mb-2">
            Binary file ({format_size(@file_size)})
          </p>
          <p class="text-sm text-muted">
            Cannot display binary content
          </p>
        </div>

        <div :if={@content} class="file-viewer">
          <div class="flex justify-between items-center mb-2 text-sm text-muted">
            <span>{line_count(@content)} lines | {format_size(@file_size)}</span>
            <span>{@filename}</span>
          </div>
          <.code_block content={@content} />
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
          :if={index < length(@path) - 1}
          navigate={"/#{@source}/#{@owner}/#{@repo}/tree/#{@branch}/#{Enum.take(@path, index + 1) |> Enum.join("/")}"}
          class="hover:underline"
        >
          {segment}
        </.link>
        <span :if={index == length(@path) - 1}>{segment}</span>
      </span>
    </span>
    """
  end

  defp code_block(assigns) do
    lines = String.split(assigns.content, "\n")
    assigns = assign(assigns, :lines, lines)

    ~H"""
    <div class="overflow-x-auto bg-alt border border-muted">
      <table class="w-full font-mono text-sm">
        <tbody>
          <tr :for={{line, num} <- Enum.with_index(@lines, 1)}>
            <td class="py-0 px-2 text-right text-muted select-none border-r border-muted w-12">
              {num}
            </td>
            <td class="py-0 px-2 whitespace-pre">{line}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp source_class(:github), do: "text-xs px-1.5 py-0.5 bg-blue-900 text-blue-200 mr-1"
  defp source_class(:forgejo), do: "text-xs px-1.5 py-0.5 bg-purple-900 text-purple-200 mr-1"
  defp source_class(_), do: ""

  defp binary?(content) do
    bytes = :binary.bin_to_list(String.slice(content, 0, 1000))
    null_count = Enum.count(bytes, &(&1 == 0))
    non_printable = Enum.count(bytes, fn b -> b < 32 and b not in [9, 10, 13] end)
    null_count > 0 or non_printable / max(length(bytes), 1) > 0.3
  end

  defp line_count(content) do
    content
    |> String.split("\n")
    |> length()
  end

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1024 / 1024, 1)} MB"
end
