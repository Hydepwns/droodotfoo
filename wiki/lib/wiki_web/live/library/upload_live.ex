defmodule WikiWeb.Library.UploadLive do
  @moduledoc """
  Document upload page with drag-and-drop support.
  """

  use WikiWeb, :live_view

  alias Wiki.Library
  alias Wiki.Library.Document

  # 50MB
  @max_file_size 50 * 1024 * 1024
  @allowed_types ~w(.pdf .doc .docx .odt .txt .md .html)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Upload Document", uploaded_files: [], tags_input: "")
     |> allow_upload(:document,
       accept: @allowed_types,
       max_entries: 1,
       max_file_size: @max_file_size,
       auto_upload: true
     )}
  end

  @impl true
  def handle_event("validate", %{"title" => title, "tags" => tags}, socket) do
    {:noreply, assign(socket, title_input: title, tags_input: tags)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :document, ref)}
  end

  def handle_event("save", %{"title" => title, "tags" => tags}, socket) do
    tags_list =
      tags
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    case uploaded_entries(socket, :document) do
      {[entry], []} ->
        # Consume the uploaded file
        result =
          consume_uploaded_entry(socket, entry, fn %{path: path} ->
            content = File.read!(path)
            content_type = entry.client_type

            title = if title == "", do: entry.client_name, else: title

            Library.upload_document(title, content_type, content, tags: tags_list)
          end)

        case result do
          {:ok, document} ->
            {:noreply,
             socket
             |> put_flash(:info, "Document uploaded successfully")
             |> push_navigate(to: ~p"/doc/#{document.slug}")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply,
             put_flash(socket, :error, "Failed to save: #{changeset_errors(changeset)}")}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Upload failed: #{inspect(reason)}")}
        end

      {[], [_error | _]} ->
        {:noreply, put_flash(socket, :error, "Please fix upload errors before saving")}

      _ ->
        {:noreply, put_flash(socket, :error, "Please select a file to upload")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-2xl mx-auto px-4 py-8">
        <div class="flex items-center justify-between mb-6">
          <h1 class="text-2xl font-mono font-bold">Upload Document</h1>
          <.link navigate="/" class="text-zinc-400 hover:text-white font-mono text-sm">
            &lt;- Back
          </.link>
        </div>

        <form phx-submit="save" phx-change="validate" class="space-y-6">
          <div
            class="border-2 border-dashed border-zinc-700 rounded-lg p-8 text-center hover:border-zinc-500 transition-colors"
            phx-drop-target={@uploads.document.ref}
          >
            <.live_file_input upload={@uploads.document} class="hidden" />

            <div :if={@uploads.document.entries == []} class="space-y-4">
              <div class="text-zinc-400 font-mono">
                <p class="text-lg">Drop a file here or</p>
                <label
                  for={@uploads.document.ref}
                  class="text-blue-400 hover:underline cursor-pointer"
                >
                  browse to upload
                </label>
              </div>
              <p class="text-sm text-zinc-500 font-mono">
                PDF, Word, ODT, Text, Markdown, HTML (max 50MB)
              </p>
            </div>

            <div :for={entry <- @uploads.document.entries} class="space-y-2">
              <div class="flex items-center justify-between">
                <span class="font-mono text-white">{entry.client_name}</span>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  class="text-red-400 hover:text-red-300 font-mono text-sm"
                >
                  Remove
                </button>
              </div>

              <div class="w-full bg-zinc-800 rounded-full h-2">
                <div
                  class="bg-blue-500 h-2 rounded-full transition-all"
                  style={"width: #{entry.progress}%"}
                >
                </div>
              </div>

              <p class="text-sm text-zinc-500 font-mono">
                {Document.type_label(entry.client_type)} - {Document.format_size(entry.client_size)}
              </p>

              <.error_msg :for={err <- upload_errors(@uploads.document, entry)} error={err} />
            </div>
          </div>

          <div>
            <label class="block text-sm font-mono text-zinc-400 mb-2">Title</label>
            <input
              type="text"
              name="title"
              value={assigns[:title_input] || ""}
              placeholder="Document title (optional, uses filename if blank)"
              class="w-full px-4 py-2 bg-zinc-900 border border-zinc-700 rounded font-mono text-white focus:border-blue-500 focus:outline-none"
            />
          </div>

          <div>
            <label class="block text-sm font-mono text-zinc-400 mb-2">Tags</label>
            <input
              type="text"
              name="tags"
              value={@tags_input}
              placeholder="work, reference, notes (comma-separated)"
              class="w-full px-4 py-2 bg-zinc-900 border border-zinc-700 rounded font-mono text-white focus:border-blue-500 focus:outline-none"
            />
          </div>

          <button
            type="submit"
            disabled={@uploads.document.entries == []}
            class="w-full px-4 py-3 bg-blue-600 hover:bg-blue-500 disabled:bg-zinc-700 disabled:cursor-not-allowed rounded font-mono font-bold"
          >
            Upload Document
          </button>
        </form>
      </div>
    </Layouts.app>
    """
  end

  defp error_msg(assigns) do
    msg =
      case assigns.error do
        :too_large -> "File is too large (max 50MB)"
        :not_accepted -> "File type not supported"
        :too_many_files -> "Only one file at a time"
        _ -> "Upload error"
      end

    assigns = assign(assigns, :msg, msg)

    ~H"""
    <p class="text-red-400 text-sm font-mono">{@msg}</p>
    """
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
    |> Enum.join("; ")
  end
end
