defmodule WikiWeb.Library.ReaderLive do
  @moduledoc """
  Document reader/viewer.
  Terminal aesthetic matching droo.foo.
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
          <span class="source-badge">{type_abbr(@document.content_type)}</span>
          {Document.format_size(@document.file_size)} · Uploaded {format_date(@document.inserted_at)}
          <span :for={tag <- @document.tags}> ·  {tag}</span>
        </p>
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
      {raw(render_markdown(@content))}
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
    Calendar.strftime(datetime, "%Y-%m-%d")
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
end
