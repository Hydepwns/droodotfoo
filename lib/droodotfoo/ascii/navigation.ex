defmodule Droodotfoo.Ascii.Navigation do
  @moduledoc """
  Section navigation indicators and breadcrumbs for ASCII UI.
  """

  @section_names %{
    home: "Home",
    projects: "Projects",
    skills: "Skills",
    experience: "Experience",
    contact: "Contact",
    help: "Help",
    terminal: "Terminal",
    matrix: "Matrix",
    ssh: "SSH",
    ls: "Directory",
    performance: "Performance",
    analytics: "Analytics"
  }

  @doc """
  Create a section transition indicator/breadcrumb.
  Shows current section with styling.

  ## Examples

      section_indicator(:home, :projects)
      # => "> Home -> Projects"
  """
  @spec section_indicator(atom(), atom()) :: String.t()
  def section_indicator(from_section, to_section) do
    from_name = format_section_name(from_section)
    to_name = format_section_name(to_section)
    "> #{from_name} -> #{to_name}"
  end

  @doc """
  Create a breadcrumb bar showing current location.

  ## Options
  - `:width` - Bar width (default: 60)

  ## Examples

      breadcrumb(:projects)
      # => "+- > Projects -+"
  """
  @spec breadcrumb(atom(), keyword()) :: String.t()
  def breadcrumb(current_section, opts \\ []) do
    width = Keyword.get(opts, :width, 60)
    section_name = format_section_name(current_section)

    content = " > #{section_name} "
    padding_needed = max(0, width - String.length(content) - 4)
    left_pad = div(padding_needed, 2)
    right_pad = padding_needed - left_pad

    "+-#{String.duplicate("-", left_pad)}#{content}#{String.duplicate("-", right_pad)}+"
  end

  @doc """
  Create a navigation hint bar.

  ## Options
  - `:width` - Bar width (default: 60)

  ## Examples

      nav_hint("Up/Down Navigate  Enter Select  : Command")
      # => "| > Up/Down Navigate  Enter Select  : Command          |"
  """
  @spec nav_hint(String.t(), keyword()) :: String.t()
  def nav_hint(text, opts \\ []) do
    width = Keyword.get(opts, :width, 60)
    content = " > #{text}"
    padded = String.pad_trailing(content, width - 2)
    "|#{padded}|"
  end

  @doc """
  Format a section name for display.
  """
  @spec format_section_name(atom()) :: String.t()
  def format_section_name(section) do
    Map.get(@section_names, section, section |> to_string() |> String.capitalize())
  end
end
