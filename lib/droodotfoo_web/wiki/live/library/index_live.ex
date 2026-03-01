defmodule DroodotfooWeb.Wiki.Library.IndexLive do
  @moduledoc """
  Personal document library index.
  Terminal aesthetic matching droo.foo.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Wiki.Layouts
  alias Droodotfoo.Wiki.Library
  alias Droodotfoo.Wiki.Library.Document

  import Phoenix.Component
  import DroodotfooWeb.Wiki.Helpers, only: [format_date: 1]

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
       page_title: "LIBRARY",
       current_path: "/lib"
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

    {:noreply, push_patch(socket, to: "/?#{URI.encode_query(params)}")}
  end

  def handle_event("filter_tag", %{"tag" => tag}, socket) do
    tag = if tag == "", do: nil, else: tag
    params = if socket.assigns.search != "", do: %{q: socket.assigns.search}, else: %{}
    params = if tag, do: Map.put(params, :tag, tag), else: params

    {:noreply, push_patch(socket, to: "/?#{URI.encode_query(params)}")}
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
    <Layouts.app flash={@flash} current_path={@current_path}>
      <section class="section-spaced">
        <div class="flex justify-between items-center">
          <h2 class="section-header-bordered" style="margin-bottom: 0; flex: 1;">
            DOCUMENTS
          </h2>
          <.link navigate="/upload" class="btn">
            [+ UPLOAD]
          </.link>
        </div>

        <div class="flex gap-2 mb-2 mt-2">
          <form phx-submit="search" phx-change="search" class="flex-1">
            <input
              type="text"
              name="q"
              value={@search}
              placeholder="Search documents..."
              phx-debounce="300"
              class="w-full"
            />
          </form>

          <select phx-change="filter_tag" name="tag">
            <option value="">All tags</option>
            <option :for={tag <- @tags} value={tag} selected={@selected_tag == tag}>
              {tag}
            </option>
          </select>
        </div>
      </section>

      <section :if={@documents == []} class="section-spaced">
        <p class="text-muted-alt">
          {if @search != "" or @selected_tag,
            do: "No documents match your search.",
            else: "No documents uploaded yet."}
        </p>
      </section>

      <section :if={@documents != []} class="section-spaced">
        <article :for={doc <- @documents} class="post-item">
          <.document_row document={doc} />
        </article>
      </section>
    </Layouts.app>
    """
  end

  defp document_row(assigns) do
    ~H"""
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-2 min-w-0">
        <span class="source-badge">{Document.type_abbr(@document.content_type)}</span>
        <div class="min-w-0">
          <h3 class="mb-0-5">
            <.link navigate={"/doc/#{@document.slug}"} class="link-reset">
              {@document.title}
            </.link>
          </h3>
          <p class="text-muted-alt text-sm">
            {Document.format_size(@document.file_size)} · {format_date(@document.inserted_at)}
            <span :for={tag <- Enum.take(@document.tags, 3)} class="hidden-mobile">
              · {tag}
            </span>
          </p>
        </div>
      </div>
      <button
        phx-click="delete"
        phx-value-slug={@document.slug}
        data-confirm="Delete this document?"
        class="text-muted-alt cursor-pointer"
      >
        [X]
      </button>
    </div>
    """
  end

  defp maybe_add(opts, _key, nil), do: opts
  defp maybe_add(opts, _key, ""), do: opts
  defp maybe_add(opts, key, value), do: Keyword.put(opts, key, value)
end
