defmodule Droodotfoo.TerminalTestHelpers do
  @moduledoc """
  Semantic test helpers for terminal UI assertions.

  These helpers provide more resilient assertions that check for intent
  rather than exact string matches, making tests less brittle when UI text changes.
  """

  @doc """
  Checks if buffer or HTML contains status bar hints (help, cmd, search).
  """
  def has_status_bar_hints?(content) when is_binary(content) do
    String.contains?(content, "help") or
      String.contains?(content, "cmd") or
      String.contains?(content, "search")
  end

  @doc """
  Checks if buffer or HTML shows command mode is active.
  """
  def in_command_mode?(content) when is_binary(content) do
    String.contains?(content, "terminal-command-line") or
      String.contains?(content, "CMD") or
      String.starts_with?(String.trim(content), ":")
  end

  @doc """
  Checks if buffer or HTML is in navigation mode (not command mode).
  """
  def in_navigation_mode?(content) when is_binary(content) do
    not in_command_mode?(content) and has_status_bar_hints?(content)
  end

  @doc """
  Checks if terminal buffer is rendered (has terminal wrapper or buffer content).
  """
  def terminal_rendered?(content) when is_binary(content) do
    String.contains?(content, "terminal-wrapper") or
      String.contains?(content, "terminal-buffer") or
      String.contains?(content, "┌") or
      String.contains?(content, "╔")
  end

  @doc """
  Extracts buffer text from a buffer struct.
  """
  def buffer_to_text(%{lines: lines}) when is_list(lines) do
    lines
    |> Enum.map(fn line ->
      line.cells
      |> Enum.map(& &1.char)
      |> Enum.join()
    end)
    |> Enum.join("\n")
  end

  def buffer_to_text(_), do: ""

  @doc """
  Checks if buffer dimensions match expected terminal size.
  """
  def has_correct_dimensions?(%{lines: lines}) when is_list(lines) do
    config = Droodotfoo.Raxol.Config.dimensions()

    length(lines) == config.height and
      Enum.all?(lines, fn line ->
        is_map(line) and
          Map.has_key?(line, :cells) and
          length(line.cells) == config.width
      end)
  end

  def has_correct_dimensions?(_), do: false

  @doc """
  Checks if content contains navigation cursor indicator.
  Uses ASCII `>` instead of fancy arrow to match actual implementation.
  """
  def has_navigation_cursor?(content) when is_binary(content) do
    String.contains?(content, ">") and
      (String.contains?(content, "Home") or
         String.contains?(content, "Projects") or
         String.contains?(content, "Skills"))
  end

  @doc """
  Checks if content shows an error message.
  """
  def has_error?(content) when is_binary(content) do
    String.contains?(content, "ERROR") or
      String.contains?(content, "error:") or
      String.match?(content, ~r/\berror\b/i)
  end

  @doc """
  Checks if content shows a success message.
  """
  def has_success?(content) when is_binary(content) do
    String.contains?(content, "SUCCESS") or
      String.contains?(content, "*") and String.contains?(content, "success")
  end

  @doc """
  Checks if content shows a warning message.
  Uses ASCII `!` instead of emoji.
  """
  def has_warning?(content) when is_binary(content) do
    String.contains?(content, "WARNING") or
      String.contains?(content, "!") and String.contains?(content, "warning")
  end

  @doc """
  Checks if content shows performance/metrics data.
  """
  def has_performance_data?(content) when is_binary(content) do
    String.contains?(content, "PERFORMANCE") or
      String.contains?(content, "Memory") or
      String.contains?(content, "Render")
  end

  @doc """
  Checks if content shows the help modal.
  """
  def help_modal_open?(content) when is_binary(content) do
    String.contains?(content, "KEYBOARD SHORTCUTS") or
      String.contains?(content, "HELP")
  end
end
