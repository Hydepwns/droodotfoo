defmodule Droodotfoo.InputRateLimiter do
  @moduledoc """
  Rate limiter for input events to prevent DoS attacks and performance issues.
  Implements a token bucket algorithm with per-session tracking.
  """

  @max_tokens 30
  # tokens per second
  @refill_rate 10
  # ms
  @refill_interval 100

  defstruct tokens: @max_tokens,
            last_refill: nil,
            events_blocked: 0,
            events_allowed: 0

  def new do
    %__MODULE__{
      tokens: @max_tokens,
      last_refill: System.monotonic_time(:millisecond)
    }
  end

  @doc """
  Check if an event should be allowed based on rate limiting.
  Returns {allowed?, updated_limiter}
  """
  def allow_event?(limiter) do
    limiter = refill_tokens(limiter)

    if limiter.tokens > 0 do
      {true, %{limiter | tokens: limiter.tokens - 1, events_allowed: limiter.events_allowed + 1}}
    else
      {false, %{limiter | events_blocked: limiter.events_blocked + 1}}
    end
  end

  defp refill_tokens(limiter) do
    now = System.monotonic_time(:millisecond)
    elapsed = now - limiter.last_refill

    if elapsed >= @refill_interval do
      tokens_to_add = div(elapsed, @refill_interval) * @refill_rate / 10
      new_tokens = min(@max_tokens, limiter.tokens + trunc(tokens_to_add))

      %{limiter | tokens: new_tokens, last_refill: now}
    else
      limiter
    end
  end

  def stats(limiter) do
    %{
      tokens_remaining: limiter.tokens,
      events_allowed: limiter.events_allowed,
      events_blocked: limiter.events_blocked,
      block_rate:
        if limiter.events_allowed + limiter.events_blocked > 0 do
          Float.round(
            limiter.events_blocked / (limiter.events_allowed + limiter.events_blocked) * 100,
            2
          )
        else
          0.0
        end
    }
  end
end
