defmodule WikiWeb.Library.ReaderLive do
  @moduledoc """
  Document reader/viewer.

  For PDFs, uses PDF.js via a JavaScript hook.
  For text/markdown/HTML, renders inline.
  """

  use WikiWeb, :live_view

  alias Wiki.Library
  alias Wiki.Library.Document

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Library.get_document(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Document not found")
         |> push_navigate(to: ~p"/")}

      document ->
        download_url = Library.download_url(document)
        content = load_text_content(document)

        {:ok,
         assign(socket,
           document: document,
           download_url: download_url,
           content: content,
           page_title: document.title
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-6xl mx-auto px-4 py-8">
        <header class="mb-6">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
              <.link navigate="/" class="text-zinc-400 hover:text-white">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 19l-7-7 7-7"
                  />
                </svg>
              </.link>
              <h1 class="text-xl font-mono font-bold">{@document.title}</h1>
            </div>

            <div class="flex items-center gap-3">
              <a
                href={@download_url}
                download={@document.title}
                class="px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 rounded font-mono text-sm"
              >
                Download
              </a>
            </div>
          </div>

          <div class="flex items-center gap-4 mt-2 text-sm text-zinc-500 font-mono">
            <span>{Document.type_label(@document.content_type)}</span>
            <span>{Document.format_size(@document.file_size)}</span>
            <span>Uploaded {format_date(@document.inserted_at)}</span>
          </div>

          <div :if={@document.tags != []} class="flex gap-2 mt-3">
            <span
              :for={tag <- @document.tags}
              class="px-2 py-0.5 bg-zinc-800 text-zinc-400 rounded text-xs font-mono"
            >
              {tag}
            </span>
          </div>
        </header>

        <.viewer document={@document} download_url={@download_url} content={@content} />
      </div>
    </Layouts.app>
    """
  end

  defp viewer(%{document: %{content_type: "application/pdf"}} = assigns) do
    ~H"""
    <div
      id="pdf-viewer"
      phx-hook="PdfViewer"
      data-url={@download_url}
      class="w-full bg-zinc-900 rounded-lg overflow-hidden"
      style="height: calc(100vh - 200px);"
    >
      <div class="flex items-center justify-center h-full text-zinc-500 font-mono">
        <div class="text-center">
          <div class="animate-pulse mb-2">Loading PDF...</div>
          <a
            href={@download_url}
            target="_blank"
            class="text-blue-400 hover:underline text-sm"
          >
            Open in new tab
          </a>
        </div>
      </div>
    </div>
    """
  end

  defp viewer(%{document: %{content_type: "text/markdown"}} = assigns) do
    ~H"""
    <article class="prose prose-invert max-w-none font-mono bg-zinc-900 rounded-lg p-6">
      {raw(render_markdown(@content))}
    </article>
    """
  end

  defp viewer(%{document: %{content_type: "text/plain"}} = assigns) do
    ~H"""
    <pre class="bg-zinc-900 rounded-lg p-6 overflow-x-auto font-mono text-sm text-zinc-300 whitespace-pre-wrap">{@content}</pre>
    """
  end

  defp viewer(%{document: %{content_type: "text/html"}} = assigns) do
    ~H"""
    <div class="bg-zinc-900 rounded-lg p-6">
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
    <div class="bg-zinc-900 rounded-lg p-8 text-center">
      <p class="text-zinc-400 font-mono mb-4">
        Preview not available for this file type.
      </p>
      <a
        href={@download_url}
        download
        class="px-4 py-2 bg-blue-600 hover:bg-blue-500 rounded font-mono"
      >
        Download File
      </a>
    </div>
    """
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

  defp render_markdown(content) do
    # Basic markdown rendering - can be enhanced with MDEx if available
    content
    |> String.replace(~r/^### (.+)$/m, "<h3>\\1</h3>")
    |> String.replace(~r/^## (.+)$/m, "<h2>\\1</h2>")
    |> String.replace(~r/^# (.+)$/m, "<h1>\\1</h1>")
    |> String.replace(~r/\*\*(.+?)\*\*/, "<strong>\\1</strong>")
    |> String.replace(~r/\*(.+?)\*/, "<em>\\1</em>")
    |> String.replace(~r/`(.+?)`/, "<code>\\1</code>")
    |> String.replace(~r/\[(.+?)\]\((.+?)\)/, "<a href=\"\\2\">\\1</a>")
    |> String.replace(~r/\n\n/, "</p><p>")
    |> then(&"<p>#{&1}</p>")
  end

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end
end
