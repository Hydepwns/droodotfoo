defmodule Droodotfoo.Content.PostRateLimiter do
  @moduledoc """
  Rate limiting for blog post API submissions.
  Prevents spam and abuse of the /api/posts endpoint.
  """

  use Droodotfoo.RateLimiter,
    table_name: :post_api_rate_limits,
    windows: [
      {:hourly, 3_600, 10},
      {:daily, 86_400, 50}
    ],
    cleanup_interval: :timer.hours(1),
    log_prefix: "Post API"
end
