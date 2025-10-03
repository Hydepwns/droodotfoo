defmodule Droodotfoo.TerminalBridge do
  @moduledoc """
  Converts Raxol terminal buffer to HTML while preserving monospace grid.
  This is the key innovation that bridges Raxol's terminal UI with web rendering.
  Includes caching and virtual DOM diffing for performance.
  """

  use GenServer

  # Cache for commonly used HTML elements
  defstruct [
    :html_char_cache,
    :style_class_cache,
    :previous_buffer,
    :previous_html
  ]

  # Public API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def terminal_to_html(buffer) do
    GenServer.call(__MODULE__, {:render, buffer})
  end

  def invalidate_cache do
    GenServer.cast(__MODULE__, :invalidate_cache)
  end

  # GenServer callbacks
  @impl true
  def init(_opts) do
    state = %__MODULE__{
      html_char_cache: build_char_cache(),
      style_class_cache: %{},
      previous_buffer: nil,
      previous_html: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:render, buffer}, _from, state) do
    {html, new_state} = render_with_diffing(buffer, state)
    {:reply, html, new_state}
  end

  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  @impl true
  def handle_cast(:invalidate_cache, state) do
    new_state = %{
      state
      | html_char_cache: build_char_cache(),
        style_class_cache: %{},
        previous_buffer: nil,
        previous_html: nil
    }

    {:noreply, new_state}
  end

  # Core rendering with virtual DOM diffing
  defp render_with_diffing(buffer, state) do
    case state.previous_buffer do
      nil ->
        # First render - generate full HTML
        html = render_full_buffer(buffer, state)
        new_state = %{state | previous_buffer: buffer, previous_html: html}
        {html, new_state}

      prev_buffer ->
        # Subsequent render - use diffing
        if buffers_identical?(buffer, prev_buffer) do
          # No changes - return cached HTML
          {state.previous_html, state}
        else
          # Changes detected - use smart diffing
          {html, new_state} = render_with_smart_diff(buffer, prev_buffer, state)
          final_state = %{new_state | previous_buffer: buffer, previous_html: html}
          {html, final_state}
        end
    end
  end

  defp render_full_buffer(buffer, state) do
    buffer
    |> get_buffer_lines()
    |> Enum.with_index()
    |> Enum.map(fn {line, line_idx} ->
      line_to_html_optimized(line, line_idx, state)
    end)
    |> wrap_in_grid_container()
  end

  defp render_with_smart_diff(buffer, prev_buffer, state) do
    current_lines = get_buffer_lines(buffer)
    prev_lines = get_buffer_lines(prev_buffer)

    # Find changed lines
    changed_lines = find_changed_lines(current_lines, prev_lines)

    if length(changed_lines) > div(length(current_lines), 3) do
      # More than 1/3 of lines changed - full render is faster
      html = render_full_buffer(buffer, state)
      {html, state}
    else
      # Render only changed lines and patch
      html = patch_html_with_changes(current_lines, changed_lines, state.previous_html, state)
      {html, state}
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

  defp patch_html_with_changes(current_lines, _changed_lines, _prev_html, state) do
    # Always do full render (patch-based rendering would need client-side JS support)
    current_lines
    |> Enum.with_index()
    |> Enum.map(fn {line, line_idx} ->
      line_to_html_optimized(line, line_idx, state)
    end)
    |> wrap_in_grid_container()
  end

  # Optimized line rendering using caches
  defp line_to_html_optimized(line, line_idx, state) do
    cells = line.cells

    # Use IO.iodata for efficient string building
    cell_html =
      cells
      |> Enum.with_index()
      |> Enum.map(fn {cell, cell_idx} ->
        cell_to_html_cached(cell, {line_idx, cell_idx}, state)
      end)

    # Build line HTML efficiently
    [~s(<div class="terminal-line">), cell_html, ~s(</div>)]
  end

  defp cell_to_html_cached(cell, _position, state) do
    # Create cache key from cell content and style
    cache_key = {cell.char, cell.style}

    case Map.get(state.html_char_cache, cache_key) do
      nil ->
        # Generate and cache new HTML
        html = generate_cell_html(cell)
        # Note: In production, we'd update the cache in state
        html

      cached_html ->
        # Return cached HTML
        cached_html
    end
  end

  defp generate_cell_html(%{char: char, style: style}) do
    classes = get_cached_style_classes(style)
    escaped_char = get_cached_escaped_char(char)

    # Use iolist for efficiency
    [~s(<span class="cell ), classes, ~s(">), escaped_char, ~s(</span>)]
  end

  defp get_cached_style_classes(style) do
    # Cache style combinations to avoid repeated string building
    # In a real implementation, this would be stored in process state or ETS
    case style do
      %{bold: false, reverse: false, fg_color: nil, bg_color: nil} ->
        # Most common case - no styling
        ""

      %{bold: true, reverse: false, fg_color: nil, bg_color: nil} ->
        "bold"

      %{bold: false, reverse: true, fg_color: nil, bg_color: nil} ->
        "reverse"

      %{bold: true, reverse: true, fg_color: nil, bg_color: nil} ->
        "bold reverse"

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
      " ",
      "a",
      "e",
      "i",
      "o",
      "u",
      "n",
      "r",
      "t",
      "s",
      "l",
      "0",
      "1",
      "2",
      "3",
      "4",
      "5",
      "6",
      "7",
      "8",
      "9",
      "-",
      "_",
      "=",
      "+",
      "|",
      "\\",
      "/",
      ".",
      ",",
      ":",
      "┌",
      "┐",
      "└",
      "┘",
      "─",
      "│",
      "█",
      "▓",
      "▒",
      "░"
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
    # Handle both style formats
    classes = if Map.get(style, :bold, false), do: ["bold" | classes], else: classes
    classes = if Map.get(style, :italic, false), do: ["italic" | classes], else: classes
    classes = if Map.get(style, :underline, false), do: ["underline" | classes], else: classes
    classes = if Map.get(style, :reverse, false), do: ["reverse" | classes], else: classes

    # Handle both fg_color and color keys
    fg = Map.get(style, :fg_color) || Map.get(style, :color)
    classes = if fg, do: ["fg-#{color_name(fg)}" | classes], else: classes

    # Handle both bg_color and background keys
    bg = Map.get(style, :bg_color) || Map.get(style, :background)
    classes = if bg, do: ["bg-#{color_name(bg)}" | classes], else: classes

    Enum.join(classes, " ")
  end

  defp color_name(color) when is_atom(color), do: color

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
      ~s(<div class="terminal-container" data-grid="true">),
      "\n",
      lines |> Enum.intersperse("\n"),
      "\n",
      ~s(</div>)
    ]
    |> IO.iodata_to_binary()
  end

  @doc """
  Creates a blank terminal buffer of the specified size filled with spaces
  """
  def create_blank_buffer(width \\ 80, height \\ 24) do
    lines =
      for _ <- 1..height do
        cells =
          for _ <- 1..width do
            %{
              char: " ",
              style: %{
                bold: false,
                italic: false,
                underline: false,
                fg_color: nil,
                bg_color: nil,
                reverse: false
              }
            }
          end

        %{cells: cells}
      end

    %{lines: lines, width: width, height: height}
  end

  @doc """
  Writes text to buffer at specified position
  """
  def write_at(buffer, x, y, text) when is_binary(text) do
    lines = buffer.lines
    line = Enum.at(lines, y, %{cells: []})
    cells = line.cells

    # Convert text to cells
    text_chars = String.graphemes(text)

    # Update cells starting at position x
    updated_cells =
      cells
      |> Enum.with_index()
      |> Enum.map(fn {cell, idx} ->
        if idx >= x and idx < x + length(text_chars) do
          char_idx = idx - x
          char = Enum.at(text_chars, char_idx, " ")
          %{cell | char: char}
        else
          cell
        end
      end)

    updated_line = %{line | cells: updated_cells}
    updated_lines = List.replace_at(lines, y, updated_line)

    %{buffer | lines: updated_lines}
  end

  @doc """
  Draws a box with the specified dimensions and style
  """
  def draw_box(buffer, x, y, width, height, style \\ :single) do
    {tl, tr, bl, br, h, v} = box_chars(style)

    buffer
    # Top border
    |> write_at(x, y, tl <> String.duplicate(h, width - 2) <> tr)
    # Side borders
    |> draw_sides(x, y + 1, height - 2, v, width)
    # Bottom border
    |> write_at(x, y + height - 1, bl <> String.duplicate(h, width - 2) <> br)
  end

  defp draw_sides(buffer, _x, _start_y, 0, _v, _width), do: buffer

  defp draw_sides(buffer, x, start_y, rows, v, width) do
    buffer
    |> write_at(x, start_y, v)
    |> write_at(x + width - 1, start_y, v)
    |> draw_sides(x, start_y + 1, rows - 1, v, width)
  end

  defp box_chars(:single), do: {"┌", "┐", "└", "┘", "─", "│"}
  defp box_chars(:double), do: {"╔", "╗", "╚", "╝", "═", "║"}
  defp box_chars(:round), do: {"╭", "╮", "╰", "╯", "─", "│"}
  defp box_chars(_), do: {"+", "+", "+", "+", "-", "|"}
end
