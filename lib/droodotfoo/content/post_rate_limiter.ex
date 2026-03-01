defmodule Droodotfoo.Content.PostRateLimiter do
  @moduledoc """
  Rate limiting for blog post API submissions.
  """

  use Droodotfoo.RateLimiter,
    table_name: :post_api_rate_limits,
    windows: [
      {:hourly, 3_600, 10},
      {:daily, 86_400, 50}
    ],
    log_prefix: "Post API"
end
