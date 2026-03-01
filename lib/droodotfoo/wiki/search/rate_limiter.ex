defmodule Droodotfoo.Wiki.Search.RateLimiter do
  @moduledoc """
  Rate limiter for wiki search.
  """

  use Droodotfoo.RateLimiter,
    table_name: :wiki_search_rate_limit,
    windows: [
      {:per_second, 1, 5},
      {:per_minute, 60, 30},
      {:hourly, 3600, 200}
    ],
    log_prefix: "Wiki search"
end
