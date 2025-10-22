defmodule Droodotfoo.TimeFormatterTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.TimeFormatter

  describe "format_duration_ms/1" do
    test "formats milliseconds to M:SS format" do
      assert TimeFormatter.format_duration_ms(0) == "0:00"
      assert TimeFormatter.format_duration_ms(1_000) == "0:01"
      assert TimeFormatter.format_duration_ms(59_000) == "0:59"
      assert TimeFormatter.format_duration_ms(60_000) == "1:00"
      assert TimeFormatter.format_duration_ms(65_000) == "1:05"
      assert TimeFormatter.format_duration_ms(125_000) == "2:05"
    end

    test "handles large durations" do
      assert TimeFormatter.format_duration_ms(3_600_000) == "60:00"
      assert TimeFormatter.format_duration_ms(3_661_000) == "61:01"
    end

    test "returns placeholder for invalid input" do
      assert TimeFormatter.format_duration_ms(nil) == "--:--"
      assert TimeFormatter.format_duration_ms("invalid") == "--:--"
      assert TimeFormatter.format_duration_ms(-1) == "--:--"
    end
  end

  describe "format_duration_sec/1" do
    test "formats seconds to M:SS format" do
      assert TimeFormatter.format_duration_sec(0) == "0:00"
      assert TimeFormatter.format_duration_sec(1) == "0:01"
      assert TimeFormatter.format_duration_sec(59) == "0:59"
      assert TimeFormatter.format_duration_sec(60) == "1:00"
      assert TimeFormatter.format_duration_sec(65) == "1:05"
      assert TimeFormatter.format_duration_sec(125) == "2:05"
    end

    test "handles large durations" do
      assert TimeFormatter.format_duration_sec(3600) == "60:00"
      assert TimeFormatter.format_duration_sec(3661) == "61:01"
    end

    test "returns placeholder for invalid input" do
      assert TimeFormatter.format_duration_sec(nil) == "--:--"
      assert TimeFormatter.format_duration_sec("invalid") == "--:--"
      assert TimeFormatter.format_duration_sec(-1) == "--:--"
    end
  end

  describe "format_relative_time/1" do
    test "formats seconds to relative time" do
      assert TimeFormatter.format_relative_time(0) == "0s ago"
      assert TimeFormatter.format_relative_time(30) == "30s ago"
      assert TimeFormatter.format_relative_time(59) == "59s ago"
    end

    test "formats minutes to relative time" do
      assert TimeFormatter.format_relative_time(60) == "1m ago"
      assert TimeFormatter.format_relative_time(120) == "2m ago"
      assert TimeFormatter.format_relative_time(3599) == "59m ago"
    end

    test "formats hours to relative time" do
      assert TimeFormatter.format_relative_time(3600) == "1h ago"
      assert TimeFormatter.format_relative_time(7200) == "2h ago"
      assert TimeFormatter.format_relative_time(86_399) == "23h ago"
    end

    test "formats days to relative time" do
      assert TimeFormatter.format_relative_time(86_400) == "1d ago"
      assert TimeFormatter.format_relative_time(172_800) == "2d ago"
      assert TimeFormatter.format_relative_time(604_800) == "7d ago"
    end
  end

  describe "format_datetime_relative/1" do
    test "formats DateTime to relative time" do
      now = DateTime.utc_now()

      # 30 seconds ago
      dt_30s = DateTime.add(now, -30, :second)
      assert TimeFormatter.format_datetime_relative(dt_30s) == "30s ago"

      # 5 minutes ago
      dt_5m = DateTime.add(now, -300, :second)
      assert TimeFormatter.format_datetime_relative(dt_5m) == "5m ago"

      # 2 hours ago
      dt_2h = DateTime.add(now, -7200, :second)
      assert TimeFormatter.format_datetime_relative(dt_2h) == "2h ago"

      # 3 days ago
      dt_3d = DateTime.add(now, -259_200, :second)
      assert TimeFormatter.format_datetime_relative(dt_3d) == "3d ago"
    end
  end

  describe "format_timestamp_ago/1" do
    test "formats recent timestamps" do
      now = System.system_time(:millisecond)

      # Just now (< 10 seconds)
      assert TimeFormatter.format_timestamp_ago(now) == "just now"
      assert TimeFormatter.format_timestamp_ago(now - 5_000) == "just now"
    end

    test "formats seconds ago" do
      now = System.system_time(:millisecond)

      assert TimeFormatter.format_timestamp_ago(now - 15_000) == "15s ago"
      assert TimeFormatter.format_timestamp_ago(now - 45_000) == "45s ago"
    end

    test "formats minutes ago" do
      now = System.system_time(:millisecond)

      assert TimeFormatter.format_timestamp_ago(now - 120_000) == "2m ago"
      assert TimeFormatter.format_timestamp_ago(now - 1_800_000) == "30m ago"
    end

    test "formats hours ago" do
      now = System.system_time(:millisecond)

      assert TimeFormatter.format_timestamp_ago(now - 7_200_000) == "2h ago"
      assert TimeFormatter.format_timestamp_ago(now - 18_000_000) == "5h ago"
    end

    test "returns never for invalid input" do
      assert TimeFormatter.format_timestamp_ago(nil) == "never"
      assert TimeFormatter.format_timestamp_ago("invalid") == "never"
    end
  end

  describe "format_iso_relative/1" do
    test "formats valid ISO8601 datetime string" do
      # Create a datetime 2 hours ago
      dt = DateTime.utc_now() |> DateTime.add(-7200, :second)
      iso_string = DateTime.to_iso8601(dt)

      result = TimeFormatter.format_iso_relative(iso_string)
      assert result == "2h ago"
    end

    test "returns unknown for invalid datetime strings" do
      assert TimeFormatter.format_iso_relative("invalid") == "unknown"
      assert TimeFormatter.format_iso_relative("2024-13-99") == "unknown"
      assert TimeFormatter.format_iso_relative("") == "unknown"
    end

    test "returns unknown for non-string input" do
      assert TimeFormatter.format_iso_relative(nil) == "unknown"
      assert TimeFormatter.format_iso_relative(123) == "unknown"
    end
  end

  describe "format_human/1" do
    test "formats zero seconds" do
      assert TimeFormatter.format_human(0) == "0 seconds"
    end

    test "formats only seconds" do
      assert TimeFormatter.format_human(1) == "1 second"
      assert TimeFormatter.format_human(5) == "5 seconds"
      assert TimeFormatter.format_human(45) == "45 seconds"
    end

    test "formats minutes and seconds" do
      assert TimeFormatter.format_human(65) == "1 minute, 5 seconds"
      assert TimeFormatter.format_human(125) == "2 minutes, 5 seconds"
    end

    test "formats hours, minutes, and seconds" do
      assert TimeFormatter.format_human(3665) == "1 hour, 1 minute, 5 seconds"
      assert TimeFormatter.format_human(7325) == "2 hours, 2 minutes, 5 seconds"
    end

    test "formats only hours" do
      assert TimeFormatter.format_human(3600) == "1 hour"
      assert TimeFormatter.format_human(7200) == "2 hours"
    end

    test "formats hours and minutes" do
      assert TimeFormatter.format_human(3660) == "1 hour, 1 minute"
      assert TimeFormatter.format_human(7320) == "2 hours, 2 minutes"
    end

    test "formats only minutes" do
      assert TimeFormatter.format_human(60) == "1 minute"
      assert TimeFormatter.format_human(120) == "2 minutes"
    end
  end
end
