defmodule Droodotfoo.RateLimiterTest do
  use ExUnit.Case, async: false

  # Test module with counter storage mode (default)
  defmodule CounterRateLimiter do
    use Droodotfoo.RateLimiter,
      table_name: :test_counter_rate_limit,
      windows: [
        {:per_second, 1, 2},
        {:per_minute, 60, 5}
      ],
      cleanup_interval: :timer.minutes(10),
      log_prefix: "Test Counter"
  end

  # Test module with multi storage mode (like PatternRateLimiter)
  defmodule MultiRateLimiter do
    use Droodotfoo.RateLimiter,
      table_name: :test_multi_rate_limit,
      windows: [
        {:per_second, 1, 2},
        {:per_minute, 60, 5}
      ],
      cleanup_interval: :timer.minutes(10),
      log_prefix: "Test Multi",
      log_level: :debug,
      record_mode: :async,
      storage_mode: :multi,
      include_status: false
  end

  # Test module with custom error message
  defmodule CustomErrorRateLimiter do
    use Droodotfoo.RateLimiter,
      table_name: :test_custom_error_rate_limit,
      windows: [
        {:hourly, 3_600, 3}
      ],
      cleanup_interval: :timer.minutes(10),
      log_prefix: "Test Custom",
      error_message: "Custom rate limit message"
  end

  describe "counter storage mode" do
    setup do
      start_supervised!(CounterRateLimiter)
      :ok
    end

    test "allows requests within limit" do
      assert {:ok, :allowed} = CounterRateLimiter.check_rate_limit("192.168.1.1")
    end

    test "records and tracks submissions" do
      ip = "192.168.1.2"
      assert :ok = CounterRateLimiter.record_submission(ip)
      assert {:ok, status} = CounterRateLimiter.get_status(ip)
      assert status.can_submit == true
    end

    test "blocks when per-second limit exceeded" do
      ip = "192.168.1.3"

      # Record 2 submissions (at limit)
      CounterRateLimiter.record_submission(ip)
      CounterRateLimiter.record_submission(ip)

      # Third should be blocked
      assert {:error, message} = CounterRateLimiter.check_rate_limit(ip)
      assert message =~ "Rate limit exceeded"
      assert message =~ "per second"
    end

    test "get_status returns correct window information" do
      ip = "192.168.1.4"
      CounterRateLimiter.record_submission(ip)

      assert {:ok, status} = CounterRateLimiter.get_status(ip)
      assert status.ip_address == ip
      assert status.can_submit == true
      assert Map.has_key?(status.windows, :per_second)
      assert Map.has_key?(status.windows, :per_minute)
    end
  end

  describe "multi storage mode" do
    setup do
      start_supervised!(MultiRateLimiter)
      :ok
    end

    test "allows requests within limit" do
      assert {:ok, :allowed} = MultiRateLimiter.check_rate_limit("10.0.0.1")
    end

    test "records requests asynchronously" do
      ip = "10.0.0.2"
      # record_request returns :ok immediately (cast)
      assert :ok = MultiRateLimiter.record_request(ip)
      # Give it a moment to process
      Process.sleep(10)
      assert {:ok, :allowed} = MultiRateLimiter.check_rate_limit(ip)
    end

    test "blocks when limit exceeded" do
      ip = "10.0.0.3"

      # Record 2 requests (at limit)
      MultiRateLimiter.record_request(ip)
      MultiRateLimiter.record_request(ip)
      Process.sleep(10)

      # Third should be blocked
      assert {:error, message} = MultiRateLimiter.check_rate_limit(ip)
      assert message =~ "Rate limit exceeded"
    end

    test "does not have get_status function" do
      refute function_exported?(MultiRateLimiter, :get_status, 1)
    end
  end

  describe "custom error message" do
    setup do
      start_supervised!(CustomErrorRateLimiter)
      :ok
    end

    test "uses custom error message function" do
      ip = "172.16.0.1"

      # Exceed limit
      CustomErrorRateLimiter.record_submission(ip)
      CustomErrorRateLimiter.record_submission(ip)
      CustomErrorRateLimiter.record_submission(ip)

      assert {:error, message} = CustomErrorRateLimiter.check_rate_limit(ip)
      assert message == "Custom rate limit message"
    end
  end

  describe "time window enforcement" do
    setup do
      start_supervised!(CounterRateLimiter)
      :ok
    end

    test "resets after window expires" do
      ip = "192.168.2.1"

      # Exceed per-second limit
      CounterRateLimiter.record_submission(ip)
      CounterRateLimiter.record_submission(ip)
      assert {:error, _} = CounterRateLimiter.check_rate_limit(ip)

      # Wait for window to expire
      Process.sleep(1100)

      # Should be allowed again (per-second reset, but still under per-minute)
      assert {:ok, :allowed} = CounterRateLimiter.check_rate_limit(ip)
    end
  end

  describe "behaviour callbacks" do
    test "counter module implements required callbacks" do
      assert function_exported?(CounterRateLimiter, :check_rate_limit, 1)
      assert function_exported?(CounterRateLimiter, :record_submission, 1)
      assert function_exported?(CounterRateLimiter, :get_status, 1)
    end

    test "multi module implements required callbacks" do
      assert function_exported?(MultiRateLimiter, :check_rate_limit, 1)
      assert function_exported?(MultiRateLimiter, :record_request, 1)
    end
  end
end
