defmodule Droodotfoo.Raxol.Config do
  @moduledoc """
  Central configuration and constants for the Raxol terminal rendering system.
  """

  # Terminal dimensions
  @width 110
  @height 45
  # Maximum height for scrollable content (experience, projects, etc.)
  @max_scrollable_height 200

  # Layout positions
  @nav_y 13
  @nav_width 30
  @nav_height 9

  @content_x 35
  @content_y 13

  @status_bar_y @height - 2
  @command_line_y @height - 1

  # STL Viewer viewport dimensions and position
  # Matches box drawing at "│  ┌─ 3D Viewport ─..."
  @stl_viewport_x 37
  # Row where viewport box starts
  @stl_viewport_y 26
  @stl_viewport_width 60
  @stl_viewport_height 8

  @doc """
  Returns the terminal width in characters.
  """
  def width, do: @width

  @doc """
  Returns the terminal height in characters.
  """
  def height, do: @height

  @doc """
  Returns the maximum scrollable height for content sections.
  Used when rendering sections that may exceed viewport height.
  """
  def max_scrollable_height, do: @max_scrollable_height

  @doc """
  Returns the navigation panel Y position.
  """
  def nav_y, do: @nav_y

  @doc """
  Returns the navigation panel width.
  """
  def nav_width, do: @nav_width

  @doc """
  Returns the navigation panel height.
  """
  def nav_height, do: @nav_height

  @doc """
  Returns the content area X position.
  """
  def content_x, do: @content_x

  @doc """
  Returns the content area Y position.
  """
  def content_y, do: @content_y

  @doc """
  Returns the status bar Y position.
  """
  def status_bar_y, do: @status_bar_y

  @doc """
  Returns the command line Y position.
  """
  def command_line_y, do: @command_line_y

  @doc """
  Returns the available content viewport height in rows.
  Calculates: height - content_y - 2 (leaving 2 rows for status bar + command bar)
  Content spans from row 13 to row 42 (30 rows total)
  """
  def content_viewport_height do
    @height - @content_y - 2
  end

  @doc """
  Returns STL viewer viewport configuration as a map.
  """
  def stl_viewport do
    %{
      x: @stl_viewport_x,
      y: @stl_viewport_y,
      width: @stl_viewport_width,
      height: @stl_viewport_height
    }
  end

  @doc """
  Returns all terminal dimensions as a map.
  """
  def dimensions do
    %{
      width: @width,
      height: @height
    }
  end

  @doc """
  Returns all layout positions as a map.
  """
  def layout do
    %{
      nav: %{x: 0, y: @nav_y, width: @nav_width, height: @nav_height},
      content: %{x: @content_x, y: @content_y},
      status_bar: %{y: @status_bar_y},
      command_line: %{y: @command_line_y},
      stl_viewport: stl_viewport()
    }
  end
end
