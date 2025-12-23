defmodule Droodotfoo.Content.PatternRateLimiter do
  @moduledoc """
  Rate limiting for pattern generation endpoint.
  Prevents CPU exhaustion from excessive pattern generation requests.
  """

  use Droodotfoo.RateLimiter,
    table_name: :pattern_rate_limits,
    windows: [
      {:per_minute, 60, 30},
      {:hourly, 3_600, 300}
    ],
    cleanup_interval: :timer.minutes(10),
    log_prefix: "Pattern",
    log_level: :debug,
    record_mode: :async,
    storage_mode: :multi,
    include_status: false
end
