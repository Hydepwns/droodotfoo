defmodule DroodotfooWeb.DroodotfooLive.Helpers do
  @moduledoc """
  Utility helper functions for DroodotfooLive.
  Handles breadcrumb conversion, screen reader announcements, and boot sequence rendering.
  """

  alias Droodotfoo.{AdaptiveRefresh, BootSequence}

  @doc """
  Convert section atoms to breadcrumb paths for display.
  """
  def section_to_breadcrumb(:home), do: ["Home"]
  def section_to_breadcrumb(:projects), do: ["Home", "Projects"]
  def section_to_breadcrumb(:skills), do: ["Home", "Skills"]
  def section_to_breadcrumb(:experience), do: ["Home", "Experience"]
  def section_to_breadcrumb(:contact), do: ["Home", "Contact"]
  def section_to_breadcrumb(:terminal), do: ["Home", "Terminal"]
  def section_to_breadcrumb(:search_results), do: ["Home", "Search Results"]
  def section_to_breadcrumb(:performance), do: ["Home", "Performance"]
  def section_to_breadcrumb(:matrix), do: ["Home", "Matrix"]
  def section_to_breadcrumb(:ssh), do: ["Home", "SSH Demo"]
  def section_to_breadcrumb(:analytics), do: ["Home", "Analytics"]
  def section_to_breadcrumb(:help), do: ["Home", "Help"]
  def section_to_breadcrumb(:stl_viewer), do: ["Home", "STL Viewer"]
  def section_to_breadcrumb(_), do: ["Home"]

  @doc """
  Generate screen reader announcements for section changes.
  """
  def announce_section_change(:home), do: "Navigated to Home section"

  def announce_section_change(:projects),
    do: "Navigated to Projects section. Browse my portfolio projects."

  def announce_section_change(:skills),
    do: "Navigated to Skills section. View my technical expertise."

  def announce_section_change(:experience),
    do: "Navigated to Experience section. Review my work history."

  def announce_section_change(:contact),
    do: "Navigated to Contact section. Get in touch with me."

  def announce_section_change(:terminal),
    do: "Navigated to Terminal mode. Interactive command line interface."

  def announce_section_change(:search_results), do: "Showing search results"

  def announce_section_change(:performance),
    do: "Navigated to Performance Dashboard. Real-time metrics and charts."

  def announce_section_change(:matrix), do: "Navigated to Matrix plugin. Digital rain effect."

  def announce_section_change(:help),
    do: "Navigated to Help section. Available commands and keyboard shortcuts."

  def announce_section_change(:stl_viewer),
    do: "Navigated to STL 3D Viewer. Interactive 3D model viewer."

  def announce_section_change(_), do: "Section changed"

  @doc """
  Render boot sequence step to HTML.
  """
  def render_boot_sequence(step) do
    lines = BootSequence.render(step)

    # Convert lines to simple HTML with monospace styling
    Enum.map_join(lines, "\n", fn line ->
      # Escape HTML and preserve spaces
      "<div class=\"terminal-line\">#{Phoenix.HTML.html_escape(line) |> Phoenix.HTML.safe_to_string()}</div>"
    end)
  end

  @doc """
  Schedule next tick based on adaptive refresh rate.
  """
  def schedule_next_tick(adaptive_refresh) do
    interval = AdaptiveRefresh.get_interval_ms(adaptive_refresh)
    Process.send_after(self(), :tick, interval)
  end
end
