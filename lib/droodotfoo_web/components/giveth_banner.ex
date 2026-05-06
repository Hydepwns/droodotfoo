defmodule DroodotfooWeb.GivethBanner do
  @moduledoc """
  Time-windowed announcement banner for the axol.io / Xochi QF Giveth round.

  Renders nothing once the close date has passed -- a defense-in-depth so the
  banner self-destructs even if the codebase is not redeployed promptly. Per-
  user dismissal is handled client-side via localStorage (see giveth_banner.ts).
  """

  use Phoenix.Component

  @close_date ~D[2026-05-14]
  @giveth_url "https://qf.giveth.io/project/axolio-xochifi"

  @doc "Renders the QF round banner if the donation window is still open."
  def banner(assigns) do
    if Date.compare(Date.utc_today(), @close_date) == :gt do
      ~H""
    else
      assigns = assign(assigns, :url, @giveth_url)

      ~H"""
      <div
        id="giveth-banner"
        class="giveth-banner banner-beam"
        role="region"
        aria-label="Giveth QF funding round"
      >
        <a
          class="giveth-banner-link"
          href={@url}
          target="_blank"
          rel="noopener noreferrer"
        >
          <span class="giveth-banner-tag">QF Round</span>
          <span class="giveth-banner-text">
            <span class="giveth-banner-multiplier">$5 to get matched</span>
            <span aria-hidden="true">&middot;</span> Back axol.io on Giveth, closes May 14
          </span>
          <span class="giveth-banner-arrow" aria-hidden="true">&rarr;</span>
        </a>
        <button
          type="button"
          class="giveth-banner-close"
          aria-label="Dismiss banner"
          data-giveth-banner-dismiss
        >
          &times;
        </button>
      </div>
      """
    end
  end
end
