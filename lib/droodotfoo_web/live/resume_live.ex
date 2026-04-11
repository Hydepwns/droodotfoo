defmodule DroodotfooWeb.ResumeLive do
  @moduledoc """
  LiveView for interactive resume filtering, preview, and PDF export.

  Provides functionality for:
  - Filtering resume content by technology, search terms, and date ranges
  - Applying preset filters (blockchain, defense, recent, etc.)
  - Previewing resume in multiple formats (technical, executive, minimal, detailed)
  - Generating and downloading PDF exports with filtered content
  """

  use DroodotfooWeb, :live_view
  import DroodotfooWeb.ContentComponents

  alias Droodotfoo.Resume.{FilterEngine, PDFGenerator, ResumeData, SearchIndex}
  alias DroodotfooWeb.SEO.JsonLD

  @impl true
  def mount(_params, _session, socket) do
    formats = ResumeData.get_resume_formats()
    selected_format = "technical"
    resume_data = ResumeData.get_resume_data()
    technologies = SearchIndex.extract_technologies(resume_data)

    {:ok,
     socket
     |> assign(:formats, formats)
     |> assign(:selected_format, selected_format)
     |> assign(:preview_html, nil)
     |> assign(:is_generating, false)
     |> assign(:download_ready, false)
     |> assign(:generated_pdf, nil)
     |> assign(:resume_data, resume_data)
     |> assign(:filtered_data, nil)
     |> assign(:technologies, technologies)
     |> assign(:selected_technologies, [])
     |> assign(:search_query, "")
     |> assign(:match_count, nil)
     |> assign(:active_filters, %{})
     |> assign_page_meta(
       "Resume",
       "/resume",
       breadcrumb_json_ld("Resume", "/resume", [JsonLD.person_schema()])
     )
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
  def handle_event("search_resume", %{"search" => %{"query" => query}}, socket) do
    socket =
      socket
      |> assign(:search_query, query)
      |> apply_filters()

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_technology", %{"tech" => tech}, socket) do
    selected = socket.assigns.selected_technologies

    new_selected =
      if tech in selected do
        List.delete(selected, tech)
      else
        [tech | selected]
      end

    socket =
      socket
      |> assign(:selected_technologies, new_selected)
      |> apply_filters()

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    socket =
      socket
      |> assign(:selected_technologies, [])
      |> assign(:search_query, "")
      |> assign(:active_filters, %{})
      |> assign(:filtered_data, nil)
      |> assign(:match_count, nil)

    {:noreply, socket}
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

  # Private helper functions

  defp load_preview(socket, format) do
    preview_html = PDFGenerator.generate_html_preview(format)
    assign(socket, :preview_html, preview_html)
  end

  defp apply_filters(socket) do
    technologies = socket.assigns.selected_technologies
    search_query = socket.assigns.search_query
    resume_data = socket.assigns.resume_data

    # Build filter options
    filters = %{}

    filters =
      if length(technologies) > 0 do
        Map.put(filters, :technologies, technologies)
      else
        filters
      end

    filters =
      if search_query != "" and String.trim(search_query) != "" do
        Map.put(filters, :text_search, search_query)
      else
        filters
      end

    # Apply additional filters from active_filters (like date ranges from presets)
    filters = Map.merge(filters, socket.assigns.active_filters)

    # Only filter if we have active filters
    if map_size(filters) > 0 do
      result = FilterEngine.filter(resume_data, filters)

      socket
      |> assign(:filtered_data, result)
      |> assign(:match_count, result.match_count)
    else
      socket
      |> assign(:filtered_data, nil)
      |> assign(:match_count, nil)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout
      page_title="Resume"
      page_description="Experience, education, and technical background"
    >
      <div class="resume-controls">
        <div class="action-buttons">
          <div class="format-selector">
            <%= for format <- @formats do %>
              <button
                class={["preset-btn", @selected_format == format.id && "selected"]}
                phx-click="select_format"
                phx-value-format={format.id}
                title={format.description}
              >
                {format.name}
              </button>
            <% end %>
          </div>

          <button
            class={["generate-btn", @is_generating && "generating"]}
            phx-click="generate_pdf"
            disabled={@is_generating}
          >
            <%= if @is_generating do %>
              <span class="spinner"></span> Generating...
            <% else %>
              Download PDF
            <% end %>
          </button>

          <%= if @download_ready do %>
            <a
              href={"/resume/download?format=#{@selected_format}"}
              class="download-btn"
              download={"resume_#{@selected_format}.pdf"}
            >
              Save PDF
            </a>
          <% end %>
        </div>
      </div>

      <%= if @preview_html do %>
        <div class="resume-preview">
          {raw(@preview_html)}
        </div>
      <% end %>

      <details class="experience-details mt-2">
        <summary class="experience-summary">Filter by technology or keyword</summary>
        <div class="filter-content mt-1">
          <form phx-change="search_resume" phx-submit="search_resume">
            <input
              type="text"
              name="search[query]"
              value={@search_query}
              placeholder="Search (blockchain, defense, engineering...)"
              class="search-input"
              autocomplete="off"
            />
          </form>

          <div class="mt-1">
            <.tech_chips
              technologies={Enum.take(@technologies.all, 20)}
              selected={@selected_technologies}
              click_event="toggle_technology"
            />
          </div>

          <%= if @match_count do %>
            <div class="active-filters mt-1">
              <span class="text-muted">Found {@match_count} matches</span>
              <button class="clear-filters-btn" phx-click="clear_filters">Clear</button>
            </div>

            <%= if @filtered_data do %>
              <div class="filter-results mt-1">
                <%= for exp <- @filtered_data.experience do %>
                  <div class="result-item">
                    <strong>{exp.position}</strong> at {exp.company}
                    <span class="text-muted">({exp.start_date} - {exp.end_date})</span>
                  </div>
                <% end %>
                <%= for edu <- @filtered_data.education do %>
                  <div class="result-item">
                    <strong>{edu.degree}</strong>, {edu.field}
                    <span class="text-muted">-- {edu.institution}</span>
                  </div>
                <% end %>
              </div>
            <% end %>
          <% end %>
        </div>
      </details>
    </.page_layout>
    """
  end
end
