defmodule DroodotfooWeb.GivethBanner do
  @moduledoc """
  Announcement banner pointing to the axol.io / Xochi Giveth project page.
  Per-user dismissal is handled client-side via localStorage (see
  giveth_banner.ts).
  """

  use Phoenix.Component

  @giveth_url "https://giveth.io/project/axolio-xochifi"

  @doc "Renders the Giveth support banner."
  def banner(assigns) do
    assigns = assign(assigns, :url, @giveth_url)

    ~H"""
    <div
      id="giveth-banner"
      class="giveth-banner banner-beam"
      role="region"
      aria-label="Giveth funding"
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
          <span aria-hidden="true">&middot;</span> Back axol.io on Giveth
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
