defmodule Droodotfoo.Contact.RateLimiter do
  @moduledoc """
  Rate limiting module for contact form submissions.
  """

  alias Droodotfoo.Forms.Constants

  use Droodotfoo.RateLimiter,
    table_name: Constants.rate_limit_table_name(),
    windows: [
      {:hourly, 3_600, Constants.max_submissions_per_hour()},
      {:daily, 86_400, Constants.max_submissions_per_day()}
    ],
    cleanup_interval: Constants.rate_limit_cleanup_interval(),
    log_prefix: "Contact form",
    error_message: Constants.get_error_message(:rate_limited)
end
