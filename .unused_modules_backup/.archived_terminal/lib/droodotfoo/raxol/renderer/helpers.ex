defmodule Droodotfoo.Raxol.Renderer.Helpers do
  @moduledoc """
  Helper functions shared across renderer modules.
  """

  alias Droodotfoo.TerminalBridge
  alias Droodotfoo.TimeFormatter

  @doc """
  Draw a box of lines at a specific position on the buffer.
  """
  def draw_box_at(buffer, lines, x, y) do
    lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, x, y + idx, line)
    end)
  end

  @doc """
  Format milliseconds into MM:SS time format.
  Delegates to TimeFormatter for consistent time formatting.
  """
  defdelegate format_time(ms), to: TimeFormatter, as: :format_duration_ms

  @doc """
  Format timestamp as relative time ago string.
  Delegates to TimeFormatter for consistent time formatting.
  """
  defdelegate format_time_ago(timestamp), to: TimeFormatter, as: :format_timestamp_ago

  @doc """
  Abbreviate Ethereum address to 0x1234...5678 format.
  Delegates to Core.Utilities for consistency.
  """
  defdelegate abbreviate_address(address), to: Droodotfoo.Core.Utilities

  @doc """
  Get human-readable network name from chain ID.
  Delegates to Web3.Networks for proper domain separation.
  """
  defdelegate get_network_name(chain_id), to: Droodotfoo.Web3.Networks

  @doc """
  Create a progress bar with filled and empty sections.

  ## Examples

      iex> create_progress_bar(75.0, 20)
      "███████████████░░░░░ 75.0%"
  """
  def create_progress_bar(progress, width) do
    filled = round(progress * width / 100)
    empty = width - filled

    filled_chars = String.duplicate("█", filled)
    empty_chars = String.duplicate("░", empty)

    "#{filled_chars}#{empty_chars} #{Float.round(progress, 1)}%"
  end
end
