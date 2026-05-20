defmodule Droodotfoo.Content.PatternAnimations.CockpitHud do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      /* Top tape strip ticks: slow rolling sweep */
      @keyframes cockpit-tick-sweep {
        0%, 100% { opacity: 0.55; }
        10%      { opacity: 1; }
        20%      { opacity: 0.55; }
      }
      .cockpit-tick {
        animation: cockpit-tick-sweep 8s linear infinite;
      }

      /* Visor grid breath: faint scale + opacity */
      @keyframes cockpit-grid-breath {
        0%, 100% { opacity: 0.85; }
        50%      { opacity: 1; }
      }
      .cockpit-grid-breath {
        animation: cockpit-grid-breath 4.5s ease-in-out infinite;
      }

      /* Reticle rings */
      @keyframes cockpit-ring-pulse {
        0%, 100% { opacity: 0.25; }
        50%      { opacity: 0.85; }
      }
      .cockpit-ring-0 { animation: cockpit-ring-pulse 3.5s ease-in-out infinite; animation-delay: 0s; }
      .cockpit-ring-1 { animation: cockpit-ring-pulse 3.5s ease-in-out infinite; animation-delay: 0.45s; }
      .cockpit-ring-2 { animation: cockpit-ring-pulse 3.5s ease-in-out infinite; animation-delay: 0.9s; }

      /* Target tracking brackets: subtle pulse at lock cadence */
      @keyframes cockpit-track-pulse {
        0%, 100% { opacity: 0.9; }
        50%      { opacity: 0.55; }
      }
      .cockpit-track {
        animation: cockpit-track-pulse 2.2s ease-in-out infinite;
      }

      /* Indicator cells: phase-offset blips */
      @keyframes cockpit-blip-on {
        0%, 100% { opacity: 0.85; }
        50%      { opacity: 0.25; }
      }
      .cockpit-blip-0 { animation: cockpit-blip-on 2.4s ease-in-out infinite; animation-delay: 0s; }
      .cockpit-blip-1 { animation: cockpit-blip-on 2.4s ease-in-out infinite; animation-delay: 0.4s; }
      .cockpit-blip-2 { animation: cockpit-blip-on 2.4s ease-in-out infinite; animation-delay: 0.8s; }
      .cockpit-blip-3 { animation: cockpit-blip-on 2.4s ease-in-out infinite; animation-delay: 1.2s; }

      /* Emphasized status line flicker */
      @keyframes cockpit-flicker {
        0%, 96%, 100% { opacity: 1; }
        97%           { opacity: 0.2; }
        98%           { opacity: 1; }
        99%           { opacity: 0.35; }
      }
      .cockpit-flicker {
        animation: cockpit-flicker 5.5s steps(1, end) infinite;
      }

      /* ZERO SYSTEM marquee: slow breath + occasional hazard flicker */
      @keyframes cockpit-marquee-breath {
        0%, 88%, 100% { opacity: 0.95; }
        90%           { opacity: 0.4; }
        92%           { opacity: 1; }
        94%           { opacity: 0.55; }
      }
      .cockpit-marquee {
        animation: cockpit-marquee-breath 7s steps(1, end) infinite;
      }

      @media (prefers-reduced-motion: reduce) {
        .cockpit-tick,
        .cockpit-grid-breath,
        .cockpit-ring-0,
        .cockpit-ring-1,
        .cockpit-ring-2,
        .cockpit-track,
        .cockpit-blip-0,
        .cockpit-blip-1,
        .cockpit-blip-2,
        .cockpit-blip-3,
        .cockpit-flicker,
        .cockpit-marquee {
          animation: none;
        }
      }
    </style>
    """
  end
end
