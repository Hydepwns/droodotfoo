defmodule DroodotfooWeb.Wiki.Library.UploadLive do
  @moduledoc """
  Document upload page with drag-and-drop support.
  Terminal aesthetic matching droo.foo.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Wiki.{Helpers, Layouts}
  alias Droodotfoo.Wiki.Library
  alias Droodotfoo.Wiki.Library.Document

  import Phoenix.Component

  # 50MB
  @max_file_size 50 * 1024 * 1024
  @allowed_types ~w(.pdf .doc .docx .odt .txt .md .html)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "UPLOAD", uploaded_files: [], tags_input: "", current_path: "/upload")
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
             |> push_navigate(to: "/doc/#{document.slug}")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply,
             put_flash(socket, :error, "Failed to save: #{Helpers.format_changeset_errors(changeset)}")}

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
    <Layouts.app flash={@flash} current_path={@current_path}>
      <section class="section-spaced">
        <div class="flex items-center justify-between">
          <h2 class="section-header-bordered" style="margin-bottom: 0; flex: 1;">
            UPLOAD
          </h2>
          <.link navigate="/">
            {"[<- BACK]"}
          </.link>
        </div>

        <form phx-submit="save" phx-change="validate">
          <div
            class="border-2 border-dashed p-4 mb-4"
            phx-drop-target={@uploads.document.ref}
          >
            <.live_file_input upload={@uploads.document} class="hidden" />

            <div :if={@uploads.document.entries == []} class="text-center py-4">
              <p class="text-muted mb-2">Drop a file here or</p>
              <label
                for={@uploads.document.ref}
                class="cursor-pointer"
              >
                [BROWSE TO UPLOAD]
              </label>
              <p class="text-xs text-muted mt-2">
                PDF, Word, ODT, Text, Markdown, HTML (max 50MB)
              </p>
            </div>

            <div :for={entry <- @uploads.document.entries}>
              <div class="flex items-center justify-between mb-2">
                <span>{entry.client_name}</span>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  class="text-muted"
                >
                  [REMOVE]
                </button>
              </div>

              <div class="progress-bar mb-2">
                <div
                  class="progress-bar-fill"
                  style={"width: #{entry.progress}%"}
                >
                </div>
              </div>

              <p class="text-xs text-muted">
                {Document.type_label(entry.client_type)} - {Document.format_size(entry.client_size)}
              </p>

              <.error_msg :for={err <- upload_errors(@uploads.document, entry)} error={err} />
            </div>
          </div>

          <div class="mb-2">
            <label class="block text-sm text-muted mb-1">Title</label>
            <input
              type="text"
              name="title"
              value={assigns[:title_input] || ""}
              placeholder="Document title (optional, uses filename if blank)"
              class="w-full"
            />
          </div>

          <div class="mb-4">
            <label class="block text-sm text-muted mb-1">Tags</label>
            <input
              type="text"
              name="tags"
              value={@tags_input}
              placeholder="work, reference, notes (comma-separated)"
              class="w-full"
            />
          </div>

          <button
            type="submit"
            disabled={@uploads.document.entries == []}
            class="btn w-full"
          >
            UPLOAD DOCUMENT
          </button>
        </form>
      </section>
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
    <p class="text-sm mt-1" style="color: #ff4444;">[!] {@msg}</p>
    """
  end
end
