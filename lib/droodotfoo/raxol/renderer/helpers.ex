defmodule Droodotfoo.Raxol.Renderer.Helpers do
  @moduledoc """
  Helper functions shared across renderer modules.
  """

  alias Droodotfoo.TerminalBridge

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
  """
  def format_time(ms) when is_integer(ms) do
    total_seconds = div(ms, 1000)
    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(seconds), 2, "0")}"
  end

  def format_time(_), do: "--:--"

  @doc """
  Format timestamp as relative time ago string.
  """
  def format_time_ago(timestamp) when is_integer(timestamp) do
    now = System.system_time(:millisecond)
    diff_ms = now - timestamp
    diff_seconds = div(diff_ms, 1000)

    cond do
      diff_seconds < 10 ->
        "just now"

      diff_seconds < 60 ->
        "#{diff_seconds}s ago"

      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        "#{minutes}m ago"

      true ->
        hours = div(diff_seconds, 3600)
        "#{hours}h ago"
    end
  end

  def format_time_ago(_), do: "never"

  @doc """
  Abbreviate Ethereum address to 0x1234...5678 format.
  """
  def abbreviate_address(address) when is_binary(address) do
    if String.length(address) > 12 do
      prefix = String.slice(address, 0..5)
      suffix = String.slice(address, -4..-1)
      "#{prefix}...#{suffix}"
    else
      address
    end
  end

  def abbreviate_address(_), do: "Unknown"

  @doc """
  Get human-readable network name from chain ID.
  """
  def get_network_name(1), do: "Ethereum Mainnet"
  def get_network_name(5), do: "Hoodi Testnet"
  def get_network_name(11_155_111), do: "Sepolia Testnet"
  def get_network_name(137), do: "Polygon Mainnet"
  def get_network_name(80_001), do: "Mumbai Testnet"
  def get_network_name(42_161), do: "Arbitrum One"
  def get_network_name(10), do: "Optimism"
  def get_network_name(8453), do: "Base"
  def get_network_name(chain_id), do: "Chain ID: #{chain_id}"

  @doc """
  Wrap text to fit within a specific width, preserving words.
  """
  def wrap_text(text, width) do
    text
    |> String.split(" ")
    |> Enum.reduce({[], ""}, fn word, {lines, current_line} ->
      test_line = if current_line == "", do: word, else: current_line <> " " <> word

      if String.length(test_line) <= width - 4 do
        {lines, test_line}
      else
        {lines ++ ["│  #{String.pad_trailing(current_line, width)}│"], word}
      end
    end)
    |> then(fn {lines, last_line} ->
      if last_line != "" do
        lines ++ ["│  #{String.pad_trailing(last_line, width)}│"]
      else
        lines
      end
    end)
  end

  @doc """
  Create a progress bar with filled and empty sections.
  """
  def create_progress_bar(progress, width) do
    filled = round(progress * width / 100)
    empty = width - filled

    filled_chars = String.duplicate("█", filled)
    empty_chars = String.duplicate("░", empty)

    "#{filled_chars}#{empty_chars} #{Float.round(progress, 1)}%"
  end

  @doc """
  Format a terminal line, truncating if necessary.
  """
  def format_terminal_line(line) do
    String.slice(line, 0..44)
  end
end
