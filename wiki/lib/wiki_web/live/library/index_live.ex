defmodule WikiWeb.Library.IndexLive do
  @moduledoc """
  Personal document library index.

  Tailnet-only access. Shows document listing with search and filtering.
  """

  use WikiWeb, :live_view

  alias Wiki.Library
  alias Wiki.Library.Document

  @impl true
  def mount(_params, _session, socket) do
    documents = Library.list_documents()
    tags = Library.list_tags()

    {:ok,
     assign(socket,
       documents: documents,
       tags: tags,
       search: "",
       selected_tag: nil,
       page_title: "Library"
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    search = params["q"] || ""
    tag = params["tag"]

    opts =
      []
      |> maybe_add(:search, search)
      |> maybe_add(:tag, tag)

    documents = Library.list_documents(opts)

    {:noreply, assign(socket, documents: documents, search: search, selected_tag: tag)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    params = if query == "", do: %{}, else: %{q: query}

    params =
      if socket.assigns.selected_tag,
        do: Map.put(params, :tag, socket.assigns.selected_tag),
        else: params

    {:noreply, push_patch(socket, to: ~p"/?#{params}")}
  end

  def handle_event("filter_tag", %{"tag" => tag}, socket) do
    tag = if tag == "", do: nil, else: tag
    params = if socket.assigns.search != "", do: %{q: socket.assigns.search}, else: %{}
    params = if tag, do: Map.put(params, :tag, tag), else: params

    {:noreply, push_patch(socket, to: ~p"/?#{params}")}
  end

  def handle_event("delete", %{"slug" => slug}, socket) do
    case Library.get_document(slug) do
      nil ->
        {:noreply, put_flash(socket, :error, "Document not found")}

      document ->
        case Library.delete_document(document) do
          {:ok, _} ->
            documents = Library.list_documents()

            {:noreply,
             socket
             |> assign(documents: documents)
             |> put_flash(:info, "Document deleted")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to delete document")}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto px-4 py-8">
        <div class="flex justify-between items-center mb-6">
          <h1 class="text-2xl font-mono font-bold">Document Library</h1>
          <.link
            navigate="/upload"
            class="px-4 py-2 bg-blue-600 hover:bg-blue-500 rounded font-mono text-sm"
          >
            + Upload
          </.link>
        </div>

        <div class="flex gap-4 mb-6">
          <form phx-submit="search" phx-change="search" class="flex-1">
            <input
              type="text"
              name="q"
              value={@search}
              placeholder="Search documents..."
              phx-debounce="300"
              class="w-full px-4 py-2 bg-zinc-900 border border-zinc-700 rounded font-mono text-white focus:border-blue-500 focus:outline-none"
            />
          </form>

          <select
            phx-change="filter_tag"
            name="tag"
            class="px-4 py-2 bg-zinc-900 border border-zinc-700 rounded font-mono text-white"
          >
            <option value="">All tags</option>
            <option :for={tag <- @tags} value={tag} selected={@selected_tag == tag}>
              {tag}
            </option>
          </select>
        </div>

        <div :if={@documents == []} class="text-zinc-500 font-mono py-8 text-center">
          {if @search != "" or @selected_tag,
            do: "No documents match your search.",
            else: "No documents uploaded yet."}
        </div>

        <div :if={@documents != []} class="space-y-2">
          <.document_row :for={doc <- @documents} document={doc} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp document_row(assigns) do
    ~H"""
    <div class="flex items-center justify-between p-4 border border-zinc-800 rounded hover:border-zinc-700 transition-colors group">
      <div class="flex items-center gap-4 min-w-0">
        <.type_icon type={@document.content_type} />

        <div class="min-w-0">
          <.link
            navigate={~p"/doc/#{@document.slug}"}
            class="font-mono text-white hover:text-blue-400 truncate block"
          >
            {@document.title}
          </.link>

          <div class="flex items-center gap-3 text-sm text-zinc-500 font-mono">
            <span>{Document.type_label(@document.content_type)}</span>
            <span>{Document.format_size(@document.file_size)}</span>
            <span>{format_date(@document.inserted_at)}</span>
          </div>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <div :if={@document.tags != []} class="hidden md:flex gap-1">
          <span
            :for={tag <- Enum.take(@document.tags, 3)}
            class="px-2 py-0.5 bg-zinc-800 text-zinc-400 rounded text-xs font-mono"
          >
            {tag}
          </span>
        </div>

        <button
          phx-click="delete"
          phx-value-slug={@document.slug}
          data-confirm="Delete this document?"
          class="p-2 text-zinc-500 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
            />
          </svg>
        </button>
      </div>
    </div>
    """
  end

  defp type_icon(assigns) do
    color =
      case assigns.type do
        "application/pdf" ->
          "text-red-400"

        t
        when t in [
               "application/msword",
               "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
             ] ->
          "text-blue-400"

        "text/markdown" ->
          "text-purple-400"

        _ ->
          "text-zinc-400"
      end

    assigns = assign(assigns, :color, color)

    ~H"""
    <div class={"w-10 h-10 rounded flex items-center justify-center bg-zinc-800 #{@color} font-mono text-xs font-bold"}>
      {type_abbr(@type)}
    </div>
    """
  end

  defp type_abbr("application/pdf"), do: "PDF"
  defp type_abbr("application/msword"), do: "DOC"

  defp type_abbr("application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
    do: "DOCX"

  defp type_abbr("application/vnd.oasis.opendocument.text"), do: "ODT"
  defp type_abbr("text/plain"), do: "TXT"
  defp type_abbr("text/markdown"), do: "MD"
  defp type_abbr("text/html"), do: "HTML"
  defp type_abbr(_), do: "FILE"

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y")
  end

  defp maybe_add(opts, _key, nil), do: opts
  defp maybe_add(opts, _key, ""), do: opts
  defp maybe_add(opts, key, value), do: Keyword.put(opts, key, value)
end
