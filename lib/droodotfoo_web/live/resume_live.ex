defmodule DroodotfooWeb.ResumeLive do
  use DroodotfooWeb, :live_view

  alias Droodotfoo.Resume.{PDFGenerator, ResumeData}

  @impl true
  def mount(_params, _session, socket) do
    formats = ResumeData.get_resume_formats()
    selected_format = "technical"

    {:ok,
     socket
     |> assign(:formats, formats)
     |> assign(:selected_format, selected_format)
     |> assign(:preview_html, nil)
     |> assign(:is_generating, false)
     |> assign(:download_ready, false)
     |> assign(:generated_pdf, nil)
     |> load_preview(selected_format)}
  end

  @impl true
  def handle_event("select_format", %{"format" => format}, socket) do
    socket =
      socket
      |> assign(:selected_format, format)
      |> assign(:download_ready, false)
      |> assign(:generated_pdf, nil)
      |> load_preview(format)

    {:noreply, socket}
  end

  @impl true
  def handle_event("generate_pdf", _params, socket) do
    socket =
      socket
      |> assign(:is_generating, true)
      |> assign(:download_ready, false)

    # Simulate PDF generation
    Process.send_after(self(), :pdf_generated, 2000)

    {:noreply, socket}
  end

  @impl true
  def handle_event("download_pdf", _params, socket) do
    if socket.assigns.download_ready do
      # Trigger download
      {:noreply, push_event(socket, "download_pdf", %{})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:pdf_generated, socket) do
    socket =
      socket
      |> assign(:is_generating, false)
      |> assign(:download_ready, true)
      |> assign(
        :generated_pdf,
        "resume_#{socket.assigns.selected_format}_#{DateTime.utc_now() |> DateTime.to_unix()}"
      )

    {:noreply, socket}
  end

  defp load_preview(socket, format) do
    preview_html = PDFGenerator.generate_html_preview(format)
    assign(socket, :preview_html, preview_html)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="resume-container">
      <div class="resume-header">
        <h1>Resume Export</h1>
        <p>Generate and download your resume in multiple formats</p>
      </div>

      <div class="resume-controls">
        <div class="format-selector">
          <h3>Select Format</h3>
          <div class="format-options">
            <%= for format <- @formats do %>
              <label class={["format-option", @selected_format == format.id && "selected"]}>
                <input
                  type="radio"
                  name="format"
                  value={format.id}
                  checked={@selected_format == format.id}
                  phx-click="select_format"
                  phx-value-format={format.id}
                />
                <div class="format-info">
                  <div class="format-name">{format.name}</div>
                  <div class="format-description">{format.description}</div>
                </div>
              </label>
            <% end %>
          </div>
        </div>

        <div class="action-buttons">
          <button
            class={["generate-btn", @is_generating && "generating"]}
            phx-click="generate_pdf"
            disabled={@is_generating}
          >
            <%= if @is_generating do %>
              <span class="spinner"></span> Generating PDF...
            <% else %>
              Generate PDF
            <% end %>
          </button>

          <%= if @download_ready do %>
            <button
              class="download-btn"
              phx-click="download_pdf"
            >
              Download PDF
            </button>
          <% end %>
        </div>
      </div>

      <div class="preview-section">
        <h3>Preview</h3>
        <div class="preview-container">
          <iframe
            src={"data:text/html;charset=utf-8,#{URI.encode(@preview_html)}"}
            class="preview-iframe"
            title="Resume Preview"
          />
        </div>
      </div>

      <div class="resume-info">
        <h3>Resume Features</h3>
        <div class="features-grid">
          <div class="feature">
            <div class="feature-title">Multiple Formats</div>
            <div class="feature-description">Technical, Executive, Minimal, and Detailed formats</div>
          </div>
          <div class="feature">
            <div class="feature-title">Real-time Preview</div>
            <div class="feature-description">
              See exactly how your resume will look before downloading
            </div>
          </div>
          <div class="feature">
            <div class="feature-title">Professional Styling</div>
            <div class="feature-description">
              Clean, ATS-friendly layouts optimized for different use cases
            </div>
          </div>
          <div class="feature">
            <div class="feature-title">Instant Download</div>
            <div class="feature-description">Generate and download PDFs instantly</div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
