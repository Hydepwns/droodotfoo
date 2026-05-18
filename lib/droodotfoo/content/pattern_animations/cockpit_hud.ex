defmodule Droodotfoo.Content.PatternAnimations.CockpitHud do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      /* Outer frame brackets */
      @keyframes cockpit-corner-pulse {
        0%, 100% { opacity: 0.85; }
        50%      { opacity: 1; }
      }
      .cockpit-corner {
        animation: cockpit-corner-pulse 5s ease-in-out infinite;
      }

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

      /* Silhouette outline pulse */
      @keyframes cockpit-pulse-breath {
        0%, 100% { opacity: 0.85; }
        50%      { opacity: 1; }
      }
      .cockpit-pulse {
        animation: cockpit-pulse-breath 3.8s ease-in-out infinite;
      }

      /* Gundam eye-cameras: bright with rare flicker */
      @keyframes cockpit-eye-glow {
        0%, 92%, 100% { opacity: 0.95; }
        94%           { opacity: 0.25; }
        96%           { opacity: 0.95; }
      }
      .cockpit-eye {
        animation: cockpit-eye-glow 6s steps(1, end) infinite;
      }

      /* Reticle rings */
      @keyframes cockpit-ring-pulse {
        0%, 100% { opacity: 0.25; }
        50%      { opacity: 0.85; }
      }
      .cockpit-ring-0 { animation: cockpit-ring-pulse 3.5s ease-in-out infinite; animation-delay: 0s; }
      .cockpit-ring-1 { animation: cockpit-ring-pulse 3.5s ease-in-out infinite; animation-delay: 0.45s; }
      .cockpit-ring-2 { animation: cockpit-ring-pulse 3.5s ease-in-out infinite; animation-delay: 0.9s; }

      /* Scan beam: horizontal line sweeping vertically across the grid */
      @keyframes cockpit-scan-sweep {
        0%   { transform: translateY(-130px); opacity: 0.0; }
        10%  { opacity: 0.95; }
        50%  { transform: translateY(0); opacity: 1; }
        90%  { opacity: 0.95; }
        100% { transform: translateY(130px); opacity: 0.0; }
      }
      .cockpit-scan {
        animation: cockpit-scan-sweep 3.6s ease-in-out infinite;
      }

      /* Sparkline draw-in then loop with fade */
      @keyframes cockpit-spark-draw {
        0%   { stroke-dashoffset: 1800; opacity: 0; }
        12%  { opacity: 1; }
        70%  { stroke-dashoffset: 0; opacity: 1; }
        90%  { opacity: 0.5; }
        100% { stroke-dashoffset: 0; opacity: 0; }
      }
      .cockpit-spark {
        stroke-dasharray: 1800;
        stroke-dashoffset: 1800;
        animation: cockpit-spark-draw 6s linear infinite;
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

      /* Wing feathers: phase-offset shimmer suggesting deployed wings */
      @keyframes cockpit-feather-shimmer {
        0%, 100% { opacity: 0.18; }
        50%      { opacity: 0.42; }
      }
      .cockpit-feather-0 { animation: cockpit-feather-shimmer 5s ease-in-out infinite; animation-delay: 0s; }
      .cockpit-feather-1 { animation: cockpit-feather-shimmer 5s ease-in-out infinite; animation-delay: 0.4s; }
      .cockpit-feather-2 { animation: cockpit-feather-shimmer 5s ease-in-out infinite; animation-delay: 0.8s; }
      .cockpit-feather-3 { animation: cockpit-feather-shimmer 5s ease-in-out infinite; animation-delay: 1.2s; }
      .cockpit-feather-4 { animation: cockpit-feather-shimmer 5s ease-in-out infinite; animation-delay: 1.6s; }

      /* Buster rifle charge bars: slow breathing fill to suggest power flow */
      @keyframes cockpit-charge-flow {
        0%, 100% { opacity: 0.7; }
        50%      { opacity: 1; }
      }
      .cockpit-charge-0 { animation: cockpit-charge-flow 2.8s ease-in-out infinite; animation-delay: 0s; }
      .cockpit-charge-1 { animation: cockpit-charge-flow 2.8s ease-in-out infinite; animation-delay: 1.4s; }

      @media (prefers-reduced-motion: reduce) {
        .cockpit-corner,
        .cockpit-tick,
        .cockpit-grid-breath,
        .cockpit-pulse,
        .cockpit-eye,
        .cockpit-ring-0,
        .cockpit-ring-1,
        .cockpit-ring-2,
        .cockpit-scan,
        .cockpit-spark,
        .cockpit-blip-0,
        .cockpit-blip-1,
        .cockpit-blip-2,
        .cockpit-blip-3,
        .cockpit-flicker,
        .cockpit-marquee,
        .cockpit-feather-0,
        .cockpit-feather-1,
        .cockpit-feather-2,
        .cockpit-feather-3,
        .cockpit-feather-4,
        .cockpit-charge-0,
        .cockpit-charge-1 {
          animation: none;
        }
        .cockpit-spark { stroke-dashoffset: 0; }
      }
    </style>
    """
  end
end
