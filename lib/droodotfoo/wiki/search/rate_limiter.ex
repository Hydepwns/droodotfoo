defmodule Droodotfoo.Wiki.Search.RateLimiter do
  @moduledoc """
  Rate limiter for wiki search to prevent abuse.

  Uses sliding windows to limit:
  - 5 requests per second (burst protection)
  - 30 requests per minute (sustained load)
  - 200 requests per hour (overall limit)
  """

  use Droodotfoo.RateLimiter,
    table_name: :wiki_search_rate_limit,
    windows: [
      {:per_second, 1, 5},
      {:per_minute, 60, 30},
      {:hourly, 3600, 200}
    ],
    cleanup_interval: :timer.minutes(5),
    log_prefix: "Wiki search",
    log_level: :debug,
    record_mode: :async,
    storage_mode: :multi
end
