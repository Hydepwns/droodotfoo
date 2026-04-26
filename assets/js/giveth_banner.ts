/**
 * Giveth banner dismissal.
 *
 * Lives in the root layout (outside the LiveView container) so a phx-hook
 * cannot attach -- this is plain DOM. Reads/writes localStorage to keep the
 * dismissed state across navigations and reloads.
 */

const STORAGE_KEY = "droofoo.giveth-banner-v1.dismissed";

function init(): void {
  const banner = document.getElementById("giveth-banner");
  if (!banner) return;

  if (localStorage.getItem(STORAGE_KEY) === "1") {
    banner.classList.add("is-hidden");
    return;
  }

  const dismiss = banner.querySelector<HTMLButtonElement>(
    "[data-giveth-banner-dismiss]",
  );
  if (!dismiss) return;

  dismiss.addEventListener("click", () => {
    localStorage.setItem(STORAGE_KEY, "1");
    banner.classList.add("is-hidden");
  });
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", init, { once: true });
} else {
  init();
}
