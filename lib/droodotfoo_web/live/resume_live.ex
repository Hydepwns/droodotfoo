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

  alias Droodotfoo.Resume.{FilterEngine, PDFGenerator, PresetManager, ResumeData, SearchIndex}
  alias DroodotfooWeb.SEO.JsonLD

  @impl true
  def mount(_params, _session, socket) do
    formats = ResumeData.get_resume_formats()
    selected_format = "technical"
    resume_data = ResumeData.get_resume_data()
    technologies = SearchIndex.extract_technologies(resume_data)
    presets = PresetManager.list_presets()

    # Generate JSON-LD schemas for resume page
    json_ld = [
      JsonLD.person_schema(),
      JsonLD.breadcrumb_schema([
        {"Home", "/"},
        {"Resume", "/resume"}
      ])
    ]

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
     |> assign(:presets, presets)
     |> assign(:active_filters, %{})
     |> assign(:selected_technologies, [])
     |> assign(:search_query, "")
     |> assign(:match_count, nil)
     |> assign(:show_filters, true)
     |> assign(:page_title, "Resume")
     |> assign(:current_path, "/resume")
     |> assign(:json_ld, json_ld)
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
  def handle_event("toggle_filters", _params, socket) do
    {:noreply, assign(socket, :show_filters, !socket.assigns.show_filters)}
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
  def handle_event("load_preset", %{"preset" => preset_name}, socket) do
    case PresetManager.load_preset(preset_name) do
      {:ok, filters} ->
        # Extract technologies from filters
        technologies = Map.get(filters, :technologies, [])
        search = Map.get(filters, :text_search, "")

        socket =
          socket
          |> assign(:selected_technologies, technologies)
          |> assign(:search_query, search)
          |> assign(:active_filters, filters)
          |> apply_filters()

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("quick_filter", %{"type" => filter_type}, socket) do
    case filter_type do
      "recent" ->
        today = Date.utc_today() |> Date.to_iso8601()

        filters = %{
          date_range: %{from: "2022-01", to: today}
        }

        socket =
          socket
          |> assign(:active_filters, filters)
          |> apply_filters()

        {:noreply, socket}

      "web3" ->
        socket =
          socket
          |> assign(:selected_technologies, ["Elixir", "Rust", "Go", "Solidity"])
          |> apply_filters()

        {:noreply, socket}

      _ ->
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
      page_title="Resume Export & Filtering"
      page_description="Filter your resume content and export in multiple formats"
    >
      <!-- Filter Panel -->
      <div class="filter-panel">
        <div class="filter-header">
          <h3>Filter Resume Content</h3>
          <button class="toggle-filters-btn" phx-click="toggle_filters">
            {if @show_filters, do: "Hide Filters", else: "Show Filters"}
          </button>
        </div>

        <%= if @show_filters do %>
          <div class="filter-content">
            <!-- Search Bar -->
            <div class="search-section">
              <form phx-change="search_resume" phx-submit="search_resume">
                <input
                  type="text"
                  name="search[query]"
                  value={@search_query}
                  placeholder="Search resume (e.g., blockchain, submarine, engineering...)"
                  class="search-input"
                  autocomplete="off"
                />
              </form>
            </div>
            
    <!-- Quick Filter Presets -->
            <div class="presets-section">
              <h4>Quick Filters</h4>
              <div class="preset-buttons">
                <%= for preset <- Enum.take(@presets, 5) do %>
                  <button
                    class="preset-btn"
                    phx-click="load_preset"
                    phx-value-preset={preset.name}
                    title={preset.description}
                  >
                    {preset.name}
                  </button>
                <% end %>
              </div>
            </div>
            
    <!-- Technology Filters -->
            <div class="tech-filters-section">
              <h4>Filter by Technology ({length(@technologies.all)} total)</h4>
              <.tech_chips
                technologies={Enum.take(@technologies.all, 20)}
                selected={@selected_technologies}
                click_event="toggle_technology"
              />
            </div>
            
    <!-- Active Filters Display -->
            <%= if @match_count do %>
              <div class="active-filters">
                <div class="match-count">
                  Found {@match_count} matches
                </div>
                <button class="clear-filters-btn" phx-click="clear_filters">
                  Clear All Filters
                </button>
              </div>
            <% end %>
          </div>
        <% end %>
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
              Generate PDF {if @filtered_data, do: "(Filtered)", else: ""}
            <% end %>
          </button>

          <%= if @download_ready do %>
            <a
              href={"/resume/download?format=#{@selected_format}"}
              class="download-btn"
              download={"resume_#{@selected_format}.pdf"}
            >
              Download PDF
            </a>
          <% end %>
        </div>
      </div>
      
    <!-- Filter Results Display -->
      <%= if @filtered_data do %>
        <div class="filter-results">
          <h3>Filtered Results ({@match_count} matches)</h3>

          <%= if length(@filtered_data.experience) > 0 do %>
            <div class="results-section">
              <h4>Experience ({length(@filtered_data.experience)} matches)</h4>
              <div class="results-list">
                <%= for exp <- @filtered_data.experience do %>
                  <div class="result-item">
                    <strong>{exp.position}</strong> at {exp.company}
                    <span class="date-range">({exp.start_date} - {exp.end_date})</span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <%= if length(@filtered_data.education) > 0 do %>
            <div class="results-section">
              <h4>Education ({length(@filtered_data.education)} matches)</h4>
              <div class="results-list">
                <%= for edu <- @filtered_data.education do %>
                  <div class="result-item">
                    <strong>{edu.degree}</strong> in {edu.field}
                    <span>from {edu.institution}</span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <%= if map_size(@filtered_data.portfolio) > 0 do %>
            <div class="results-section">
              <h4>Portfolio Projects</h4>
              <div class="results-list">
                <%= for project <- Map.get(@filtered_data.portfolio, :projects, []) do %>
                  <div class="result-item">
                    <strong>{project.name}</strong>
                    ({project.language}) <span>{project.description}</span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </.page_layout>
    """
  end
end
