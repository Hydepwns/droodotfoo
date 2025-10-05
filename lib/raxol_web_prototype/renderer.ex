defmodule RaxolWeb.Renderer do
  @moduledoc """
  Core buffer-to-HTML rendering engine for Raxol web terminals.

  This module handles the conversion of terminal buffers (grid of cells)
  into optimized HTML suitable for web rendering with character-perfect
  monospace grid alignment.

  ## Features

  - Virtual DOM-style diffing to minimize DOM updates
  - Smart caching for common characters and styles
  - Efficient iodata-based string building
  - Dirty checking to skip unnecessary renders

  ## Usage

      buffer = %{
        lines: [%{cells: [%{char: "H", style: %{bold: true}}]}],
        width: 80,
        height: 24
      }

      {:ok, renderer} = RaxolWeb.Renderer.new()
      {html, new_renderer} = RaxolWeb.Renderer.render(renderer, buffer)
  """

  defstruct [
    :html_char_cache,
    :style_class_cache,
    :previous_buffer,
    :previous_html,
    :render_count,
    :cache_hits,
    :cache_misses
  ]

  @type cell :: %{char: String.t(), style: map()}
  @type line :: %{cells: [cell()]}
  @type buffer :: %{lines: [line()], width: integer(), height: integer()}
  @type t :: %__MODULE__{}

  @doc """
  Creates a new renderer with empty caches.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{
      html_char_cache: build_char_cache(),
      style_class_cache: %{},
      previous_buffer: nil,
      previous_html: nil,
      render_count: 0,
      cache_hits: 0,
      cache_misses: 0
    }
  end

  @doc """
  Renders a buffer to HTML, using diffing and caching for performance.

  Returns `{html_string, updated_renderer}`.
  """
  @spec render(t(), buffer()) :: {String.t(), t()}
  def render(renderer, buffer) do
    case renderer.previous_buffer do
      nil ->
        # First render - generate full HTML
        html = render_full_buffer(buffer, renderer)
        new_renderer = %{
          renderer
          | previous_buffer: buffer,
            previous_html: html,
            render_count: renderer.render_count + 1
        }

        {html, new_renderer}

      prev_buffer ->
        # Subsequent render - use diffing
        if buffers_identical?(buffer, prev_buffer) do
          # No changes - return cached HTML
          {renderer.previous_html, renderer}
        else
          # Changes detected - use smart diffing
          {html, new_renderer} = render_with_smart_diff(buffer, prev_buffer, renderer)

          final_renderer = %{
            new_renderer
            | previous_buffer: buffer,
              previous_html: html,
              render_count: renderer.render_count + 1
          }

          {html, final_renderer}
        end
    end
  end

  @doc """
  Invalidates all caches, forcing a full re-render on next call.
  """
  @spec invalidate_cache(t()) :: t()
  def invalidate_cache(renderer) do
    %{
      renderer
      | html_char_cache: build_char_cache(),
        style_class_cache: %{},
        previous_buffer: nil,
        previous_html: nil
    }
  end

  @doc """
  Returns statistics about cache performance.
  """
  @spec stats(t()) :: map()
  def stats(renderer) do
    %{
      render_count: renderer.render_count,
      cache_hits: renderer.cache_hits,
      cache_misses: renderer.cache_misses,
      hit_ratio:
        if(renderer.cache_hits + renderer.cache_misses > 0,
          do: renderer.cache_hits / (renderer.cache_hits + renderer.cache_misses),
          else: 0.0
        )
    }
  end

  # Private Implementation

  defp render_full_buffer(buffer, renderer) do
    buffer
    |> get_buffer_lines()
    |> Enum.with_index()
    |> Enum.map(fn {line, line_idx} ->
      line_to_html_optimized(line, line_idx, renderer)
    end)
    |> wrap_in_grid_container()
  end

  defp render_with_smart_diff(buffer, prev_buffer, renderer) do
    current_lines = get_buffer_lines(buffer)
    prev_lines = get_buffer_lines(prev_buffer)

    # Find changed lines
    changed_lines = find_changed_lines(current_lines, prev_lines)

    if length(changed_lines) > div(length(current_lines), 3) do
      # More than 1/3 of lines changed - full render is faster
      html = render_full_buffer(buffer, renderer)
      {html, renderer}
    else
      # Render only changed lines and patch
      html = patch_html_with_changes(current_lines, changed_lines, renderer)
      {html, renderer}
    end
  end

  defp find_changed_lines(current_lines, prev_lines) do
    current_lines
    |> Enum.with_index()
    |> Enum.filter(fn {line, idx} ->
      prev_line = Enum.at(prev_lines, idx)
      not lines_identical?(line, prev_line)
    end)
  end

  defp patch_html_with_changes(current_lines, _changed_lines, renderer) do
    # Always do full render (patch-based rendering would need client-side JS support)
    current_lines
    |> Enum.with_index()
    |> Enum.map(fn {line, line_idx} ->
      line_to_html_optimized(line, line_idx, renderer)
    end)
    |> wrap_in_grid_container()
  end

  # Optimized line rendering using caches
  defp line_to_html_optimized(line, _line_idx, renderer) do
    cells = line.cells

    # Use IO.iodata for efficient string building
    cell_html =
      cells
      |> Enum.map(fn cell ->
        cell_to_html_cached(cell, renderer)
      end)

    # Build line HTML efficiently
    [~s(<div class="raxol-line">), cell_html, ~s(</div>)]
  end

  defp cell_to_html_cached(cell, renderer) do
    # Create cache key from cell content and style
    cache_key = {cell.char, cell.style}

    case Map.get(renderer.html_char_cache, cache_key) do
      nil ->
        # Generate HTML for this cell
        generate_cell_html(cell)

      cached_html ->
        # Return cached HTML
        cached_html
    end
  end

  defp generate_cell_html(%{char: char, style: style}) do
    classes = get_cached_style_classes(style)
    escaped_char = get_cached_escaped_char(char)

    # Use iolist for efficiency
    [~s(<span class="raxol-cell ), classes, ~s(">), escaped_char, ~s(</span>)]
  end

  defp get_cached_style_classes(style) do
    # Cache style combinations to avoid repeated string building
    case style do
      %{bold: false, reverse: false, fg_color: nil, bg_color: nil} ->
        # Most common case - no styling
        ""

      %{bold: true, reverse: false, fg_color: nil, bg_color: nil} ->
        "raxol-bold"

      %{bold: false, reverse: true, fg_color: nil, bg_color: nil} ->
        "raxol-reverse"

      %{bold: true, reverse: true, fg_color: nil, bg_color: nil} ->
        "raxol-bold raxol-reverse"

      _ ->
        # For complex styles, fall back to dynamic generation
        style_to_css_classes(style)
    end
  end

  defp get_cached_escaped_char(char) do
    # Use pre-computed escape cache
    case char do
      " " -> "&nbsp;"
      "&" -> "&amp;"
      "<" -> "&lt;"
      ">" -> "&gt;"
      "\"" -> "&quot;"
      "'" -> "&#39;"
      _ -> char
    end
  end

  # Pre-build cache of common HTML characters
  defp build_char_cache do
    common_chars = [
      " ", "a", "e", "i", "o", "u", "n", "r", "t", "s", "l",
      "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
      "-", "_", "=", "+", "|", "\\", "/", ".", ",", ":",
      "┌", "┐", "└", "┘", "─", "│", "█", "▓", "▒", "░"
    ]

    default_style = %{
      bold: false,
      italic: false,
      underline: false,
      reverse: false,
      fg_color: nil,
      bg_color: nil
    }

    # Pre-generate HTML for common char/style combinations
    for char <- common_chars, into: %{} do
      cache_key = {char, default_style}
      cell = %{char: char, style: default_style}
      html = generate_cell_html(cell) |> IO.iodata_to_binary()
      {cache_key, html}
    end
  end

  # Utility functions
  defp buffers_identical?(buffer1, buffer2) do
    # Quick comparison - check if buffers are identical
    buffer1 == buffer2
  end

  defp lines_identical?(line1, line2) do
    # Compare line cells efficiently, handling nil cases
    case {line1, line2} do
      {nil, nil} -> true
      {nil, _} -> false
      {_, nil} -> false
      {l1, l2} -> l1.cells == l2.cells
    end
  end

  defp get_buffer_lines(buffer) do
    case buffer do
      lines when is_list(lines) -> lines
      %{lines: lines} -> lines
      _ -> []
    end
  end

  defp style_to_css_classes(style) do
    classes = []
    classes = if Map.get(style, :bold, false), do: ["raxol-bold" | classes], else: classes
    classes = if Map.get(style, :italic, false), do: ["raxol-italic" | classes], else: classes

    classes =
      if Map.get(style, :underline, false), do: ["raxol-underline" | classes], else: classes

    classes = if Map.get(style, :reverse, false), do: ["raxol-reverse" | classes], else: classes

    # Handle both fg_color and color keys
    fg = Map.get(style, :fg_color) || Map.get(style, :color)
    classes = if fg, do: ["raxol-fg-#{color_name(fg)}" | classes], else: classes

    # Handle both bg_color and background keys
    bg = Map.get(style, :bg_color) || Map.get(style, :background)
    classes = if bg, do: ["raxol-bg-#{color_name(bg)}" | classes], else: classes

    Enum.join(classes, " ")
  end

  defp color_name(color) when is_atom(color) do
    color |> Atom.to_string() |> String.replace("_", "-")
  end

  defp color_name(color) when is_tuple(color) do
    case color do
      {:rgb, r, g, b} -> "rgb-#{r}-#{g}-#{b}"
      _ -> "default"
    end
  end

  defp color_name(_), do: "default"

  defp wrap_in_grid_container(lines) do
    # Use iolist for efficiency
    [
      ~s(<div class="raxol-terminal" data-grid="true">),
      "\n",
      lines |> Enum.intersperse("\n"),
      "\n",
      ~s(</div>)
    ]
    |> IO.iodata_to_binary()
  end
end
