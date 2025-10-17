#!/usr/bin/env elixir

defmodule ComplexityAnalyzer do
  @moduledoc """
  Analyzes Elixir codebase for complexity metrics.
  Identifies files that exceed target thresholds for refactoring.
  """

  @line_threshold 600

  defmodule FileMetrics do
    @moduledoc false
    defstruct [
      :path,
      :lines,
      :functions,
      :public_functions,
      :private_functions,
      :sections,
      :complexity_score,
      :needs_refactoring
    ]
  end

  def run(args \\ []) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          threshold: :integer,
          format: :string,
          output: :string,
          verbose: :boolean
        ],
        aliases: [t: :threshold, f: :format, o: :output, v: :verbose]
      )

    threshold = Keyword.get(opts, :threshold, @line_threshold)
    format = Keyword.get(opts, :format, "markdown")
    output = Keyword.get(opts, :output)
    verbose = Keyword.get(opts, :verbose, false)

    IO.puts("\n🔍 Analyzing codebase for complexity...\n")

    # Find all Elixir files
    files =
      Path.wildcard("{lib,test}/**/*.{ex,exs}")
      |> Enum.sort()

    IO.puts("Found #{length(files)} Elixir files\n")

    # Analyze each file
    metrics =
      files
      |> Enum.map(&analyze_file(&1, threshold, verbose))
      |> Enum.filter(& &1)

    # Sort by lines (descending)
    sorted_metrics = Enum.sort_by(metrics, & &1.lines, :desc)

    # Get files over threshold
    over_threshold = Enum.filter(sorted_metrics, & &1.needs_refactoring)

    # Generate report
    case format do
      "json" ->
        generate_json_report(sorted_metrics, over_threshold, threshold, output)

      "markdown" ->
        generate_markdown_report(sorted_metrics, over_threshold, threshold, output)

      _ ->
        IO.puts("Unknown format: #{format}. Use 'json' or 'markdown'")
    end

    # Print summary
    print_summary(sorted_metrics, over_threshold, threshold)

    # Exit with status code based on threshold violations
    if length(over_threshold) > 0, do: System.halt(1), else: System.halt(0)
  end

  defp analyze_file(path, threshold, verbose) do
    content = File.read!(path)
    lines = String.split(content, "\n")
    line_count = length(lines)

    # Count functions
    public_functions = Regex.scan(~r/^\s{2}def\s+([a-z_][a-z0-9_?!]*)/m, content) |> length()

    private_functions =
      Regex.scan(~r/^\s{2}defp\s+([a-z_][a-z0-9_?!]*)/m, content) |> length()

    total_functions = public_functions + private_functions

    # Detect logical sections from comments
    sections =
      Regex.scan(~r/^\s{2}#\s+(.+)/m, content)
      |> Enum.map(fn [_, section] -> String.trim(section) end)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    # Calculate complexity score (higher = more complex)
    # Weight: lines (1x), functions (20x), sections (10x)
    complexity_score =
      line_count * 1 + total_functions * 20 + length(sections) * 10

    needs_refactoring = line_count > threshold

    if verbose do
      status = if needs_refactoring, do: "🔴", else: "✅"
      IO.puts("#{status} #{path}: #{line_count} lines, #{total_functions} functions")
    end

    %FileMetrics{
      path: path,
      lines: line_count,
      functions: total_functions,
      public_functions: public_functions,
      private_functions: private_functions,
      sections: sections,
      complexity_score: complexity_score,
      needs_refactoring: needs_refactoring
    }
  end

  defp generate_markdown_report(metrics, over_threshold, threshold, output_path) do
    report = """
    # Codebase Complexity Analysis Report

    **Generated:** #{DateTime.utc_now() |> DateTime.to_string()}
    **Threshold:** #{threshold} lines per file
    **Total Files:** #{length(metrics)}
    **Files Over Threshold:** #{length(over_threshold)}

    ## Executive Summary

    #{summary_stats(metrics, over_threshold, threshold)}

    ## Files Requiring Refactoring (#{length(over_threshold)})

    #{format_over_threshold_table(over_threshold, threshold)}

    ## Refactoring Recommendations

    #{generate_recommendations(over_threshold)}

    ## All Files Sorted by Complexity

    #{format_all_files_table(metrics)}

    ## Detailed File Analysis

    #{format_detailed_analysis(over_threshold)}
    """

    if output_path do
      File.write!(output_path, report)
      IO.puts("\n📄 Markdown report written to: #{output_path}")
    else
      IO.puts("\n" <> report)
    end
  end

  defp generate_json_report(metrics, over_threshold, threshold, output_path) do
    report = %{
      generated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      threshold: threshold,
      total_files: length(metrics),
      files_over_threshold: length(over_threshold),
      summary: calculate_summary_stats(metrics),
      files: Enum.map(metrics, &format_metric_for_json/1),
      needs_refactoring: Enum.map(over_threshold, &format_metric_for_json/1)
    }

    json = Jason.encode!(report, pretty: true)

    if output_path do
      File.write!(output_path, json)
      IO.puts("\n📄 JSON report written to: #{output_path}")
    else
      IO.puts("\n" <> json)
    end
  end

  defp format_metric_for_json(metric) do
    %{
      path: metric.path,
      lines: metric.lines,
      functions: metric.functions,
      public_functions: metric.public_functions,
      private_functions: metric.private_functions,
      sections: metric.sections,
      complexity_score: metric.complexity_score,
      needs_refactoring: metric.needs_refactoring
    }
  end

  defp summary_stats(metrics, over_threshold, threshold) do
    total_lines = Enum.sum(Enum.map(metrics, & &1.lines))
    avg_lines = div(total_lines, max(length(metrics), 1))
    total_functions = Enum.sum(Enum.map(metrics, & &1.functions))
    percentage_over = Float.round(length(over_threshold) / max(length(metrics), 1) * 100, 1)

    """
    - **Total Lines of Code:** #{total_lines}
    - **Average Lines per File:** #{avg_lines}
    - **Total Functions:** #{total_functions}
    - **Files Over #{threshold} Lines:** #{length(over_threshold)} (#{percentage_over}%)
    """
  end

  defp calculate_summary_stats(metrics) do
    total_lines = Enum.sum(Enum.map(metrics, & &1.lines))
    avg_lines = div(total_lines, max(length(metrics), 1))
    total_functions = Enum.sum(Enum.map(metrics, & &1.functions))

    %{
      total_lines: total_lines,
      average_lines: avg_lines,
      total_functions: total_functions
    }
  end

  defp format_over_threshold_table(over_threshold, threshold) do
    if length(over_threshold) == 0 do
      "✅ No files exceed the #{threshold} line threshold!"
    else
      header = "| Priority | File | Lines | Functions | Sections | Over By |\n"
      separator = "|----------|------|-------|-----------|----------|----------|\n"

      rows =
        over_threshold
        |> Enum.with_index(1)
        |> Enum.map(fn {metric, idx} ->
          over_by = metric.lines - threshold
          priority = get_priority_emoji(metric.lines, threshold)
          sections_count = length(metric.sections)

          "| #{priority} #{idx} | `#{metric.path}` | #{metric.lines} | #{metric.functions} | #{sections_count} | +#{over_by} |"
        end)
        |> Enum.join("\n")

      header <> separator <> rows
    end
  end

  defp format_all_files_table(metrics) do
    header = "| File | Lines | Functions | Status |\n"
    separator = "|------|-------|-----------|--------|\n"

    rows =
      metrics
      |> Enum.take(20)
      |> Enum.map(fn metric ->
        status = if metric.needs_refactoring, do: "🔴 Refactor", else: "✅ OK"
        "| `#{metric.path}` | #{metric.lines} | #{metric.functions} | #{status} |"
      end)
      |> Enum.join("\n")

    header <> separator <> rows
  end

  defp format_detailed_analysis(over_threshold) do
    over_threshold
    |> Enum.with_index(1)
    |> Enum.map(fn {metric, idx} ->
      """
      ### #{idx}. #{Path.basename(metric.path)}

      **Path:** `#{metric.path}`
      **Lines:** #{metric.lines}
      **Functions:** #{metric.functions} (#{metric.public_functions} public, #{metric.private_functions} private)
      **Complexity Score:** #{metric.complexity_score}

      #{if length(metric.sections) > 0 do
        """
        **Detected Sections (#{length(metric.sections)}):**
        #{metric.sections |> Enum.map(&"- #{&1}") |> Enum.join("\n")}

        **Refactoring Strategy:**
        This file has #{length(metric.sections)} logical sections that can be extracted into separate modules.
        """
      else
        "**Refactoring Strategy:** Consider splitting by functional responsibility."
      end}

      ---
      """
    end)
    |> Enum.join("\n")
  end

  defp generate_recommendations(over_threshold) do
    if length(over_threshold) == 0 do
      "✅ All files are within acceptable complexity limits!"
    else
      top_3 = Enum.take(over_threshold, 3)

      recommendations =
        top_3
        |> Enum.with_index(1)
        |> Enum.map(fn {metric, idx} ->
          """
          ### #{idx}. #{Path.basename(metric.path)} (#{metric.lines} lines)

          #{generate_specific_recommendation(metric)}
          """
        end)
        |> Enum.join("\n")

      """
      Focus on these high-priority files first:

      #{recommendations}
      """
    end
  end

  defp generate_specific_recommendation(metric) do
    cond do
      String.contains?(metric.path, "commands.ex") ->
        """
        **Strategy:** Split by command categories (#{length(metric.sections)} sections detected)
        - Create `Commands.Navigation`, `Commands.FileOps`, `Commands.Web3`, etc.
        - Each module should have < 300 lines
        - Use `defdelegate` in main Commands module for backward compatibility
        """

      String.contains?(metric.path, "renderer.ex") ->
        """
        **Strategy:** Extract rendering concerns
        - `Renderer.Core` - main render loop
        - `Renderer.Sections` - section-specific renderers
        - `Renderer.Components` - reusable UI components
        - `Renderer.Formatting` - text formatting utilities
        """

      String.contains?(metric.path, "live.ex") ->
        """
        **Strategy:** Extract LiveView concerns
        - Move event handlers to separate module
        - Extract state processing logic
        - Create dedicated action modules (Web3, Spotify, STL)
        """

      true ->
        """
        **Strategy:** Analyze #{length(metric.sections)} sections and split by responsibility
        - Aim for single-responsibility modules
        - Keep each module under 300 lines
        - Use composition over inheritance
        """
    end
  end

  defp get_priority_emoji(lines, threshold) do
    ratio = lines / threshold

    cond do
      ratio >= 5 -> "🔴🔴🔴"
      ratio >= 3 -> "🔴🔴"
      ratio >= 2 -> "🔴"
      ratio >= 1.5 -> "🟡"
      true -> "🟢"
    end
  end

  defp print_summary(metrics, over_threshold, threshold) do
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("COMPLEXITY ANALYSIS SUMMARY")
    IO.puts(String.duplicate("=", 60))
    IO.puts(summary_stats(metrics, over_threshold, threshold))

    if length(over_threshold) > 0 do
      IO.puts("\n🔴 ACTION REQUIRED: #{length(over_threshold)} files need refactoring\n")

      over_threshold
      |> Enum.take(5)
      |> Enum.each(fn metric ->
        IO.puts(
          "  #{get_priority_emoji(metric.lines, threshold)} #{metric.path} (#{metric.lines} lines)"
        )
      end)
    else
      IO.puts("\n✅ All files are within complexity limits!")
    end

    IO.puts("\n" <> String.duplicate("=", 60))
  end
end

# Check if Jason is available, otherwise provide instructions
case Code.ensure_loaded(Jason) do
  {:module, _} ->
    ComplexityAnalyzer.run(System.argv())

  {:error, _} ->
    IO.puts("""
    ⚠️  Jason library not found.
    To use JSON output, run this script with:
      mix run scripts/analyze_complexity.exs
    Or install Jason: mix deps.get
    """)

    ComplexityAnalyzer.run(System.argv())
end
