defmodule Droodotfoo.AsciiChartTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.AsciiChart

  describe "sparkline/2" do
    test "generates sparkline from data" do
      data = [1, 2, 3, 4, 5]
      result = AsciiChart.sparkline(data)

      # Should return 5 block characters
      assert String.length(result) == 5
      # Should contain ASCII block characters
      assert result =~ ~r/[_.=+*#^-]/
    end

    test "handles empty data" do
      assert AsciiChart.sparkline([]) == ""
    end

    test "handles single value" do
      assert AsciiChart.sparkline([5]) == "-"
    end

    test "respects width option" do
      data = Enum.to_list(1..100)
      result = AsciiChart.sparkline(data, width: 20)

      assert String.length(result) == 20
    end

    test "handles all same values" do
      data = [5, 5, 5, 5, 5]
      result = AsciiChart.sparkline(data)

      # All same values should produce middle block
      assert String.length(result) == 5
    end
  end

  describe "bar_chart/2" do
    test "generates full bar at 100%" do
      result = AsciiChart.bar_chart(100, max: 100, width: 10)

      assert result == "##########"
    end

    test "generates half bar at 50%" do
      result = AsciiChart.bar_chart(50, max: 100, width: 10)

      assert result == "#####....."
    end

    test "generates empty bar at 0%" do
      result = AsciiChart.bar_chart(0, max: 100, width: 10)

      assert result == ".........."
    end

    test "handles values over max" do
      result = AsciiChart.bar_chart(150, max: 100, width: 10)

      # Should cap at full width
      assert result == "##########"
    end
  end

  describe "percent_bar/3" do
    test "generates labeled percent bar" do
      result = AsciiChart.percent_bar("Memory", 75.5, width: 20, label_width: 10)

      assert result =~ "Memory"
      assert result =~ "75.5%"
      assert result =~ ~r/[#.]/
    end

    test "pads label to specified width" do
      result = AsciiChart.percent_bar("CPU", 50, width: 10, label_width: 10)

      # Label should be padded to 10 chars
      assert String.starts_with?(result, "CPU       ")
    end
  end

  describe "threshold_indicator/2" do
    test "returns good indicator for low values" do
      assert AsciiChart.threshold_indicator(10, good: 0, warning: 50, critical: 80) == "+"
    end

    test "returns warning indicator for medium values" do
      assert AsciiChart.threshold_indicator(60, good: 0, warning: 50, critical: 80) == "*"
    end

    test "returns critical indicator for high values" do
      assert AsciiChart.threshold_indicator(90, good: 0, warning: 50, critical: 80) == "!"
    end
  end
end
