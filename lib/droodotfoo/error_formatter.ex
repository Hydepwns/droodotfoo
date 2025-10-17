defmodule Droodotfoo.ErrorFormatter do
  @moduledoc """
  Formats error messages with friendly ASCII box-drawing and visual indicators.
  Provides consistent, user-friendly error display throughout the terminal UI.
  """

  @type error_type :: :error | :warning | :info | :success
  @type format_opts :: [
          type: error_type(),
          suggestions: [String.t()],
          context: String.t(),
          width: pos_integer()
        ]

  @doc """
  Formats an error message with ASCII box-drawing and styling.

  ## Examples

      iex> ErrorFormatter.format("command not found")
      \"\"\"
      ╔═══════════════════════════════════════════╗
      ║ ERROR                                     ║
      ╠═══════════════════════════════════════════╣
      ║                                           ║
      ║  command not found                        ║
      ║                                           ║
      ╚═══════════════════════════════════════════╝
      \"\"\"

      iex> ErrorFormatter.format("file not found", type: :warning)
      # Returns formatted warning message
  """
  @spec format(String.t(), format_opts()) :: String.t()
  def format(message, opts \\ []) do
    type = Keyword.get(opts, :type, :error)
    suggestions = Keyword.get(opts, :suggestions, [])
    context = Keyword.get(opts, :context)
    width = Keyword.get(opts, :width, 45)

    [
      build_header(type, width),
      build_content(message, width),
      build_context(context, width),
      build_suggestions(suggestions, width),
      build_footer(width)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  @doc """
  Formats a command not found error with suggestions.
  """
  @spec command_not_found(String.t(), [String.t()]) :: String.t()
  def command_not_found(command, suggestions \\ []) do
    message = "Command '#{command}' not found"

    format(message,
      type: :error,
      suggestions: suggestions,
      context: "Type 'help' to see available commands"
    )
  end

  @doc """
  Formats a file system error (file not found, permission denied, etc.).
  """
  @spec file_error(String.t(), String.t()) :: String.t()
  def file_error(operation, reason) do
    message = "#{operation}: #{reason}"
    format(message, type: :error)
  end

  @doc """
  Formats an invalid argument error.
  """
  @spec invalid_args(String.t(), String.t()) :: String.t()
  def invalid_args(command, reason) do
    message = "#{command}: #{reason}"

    format(message,
      type: :error,
      context: "Try '#{command} --help' for usage information"
    )
  end

  @doc """
  Formats a warning message.
  """
  @spec warning(String.t()) :: String.t()
  def warning(message) do
    format(message, type: :warning)
  end

  @doc """
  Formats an info message.
  """
  @spec info(String.t()) :: String.t()
  def info(message) do
    format(message, type: :info)
  end

  @doc """
  Formats a success message.
  """
  @spec success(String.t()) :: String.t()
  def success(message) do
    format(message, type: :success)
  end

  # Private functions

  defp build_header(type, width) do
    {title, icon} = get_type_info(type)
    content = " #{icon} #{title}"
    padded = String.pad_trailing(content, width - 2)

    """
    ╔#{"═" |> String.duplicate(width - 2)}╗
    ║#{padded}║
    ╠#{"═" |> String.duplicate(width - 2)}╣
    """
    |> String.trim_trailing()
  end

  defp build_content(message, width) do
    lines = wrap_text(message, width - 4)

    content_lines =
      [""] ++
        Enum.map(lines, fn line ->
          padded = String.pad_trailing("  #{line}", width - 2)
          "║#{padded}║"
        end) ++
        [""]

    Enum.join(content_lines, "\n")
  end

  defp build_context(nil, _width), do: nil

  defp build_context(context, width) do
    lines = wrap_text(context, width - 4)

    separator = "╠#{String.duplicate("═", width - 2)}╣"

    content_lines =
      Enum.map(lines, fn line ->
        padded = String.pad_trailing("  #{line}", width - 2)
        "║#{padded}║"
      end)

    ([separator] ++ content_lines ++ [""])
    |> Enum.join("\n")
  end

  defp build_suggestions([], _width), do: nil

  defp build_suggestions(suggestions, width) do
    separator = "╠#{String.duplicate("═", width - 2)}╣"
    header = String.pad_trailing("  Did you mean:", width - 2)

    suggestion_lines =
      Enum.map(suggestions, fn suggestion ->
        content = "    • #{suggestion}"
        padded = String.pad_trailing(content, width - 2)
        "║#{padded}║"
      end)

    ([separator, "║#{header}║"] ++ suggestion_lines ++ [""])
    |> Enum.join("\n")
  end

  defp build_footer(width) do
    "╚#{"═" |> String.duplicate(width - 2)}╝"
  end

  defp get_type_info(:error), do: {"ERROR", "█"}
  defp get_type_info(:warning), do: {"WARNING", "!"}
  defp get_type_info(:info), do: {"INFO", "i"}
  defp get_type_info(:success), do: {"SUCCESS", "*"}

  @doc """
  Wraps text to fit within a specified width.
  """
  @spec wrap_text(String.t(), pos_integer()) :: [String.t()]
  def wrap_text(text, max_width) do
    text
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      if String.length(line) <= max_width do
        [line]
      else
        wrap_line(line, max_width)
      end
    end)
  end

  defp wrap_line(line, max_width) do
    words = String.split(line, " ")

    {lines, current} =
      Enum.reduce(words, {[], ""}, fn word, {lines, current} ->
        test_line = if current == "", do: word, else: "#{current} #{word}"

        if String.length(test_line) <= max_width do
          {lines, test_line}
        else
          {lines ++ [current], word}
        end
      end)

    if current == "", do: lines, else: lines ++ [current]
  end
end
