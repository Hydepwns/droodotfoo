defmodule Droodotfoo.TimeFormatter do
  @moduledoc """
  Time and duration formatting utilities.
  Provides consistent time display across the application.
  """

  @doc """
  Formats duration in milliseconds to M:SS format.

  ## Examples

      iex> Droodotfoo.TimeFormatter.format_duration_ms(65_000)
      "1:05"

      iex> Droodotfoo.TimeFormatter.format_duration_ms(3_661_000)
      "61:01"

      iex> Droodotfoo.TimeFormatter.format_duration_ms(nil)
      "--:--"

      iex> Droodotfoo.TimeFormatter.format_duration_ms(0)
      "0:00"
  """
  def format_duration_ms(ms) when is_integer(ms) and ms >= 0 do
    total_seconds = div(ms, 1000)
    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(seconds), 2, "0")}"
  end

  def format_duration_ms(_), do: "--:--"

  @doc """
  Formats duration in seconds to M:SS format.

  ## Examples

      iex> Droodotfoo.TimeFormatter.format_duration_sec(65)
      "1:05"

      iex> Droodotfoo.TimeFormatter.format_duration_sec(3661)
      "61:01"
  """
  def format_duration_sec(seconds) when is_integer(seconds) and seconds >= 0 do
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(secs), 2, "0")}"
  end

  def format_duration_sec(_), do: "--:--"

  @doc """
  Formats duration in seconds to relative time (e.g., "5m ago", "2h ago").

  ## Examples

      iex> Droodotfoo.TimeFormatter.format_relative_time(45)
      "45s ago"

      iex> Droodotfoo.TimeFormatter.format_relative_time(3600)
      "1h ago"

      iex> Droodotfoo.TimeFormatter.format_relative_time(86400)
      "1d ago"

      iex> Droodotfoo.TimeFormatter.format_relative_time(604800)
      "7d ago"
  """
  def format_relative_time(seconds) when seconds < 60, do: "#{seconds}s ago"
  def format_relative_time(seconds) when seconds < 3600, do: "#{div(seconds, 60)}m ago"
  def format_relative_time(seconds) when seconds < 86_400, do: "#{div(seconds, 3600)}h ago"
  def format_relative_time(seconds), do: "#{div(seconds, 86_400)}d ago"

  @doc """
  Formats a DateTime to relative time from now.

  ## Examples

      iex> dt = DateTime.utc_now() |> DateTime.add(-3600, :second)
      iex> Droodotfoo.TimeFormatter.format_datetime_relative(dt)
      "1h ago"
  """
  def format_datetime_relative(%DateTime{} = dt) do
    diff = DateTime.diff(DateTime.utc_now(), dt)
    format_relative_time(diff)
  end

  @doc """
  Formats a millisecond timestamp as relative time ago string.

  ## Examples

      iex> ts = System.system_time(:millisecond) - 3600_000
      iex> Droodotfoo.TimeFormatter.format_timestamp_ago(ts)
      "1h ago"
  """
  def format_timestamp_ago(timestamp) when is_integer(timestamp) do
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

  def format_timestamp_ago(_), do: "never"

  @doc """
  Parses ISO8601 datetime string and formats as relative time.

  ## Examples

      iex> Droodotfoo.TimeFormatter.format_iso_relative("2024-01-01T00:00:00Z")
      # Returns something like "45d ago" depending on current time
  """
  def format_iso_relative(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, dt, _} ->
        format_datetime_relative(dt)

      _ ->
        "unknown"
    end
  end

  def format_iso_relative(_), do: "unknown"

  @doc """
  Formats seconds into human-readable long format.

  ## Examples

      iex> Droodotfoo.TimeFormatter.format_human(65)
      "1 minute, 5 seconds"

      iex> Droodotfoo.TimeFormatter.format_human(3665)
      "1 hour, 1 minute, 5 seconds"
  """
  def format_human(seconds) when is_integer(seconds) and seconds >= 0 do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)

    parts =
      []
      |> add_time_part(hours, "hour")
      |> add_time_part(minutes, "minute")
      |> add_time_part(secs, "second")

    case parts do
      [] -> "0 seconds"
      _ -> Enum.join(parts, ", ")
    end
  end

  defp add_time_part(parts, 0, _unit), do: parts

  defp add_time_part(parts, 1, unit), do: parts ++ ["1 #{unit}"]

  defp add_time_part(parts, value, unit), do: parts ++ ["#{value} #{unit}s"]
end
