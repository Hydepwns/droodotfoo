defmodule Droodotfoo.InputRateLimiterTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.InputRateLimiter

  describe "new/0" do
    test "creates a new rate limiter with default tokens" do
      limiter = InputRateLimiter.new()

      assert %InputRateLimiter{} = limiter
      # @max_tokens default
      assert limiter.tokens == 30
      assert limiter.events_allowed == 0
      assert limiter.events_blocked == 0
      assert is_integer(limiter.last_refill)
    end
  end

  describe "allow_event?/1" do
    test "allows events when tokens are available" do
      limiter = InputRateLimiter.new()

      # Should allow first 30 events (max tokens)
      {limiter, results} =
        Enum.reduce(1..30, {limiter, []}, fn _i, {lim, results} ->
          {allowed, new_lim} = InputRateLimiter.allow_event?(lim)
          {new_lim, [allowed | results]}
        end)

      assert Enum.all?(results, &(&1 == true))
      assert limiter.tokens == 0
      assert limiter.events_allowed == 30
      assert limiter.events_blocked == 0
    end

    test "blocks events when tokens are exhausted" do
      limiter = InputRateLimiter.new()

      # Exhaust all tokens
      {limiter, _} =
        Enum.reduce(1..30, {limiter, []}, fn _i, {lim, results} ->
          {allowed, new_lim} = InputRateLimiter.allow_event?(lim)
          {new_lim, [allowed | results]}
        end)

      # Next event should be blocked
      {allowed, limiter} = InputRateLimiter.allow_event?(limiter)

      assert allowed == false
      assert limiter.events_blocked == 1
      assert limiter.tokens == 0
    end

    test "tracks allowed and blocked events" do
      limiter = InputRateLimiter.new()

      # Allow 30 events (exhaust tokens)
      {limiter, _} =
        Enum.reduce(1..30, {limiter, []}, fn _i, {lim, _} ->
          {_, new_lim} = InputRateLimiter.allow_event?(lim)
          {new_lim, nil}
        end)

      # Try 10 more events (should be blocked)
      {limiter, _} =
        Enum.reduce(1..10, {limiter, []}, fn _i, {lim, _} ->
          {_, new_lim} = InputRateLimiter.allow_event?(lim)
          {new_lim, nil}
        end)

      assert limiter.events_allowed == 30
      assert limiter.events_blocked == 10
    end

    test "refills tokens over time" do
      limiter = InputRateLimiter.new()

      # Exhaust all tokens
      {limiter, _} =
        Enum.reduce(1..30, {limiter, []}, fn _i, {lim, _} ->
          {_, new_lim} = InputRateLimiter.allow_event?(lim)
          {new_lim, nil}
        end)

      assert limiter.tokens == 0

      # Simulate time passing by setting last_refill to past
      # 200ms ago
      past_time = System.monotonic_time(:millisecond) - 200
      limiter = %{limiter | last_refill: past_time}

      # Should refill some tokens (2 refill intervals = 2 tokens)
      {allowed, limiter} = InputRateLimiter.allow_event?(limiter)

      assert allowed == true
      # Should have refilled some tokens
      assert limiter.tokens > 0
    end

    test "caps tokens at maximum" do
      limiter = InputRateLimiter.new()

      # Set last_refill to very long ago
      # 10 seconds ago
      past_time = System.monotonic_time(:millisecond) - 10_000
      limiter = %{limiter | last_refill: past_time}

      # Should refill to max tokens only
      {_, limiter} = InputRateLimiter.allow_event?(limiter)

      # Tokens should be capped at max (30) minus 1 (used)
      assert limiter.tokens <= 30
    end
  end

  describe "stats/1" do
    test "returns current statistics" do
      limiter = InputRateLimiter.new()

      # Generate some activity
      {limiter, _} =
        Enum.reduce(1..35, {limiter, []}, fn _i, {lim, _} ->
          {_, new_lim} = InputRateLimiter.allow_event?(lim)
          {new_lim, nil}
        end)

      stats = InputRateLimiter.stats(limiter)

      assert is_map(stats)
      assert stats.tokens_remaining == 0
      assert stats.events_allowed == 30
      assert stats.events_blocked == 5
      assert stats.block_rate == Float.round(5 / 35 * 100, 2)
    end

    test "handles zero events gracefully" do
      limiter = InputRateLimiter.new()
      stats = InputRateLimiter.stats(limiter)

      assert stats.tokens_remaining == 30
      assert stats.events_allowed == 0
      assert stats.events_blocked == 0
      assert stats.block_rate == 0.0
    end
  end

  describe "concurrent usage simulation" do
    test "maintains consistency with rapid sequential events" do
      limiter = InputRateLimiter.new()

      # Simulate 100 rapid events
      {final_limiter, results} =
        Enum.reduce(1..100, {limiter, []}, fn _i, {lim, results} ->
          {allowed, new_lim} = InputRateLimiter.allow_event?(lim)
          {new_lim, [allowed | results]}
        end)

      allowed_count = Enum.count(results, &(&1 == true))
      blocked_count = Enum.count(results, &(&1 == false))

      assert allowed_count == final_limiter.events_allowed
      assert blocked_count == final_limiter.events_blocked
      assert allowed_count + blocked_count == 100

      # First 30 should be allowed, rest blocked (without refills)
      assert allowed_count >= 30
    end

    test "handles burst patterns" do
      limiter = InputRateLimiter.new()

      # Burst of 50 events
      {limiter, burst_results} =
        Enum.reduce(1..50, {limiter, []}, fn _i, {lim, results} ->
          {allowed, new_lim} = InputRateLimiter.allow_event?(lim)
          {new_lim, [allowed | results]}
        end)

      burst_allowed = Enum.count(burst_results, &(&1 == true))

      # Should allow 30, block 20
      assert burst_allowed == 30
      assert limiter.events_blocked == 20

      # Simulate delay for refill
      past_time = System.monotonic_time(:millisecond) - 300
      limiter = %{limiter | last_refill: past_time}

      # Another burst
      {limiter, _} =
        Enum.reduce(1..10, {limiter, []}, fn _i, {lim, _} ->
          {_, new_lim} = InputRateLimiter.allow_event?(lim)
          {new_lim, nil}
        end)

      # Should have allowed some from the second burst due to refill
      assert limiter.events_allowed > burst_allowed
    end
  end

  describe "edge cases" do
    test "handles negative token count gracefully" do
      limiter = %InputRateLimiter{
        tokens: -5,
        last_refill: System.monotonic_time(:millisecond),
        events_allowed: 0,
        events_blocked: 0
      }

      {allowed, limiter} = InputRateLimiter.allow_event?(limiter)

      assert allowed == false
      assert limiter.events_blocked == 1
    end

    test "handles nil last_refill" do
      limiter = %InputRateLimiter{
        tokens: 10,
        last_refill: nil,
        events_allowed: 0,
        events_blocked: 0
      }

      # Should handle nil gracefully (might crash or reset)
      assert_raise ArithmeticError, fn ->
        InputRateLimiter.allow_event?(limiter)
      end
    end

    test "handles very large token values" do
      limiter = %InputRateLimiter{
        tokens: 999_999,
        last_refill: System.monotonic_time(:millisecond),
        events_allowed: 0,
        events_blocked: 0
      }

      {allowed, limiter} = InputRateLimiter.allow_event?(limiter)

      assert allowed == true
      assert limiter.tokens == 999_998
    end
  end
end
