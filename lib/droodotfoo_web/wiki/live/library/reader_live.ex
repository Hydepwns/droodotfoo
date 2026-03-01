defmodule DroodotfooWeb.Wiki.Library.ReaderLive do
  @moduledoc """
  Document reader/viewer.
  Terminal aesthetic matching droo.foo.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Wiki.Layouts
  alias Droodotfoo.Wiki.Library
  alias Droodotfoo.Wiki.Library.Document

  import Phoenix.Component
  import DroodotfooWeb.Wiki.Helpers, only: [format_date: 1, format_datetime: 1]

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Library.get_document(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Document not found")
         |> push_navigate(to: "/")}

      document ->
        download_url = Library.download_url(document)
        content = load_text_content(document)
        revisions = Library.list_revisions(document)

        {:ok,
         assign(socket,
           document: document,
           download_url: download_url,
           content: content,
           revisions: revisions,
           show_versions: false,
           page_title: String.upcase(document.title),
           current_path: "/doc/#{slug}"
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <section class="section-spaced">
        <div class="flex items-center justify-between">
          <h2 class="section-header-bordered" style="margin-bottom: 0; flex: 1;">
            <.link navigate="/" class="text-muted-alt">{"[<-]"}</.link>
            {String.upcase(@document.title)}
          </h2>
          <a href={@download_url} download={@document.title} class="btn">
            [DOWNLOAD]
          </a>
        </div>

        <p class="text-muted-alt mt-2">
          <span class="source-badge">{Document.type_abbr(@document.content_type)}</span>
          {Document.format_size(@document.file_size)} · Uploaded {format_date(@document.inserted_at)}
          <span :for={tag <- @document.tags}> ·         {tag}</span>
          <button
            :if={@revisions != []}
            phx-click="toggle_versions"
            class="ml-4 text-blue-400 hover:text-blue-300"
          >
            [{if @show_versions, do: "hide", else: "show"} {@revisions |> length()} versions]
          </button>
        </p>
      </section>

      <section :if={@show_versions && @revisions != []} class="section-spaced">
        <h2 class="section-header-bordered">VERSION HISTORY</h2>
        <table class="w-full font-mono text-sm">
          <thead class="text-left text-muted-alt">
            <tr>
              <th class="py-2 pr-4">Date</th>
              <th class="py-2 pr-4">Size</th>
              <th class="py-2 pr-4">Comment</th>
              <th class="py-2"></th>
            </tr>
          </thead>
          <tbody>
            <tr :for={rev <- @revisions} class="border-t border-muted">
              <td class="py-2 pr-4">{format_datetime(rev.inserted_at)}</td>
              <td class="py-2 pr-4">{Document.format_size(rev.file_size)}</td>
              <td class="py-2 pr-4 text-muted-alt">{rev.comment || "-"}</td>
              <td class="py-2 text-right">
                <button
                  phx-click="restore"
                  phx-value-id={rev.id}
                  data-confirm="Restore this version? Current content will be saved as a revision."
                  class="text-blue-400 hover:text-blue-300"
                >
                  [restore]
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </section>

      <section class="section-spaced">
        <.viewer document={@document} download_url={@download_url} content={@content} />
      </section>
    </Layouts.app>
    """
  end

  defp viewer(%{document: %{content_type: "application/pdf"}} = assigns) do
    ~H"""
    <div
      id="pdf-viewer"
      phx-hook="PdfViewer"
      data-url={@download_url}
      class="w-full bg-alt border"
      style="height: calc(100vh - 200px);"
    >
      <div class="flex items-center justify-center h-full text-muted">
        <div class="text-center">
          <div class="loading mb-2">Loading PDF</div>
          <a href={@download_url} target="_blank">
            [OPEN IN NEW TAB]
          </a>
        </div>
      </div>
    </div>
    """
  end

  defp viewer(%{document: %{content_type: "text/markdown"}} = assigns) do
    ~H"""
    <article class="article-body bg-alt border p-4">
      {Phoenix.HTML.raw(render_markdown(@content))}
    </article>
    """
  end

  defp viewer(%{document: %{content_type: "text/plain"}} = assigns) do
    ~H"""
    <pre class="bg-alt border p-4 overflow-x-auto text-sm whitespace-pre-wrap">{@content}</pre>
    """
  end

  defp viewer(%{document: %{content_type: "text/html"}} = assigns) do
    ~H"""
    <div class="bg-alt border p-4">
      <iframe
        srcdoc={@content}
        class="w-full border-0"
        style="height: calc(100vh - 250px);"
        sandbox="allow-same-origin"
      >
      </iframe>
    </div>
    """
  end

  defp viewer(assigns) do
    ~H"""
    <div class="bg-alt border p-4 text-center">
      <p class="text-muted mb-4">
        Preview not available for this file type.
      </p>
      <a href={@download_url} download class="btn">
        [DOWNLOAD FILE]
      </a>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_versions", _params, socket) do
    {:noreply, assign(socket, show_versions: !socket.assigns.show_versions)}
  end

  def handle_event("restore", %{"id" => id}, socket) do
    revision_id = String.to_integer(id)

    case Library.restore_revision(socket.assigns.document, revision_id) do
      {:ok, document} ->
        content = load_text_content(document)
        revisions = Library.list_revisions(document)

        {:noreply,
         socket
         |> put_flash(:info, "Document restored from revision")
         |> assign(document: document, content: content, revisions: revisions)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Revision not found")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to restore revision")}
    end
  end

  defp load_text_content(%Document{content_type: type} = doc)
       when type in ["text/plain", "text/markdown", "text/html"] do
    case Library.get_file(doc.file_key) do
      {:ok, content} -> content
      {:error, _} -> ""
    end
  end

  defp load_text_content(_), do: nil

  defp render_markdown(nil), do: ""
  defp render_markdown(content), do: MDEx.to_html!(content)
end
