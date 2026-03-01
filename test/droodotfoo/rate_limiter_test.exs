defmodule Droodotfoo.RateLimiterTest do
  use ExUnit.Case, async: false

  defmodule TestRateLimiter do
    use Droodotfoo.RateLimiter,
      table_name: :test_rate_limit,
      windows: [
        {:per_second, 1, 2},
        {:per_minute, 60, 5}
      ],
      log_prefix: "Test"
  end

  defmodule CustomErrorRateLimiter do
    use Droodotfoo.RateLimiter,
      table_name: :test_custom_error_rate_limit,
      windows: [{:hourly, 3_600, 3}],
      error_message: "Custom rate limit message"
  end

  describe "basic rate limiting" do
    setup do
      start_supervised!(TestRateLimiter)
      :ok
    end

    test "allows requests within limit" do
      assert {:ok, :allowed} = TestRateLimiter.check_rate_limit("192.168.1.1")
    end

    test "records and tracks requests" do
      ip = "192.168.1.2"
      :ok = TestRateLimiter.record(ip)
      assert {:ok, status} = TestRateLimiter.get_status(ip)
      assert status.can_submit == true
      assert status.windows.per_second.count == 1
    end

    test "blocks when per-second limit exceeded" do
      ip = "192.168.1.3"

      TestRateLimiter.record(ip)
      TestRateLimiter.record(ip)
      Process.sleep(10)

      assert {:error, message} = TestRateLimiter.check_rate_limit(ip)
      assert message =~ "Rate limit exceeded"
      assert message =~ "per second"
    end

    test "get_status returns correct window information" do
      ip = "192.168.1.4"
      TestRateLimiter.record(ip)
      Process.sleep(10)

      assert {:ok, status} = TestRateLimiter.get_status(ip)
      assert status.ip_address == ip
      assert status.can_submit == true
      assert Map.has_key?(status.windows, :per_second)
      assert Map.has_key?(status.windows, :per_minute)
    end

    test "backward compatible aliases work" do
      ip = "192.168.1.5"
      assert :ok = TestRateLimiter.record_submission(ip)
      assert :ok = TestRateLimiter.record_request(ip)
    end
  end

  describe "custom error message" do
    setup do
      start_supervised!(CustomErrorRateLimiter)
      :ok
    end

    test "uses custom error message" do
      ip = "172.16.0.1"

      CustomErrorRateLimiter.record(ip)
      CustomErrorRateLimiter.record(ip)
      CustomErrorRateLimiter.record(ip)
      Process.sleep(10)

      assert {:error, message} = CustomErrorRateLimiter.check_rate_limit(ip)
      assert message == "Custom rate limit message"
    end
  end

  describe "time window enforcement" do
    setup do
      start_supervised!(TestRateLimiter)
      :ok
    end

    test "resets after window expires" do
      ip = "192.168.2.1"

      TestRateLimiter.record(ip)
      TestRateLimiter.record(ip)
      Process.sleep(10)
      assert {:error, _} = TestRateLimiter.check_rate_limit(ip)

      # Wait for per-second window to expire
      Process.sleep(1100)

      # Should be allowed again (per-second reset, still under per-minute)
      assert {:ok, :allowed} = TestRateLimiter.check_rate_limit(ip)
    end
  end

  describe "behaviour callbacks" do
    test "module implements required callbacks" do
      assert function_exported?(TestRateLimiter, :check_rate_limit, 1)
      assert function_exported?(TestRateLimiter, :record, 1)
      assert function_exported?(TestRateLimiter, :get_status, 1)
      # Backward compatible aliases
      assert function_exported?(TestRateLimiter, :record_submission, 1)
      assert function_exported?(TestRateLimiter, :record_request, 1)
    end
  end
end
