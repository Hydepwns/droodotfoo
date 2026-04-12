defmodule Droodotfoo.Contact.RateLimiter do
  @moduledoc """
  Rate limiting for contact form submissions.
  """

  use Droodotfoo.RateLimiter,
    table_name: :contact_rate_limit,
    windows: [
      {:hourly, 3_600, 3},
      {:daily, 86_400, 10}
    ],
    log_prefix: "Contact form",
    error_message: "Too many submissions. Please try again later."
end
