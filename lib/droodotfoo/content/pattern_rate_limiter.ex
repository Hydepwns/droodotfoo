defmodule Droodotfoo.Content.PatternRateLimiter do
  @moduledoc """
  Rate limiting for pattern generation endpoint.
  """

  use Droodotfoo.RateLimiter,
    table_name: :pattern_rate_limits,
    windows: [
      {:per_minute, 60, 30},
      {:hourly, 3_600, 300}
    ],
    log_prefix: "Pattern"
end
