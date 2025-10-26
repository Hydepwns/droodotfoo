defmodule Droodotfoo.Performance.MetricsTest do
  use ExUnit.Case, async: false
  alias Droodotfoo.Performance.Metrics

  setup do
    # Clear metrics before each test (process already running from supervision tree)
    Metrics.clear(:all)
    :ok
  end

  describe "timing/4" do
    test "records timing metrics" do
      Metrics.timing(:test_api, :get_data, 150)
      Metrics.timing(:test_api, :get_data, 200)

      stats = Metrics.stats(:test_api, :get_data)

      assert stats.count == 2
      assert stats.min == 150
      assert stats.max == 200
    end
  end

  describe "measure/4" do
    test "measures function duration and returns result" do
      result =
        Metrics.measure(:test_api, :compute, fn ->
          Process.sleep(10)
          42
        end)

      assert result == 42

      stats = Metrics.stats(:test_api, :compute)
      assert stats.count == 1
      assert stats.min >= 10
    end
  end

  describe "increment/3" do
    test "increments counter metrics" do
      # Clear to ensure fresh state
      Metrics.clear(:all)

      Metrics.increment(:test_counter)
      # Sleep 1 second to ensure different timestamps (metrics uses :second granularity)
      Process.sleep(1100)
      Metrics.increment(:test_counter)
      Process.sleep(1100)
      Metrics.increment(:test_counter, 3)
      Process.sleep(100)

      value = Metrics.counter_value(:test_counter)
      assert value == 5
    end
  end

  describe "gauge/3" do
    test "sets gauge values" do
      Metrics.gauge(:test_gauge, 42)
      assert Metrics.gauge_value(:test_gauge) == 42

      Metrics.gauge(:test_gauge, 100)
      assert Metrics.gauge_value(:test_gauge) == 100
    end
  end

  describe "stats/2" do
    test "returns nil for non-existent metrics" do
      assert Metrics.stats(:nonexistent, :operation) == nil
    end

    test "calculates statistics correctly" do
      values = [100, 150, 200, 250, 300]

      for value <- values do
        Metrics.timing(:test_api, :operation, value)
      end

      stats = Metrics.stats(:test_api, :operation)

      assert stats.count == 5
      assert stats.min == 100
      assert stats.max == 300
      assert stats.mean == 200.0
      assert stats.median == 200.0
    end

    test "calculates percentiles correctly" do
      # Add 100 values from 1 to 100
      for i <- 1..100 do
        Metrics.timing(:test_api, :percentile_test, i)
      end

      stats = Metrics.stats(:test_api, :percentile_test)

      assert stats.p95 >= 95.0
      assert stats.p99 >= 99.0
    end
  end

  describe "all_metrics/1" do
    test "returns list of metrics by type" do
      Metrics.timing(:api1, :op1, 100)
      Metrics.timing(:api2, :op2, 200)
      Metrics.increment(:counter1)

      timing_metrics = Metrics.all_metrics(:timing)
      counter_metrics = Metrics.all_metrics(:counter)

      assert {:api1, :op1} in timing_metrics
      assert {:api2, :op2} in timing_metrics
      assert :counter1 in counter_metrics
    end
  end

  describe "clear/1" do
    test "clears specific metric type" do
      Metrics.timing(:test_api, :operation, 100)
      Metrics.increment(:test_counter)

      Metrics.clear(:timing)

      assert Metrics.stats(:test_api, :operation) == nil
      assert Metrics.counter_value(:test_counter) > 0
    end

    test "clears all metrics" do
      Metrics.timing(:test_api, :operation, 100)
      Metrics.increment(:test_counter)

      Metrics.clear(:all)

      assert Metrics.stats(:test_api, :operation) == nil
      assert Metrics.counter_value(:test_counter) == 0
    end
  end

  describe "chart/3" do
    test "generates ASCII chart for metrics" do
      for i <- 1..20 do
        Metrics.timing(:test_api, :operation, i * 10)
      end

      chart = Metrics.chart(:test_api, :operation)

      assert is_binary(chart)
      assert String.contains?(chart, "┌─")
      assert String.contains?(chart, "└─")
      assert String.contains?(chart, "Min:")
      assert String.contains?(chart, "Max:")
    end

    test "returns message for empty metrics" do
      chart = Metrics.chart(:test_api, :nonexistent)

      assert is_binary(chart)
      assert String.contains?(chart, "No data available")
    end
  end
end
