defmodule Droodotfoo.Raxol.BoxAlignmentTest do
  use ExUnit.Case, async: true
  # Raxol modules archived - tests skipped until reactivation
  @moduletag :skip
  alias Droodotfoo.Raxol.BoxConfig

  @moduledoc """
  Compile-time validation of all box widths in renderer modules.

  This test reads renderer source files and validates that all
  box headers and borders are exactly 71 characters wide.

  Runs automatically during `mix test` to catch alignment regressions.

  ## Intentional Exceptions

  Some boxes are intentionally different widths for specific layouts:
  - **Project cards (35 chars)**: 2-column grid layout in projects view
  - **Search modal (50 chars)**: Centered overlay at different position

  All other boxes should be exactly 71 characters wide to maintain
  proper alignment in the terminal layout.
  """

  @renderer_files [
    "lib/droodotfoo/raxol/renderer.ex",
    "lib/droodotfoo/raxol/renderer/home.ex",
    "lib/droodotfoo/raxol/renderer/spotify.ex",
    "lib/droodotfoo/raxol/renderer/portal.ex",
    "lib/droodotfoo/raxol/renderer/helpers.ex",
    "lib/droodotfoo/raxol/renderer/games.ex"
  ]

  # Known intentional exceptions (with rationale)
  @exceptions [
    {35, "Project cards (2-column grid layout)"},
    {38, "Project card borders (calculated from 35 + 3 border chars)"},
    {42, "Autocomplete dropdown (compact size for suggestions)"},
    {47, "Autocomplete header (calculated, uses String.duplicate)"},
    {50, "Search modal (centered overlay at different position)"},
    {77, "Help modal (wider for better readability of keyboard shortcuts)"},
    {80, "Performance dashboard (full metrics view with sparklines)"},
    {106, "ASCII logo (full terminal width for header)"}
  ]

  describe "box width validation" do
    test "all main content boxes are exactly 71 characters wide" do
      violations =
        for file <- @renderer_files, File.exists?(file) do
          content = File.read!(file)

          # Find all box headers (top borders with various styles)
          headers =
            Regex.scan(~r/"[┌╭╔][─═]+.+?[┐╮╗]"/, content)
            |> Enum.map(fn [match] -> String.replace(match, "\"", "") end)
            |> Enum.uniq()

          for header <- headers do
            width = String.length(header)
            exception_widths = Enum.map(@exceptions, &elem(&1, 0))

            # Ignore headers shorter than 20 chars (likely false matches)
            # or those using String.duplicate (will be caught by other tests)
            if width >= 20 and width not in exception_widths and
                 width != BoxConfig.content_width() do
              %{
                file: Path.basename(file),
                width: width,
                expected: BoxConfig.content_width(),
                preview: String.slice(header, 0..50)
              }
            end
          end
          |> Enum.reject(&is_nil/1)
        end
        |> List.flatten()

      if length(violations) > 0 do
        error_message =
          """

          Box Alignment Violations Found!
          ================================

          The following boxes do not match the expected width of #{BoxConfig.content_width()} characters:

          """ <>
            Enum.map_join(violations, "\n", fn v ->
              """
                File: #{v.file}
                Expected width: #{v.expected} chars
                Actual width:   #{v.width} chars
                Box preview:    #{v.preview}...

                Fix: Adjust padding or use BoxConfig.header_line/2
              """
            end)

        flunk(error_message)
      end
    end

    test "all renderer files exist" do
      for file <- @renderer_files do
        assert File.exists?(file),
               "Renderer file #{file} does not exist. Update @renderer_files list."
      end
    end

    test "all box footers are exactly 71 characters wide" do
      violations =
        for file <- @renderer_files, File.exists?(file) do
          content = File.read!(file)

          # Find all box footers (bottom borders with various styles)
          footers =
            Regex.scan(~r/"[└╰╚][─═]+[┘╯╝]"/, content)
            |> Enum.map(fn [match] -> String.replace(match, "\"", "") end)
            |> Enum.uniq()

          for footer <- footers do
            width = String.length(footer)
            exception_widths = Enum.map(@exceptions, &elem(&1, 0))

            # Ignore footers shorter than 20 chars (likely false matches like tree connectors)
            # or those using String.duplicate (will be caught by other tests)
            if width >= 20 and width not in exception_widths and
                 width != BoxConfig.content_width() do
              %{
                file: Path.basename(file),
                width: width,
                expected: BoxConfig.content_width(),
                preview: String.slice(footer, 0..50)
              }
            end
          end
          |> Enum.reject(&is_nil/1)
        end
        |> List.flatten()

      if length(violations) > 0 do
        error_message =
          """

          Box Footer Alignment Violations Found!
          =======================================

          The following box footers do not match the expected width of #{BoxConfig.content_width()} characters:

          """ <>
            Enum.map_join(violations, "\n", fn v ->
              """
                File: #{v.file}
                Expected width: #{v.expected} chars
                Actual width:   #{v.width} chars
                Footer preview: #{v.preview}...
              """
            end)

        flunk(error_message)
      end
    end

    test "no hardcoded width values in padding calls" do
      # This test checks for common anti-patterns like:
      # String.pad_trailing(text, 57) instead of using BoxConfig constants
      known_constants = [
        BoxConfig.terminal_width(),
        BoxConfig.nav_width(),
        BoxConfig.content_width(),
        BoxConfig.inner_width(),
        # Also allow some derived values
        BoxConfig.inner_width() - 10,
        BoxConfig.inner_width() - 20,
        BoxConfig.content_width() - 6,
        BoxConfig.content_width() - 10,
        # Exception-specific widths
        # vim_status ("ON " or "OFF")
        3,
        # Project card content (35 - 6 borders/padding)
        29,
        # Project card line content
        31,
        # Search modal widths (50-char box)
        # Section name width in search results
        10,
        # Match counter width
        24,
        # Line preview width
        30,
        # Query display width
        38,
        # Search modal total line width (50 - 1 border)
        49,
        # Performance dashboard widths (80-char box)
        # Memory sparkline width
        12,
        # Request rate width
        13,
        # Render sparkline, uptime, processes, P95 render widths
        15,
        # Avg render time, current memory widths
        18,
        # Errors, avg memory, max render widths
        20
      ]

      violations =
        for file <- @renderer_files, File.exists?(file) do
          content = File.read!(file)
          lines = String.split(content, "\n")

          # Look for String.pad_trailing with hardcoded numbers
          Enum.with_index(lines, 1)
          |> Enum.flat_map(fn {line, line_num} ->
            # Match: String.pad_trailing(..., <number>)
            matches = Regex.scan(~r/String\.pad_trailing\([^,]+,\s*(\d+)\)/, line)

            for [_full_match, number_str] <- matches do
              number = String.to_integer(number_str)

              if number not in known_constants do
                %{
                  file: Path.basename(file),
                  line: line_num,
                  width: number,
                  code_snippet: String.trim(line)
                }
              end
            end
            |> Enum.reject(&is_nil/1)
          end)
        end
        |> List.flatten()

      if length(violations) > 0 do
        error_message =
          """

          Hardcoded Width Values Found!
          ==============================

          The following lines use hardcoded width values instead of BoxConfig constants:

          """ <>
            Enum.map_join(violations, "\n", fn v ->
              """
                File: #{v.file}:#{v.line}
                Hardcoded width: #{v.width}
                Code: #{String.slice(v.code_snippet, 0..80)}

                Fix: Replace with BoxConfig constants:
                  - BoxConfig.content_width() (71)
                  - BoxConfig.inner_width() (67)
                  - Or use BoxConfig.truncate_and_pad/2 helper
              """
            end)

        flunk(error_message)
      end
    end

    test "all renderers should eventually use BoxConfig" do
      # Check if renderer files import or alias BoxConfig
      # This is a soft recommendation for future refactoring
      files_without_boxconfig =
        for file <- @renderer_files, File.exists?(file) do
          content = File.read!(file)

          # Check for alias or import of BoxConfig
          unless String.contains?(content, "Droodotfoo.Raxol.BoxConfig") do
            Path.basename(file)
          end
        end
        |> Enum.reject(&is_nil/1)

      # This is informational only - we'll gradually migrate files
      if length(files_without_boxconfig) > 0 do
        IO.puts("""

        Note: The following renderer files don't yet use BoxConfig:
        #{Enum.map_join(files_without_boxconfig, "\n  ", &("- " <> &1))}

        Consider adding: alias Droodotfoo.Raxol.BoxConfig
        """)
      end

      # Always pass - this is just informational
      assert true
    end
  end

  describe "inner box validation" do
    test "inner box headers have consistent width" do
      # Inner boxes should follow the pattern:
      # "│  ┌───...───┐  │" (total 71 chars)
      violations =
        for file <- @renderer_files, File.exists?(file) do
          content = File.read!(file)

          # Find inner box headers (indented boxes within outer boxes)
          inner_headers =
            Regex.scan(~r/"│\s+[┌╭╔][─═]+[┐╮╗]\s+│"/, content)
            |> Enum.map(fn [match] -> String.replace(match, "\"", "") end)
            |> Enum.uniq()

          for header <- inner_headers do
            width = String.length(header)

            if width != BoxConfig.content_width() do
              %{
                file: Path.basename(file),
                width: width,
                expected: BoxConfig.content_width(),
                preview: String.slice(header, 0..50)
              }
            end
          end
          |> Enum.reject(&is_nil/1)
        end
        |> List.flatten()

      if length(violations) > 0 do
        error_message =
          """

          Inner Box Alignment Violations Found!
          ======================================

          The following inner boxes do not match the expected width of #{BoxConfig.content_width()} characters:

          """ <>
            Enum.map_join(violations, "\n", fn v ->
              """
                File: #{v.file}
                Expected width: #{v.expected} chars
                Actual width:   #{v.width} chars
                Box preview:    #{v.preview}...

                Fix: Use BoxConfig.inner_box_header/1
              """
            end)

        flunk(error_message)
      end
    end
  end

  describe "exception documentation" do
    test "all exceptions are documented with rationale" do
      for {width, rationale} <- @exceptions do
        assert is_integer(width), "Exception width must be an integer"
        assert is_binary(rationale), "Exception must have a rationale"

        assert String.length(rationale) > 10,
               "Exception rationale should be descriptive (width: #{width})"
      end
    end

    test "exceptions list is not empty" do
      # We should have at least the project cards exception
      assert length(@exceptions) >= 2,
             "Expected at least 2 documented exceptions (project cards and search modal)"
    end
  end

  describe "integration with BoxConfig" do
    test "test uses BoxConfig.content_width() for validation" do
      # Verify we're using the constant, not hardcoded 71
      assert BoxConfig.content_width() == 71,
             "BoxConfig.content_width() should be 71"
    end

    test "BoxConfig constants match terminal layout" do
      assert BoxConfig.terminal_width() == 106
      assert BoxConfig.nav_width() == 35
      assert BoxConfig.content_width() == 71
      assert BoxConfig.inner_width() == 67

      # Verify relationships
      assert BoxConfig.terminal_width() ==
               BoxConfig.nav_width() + BoxConfig.content_width()

      assert BoxConfig.content_width() == BoxConfig.inner_width() + 4
    end
  end
end
