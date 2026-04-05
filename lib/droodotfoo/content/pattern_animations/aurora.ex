defmodule Droodotfoo.Content.PatternAnimations.Aurora do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes aurora-emerge-0 {
        0% {
          stroke-dashoffset: 2000;
          opacity: 0;
          transform: translateY(0);
        }
        20% {
          opacity: 0.4;
        }
        50% {
          stroke-dashoffset: 0;
          opacity: 0.5;
          transform: translateY(-5px);
        }
        70% {
          opacity: 0.4;
          transform: translateY(3px);
        }
        100% {
          stroke-dashoffset: 0;
          opacity: 0.3;
          transform: translateY(0);
        }
      }
      @keyframes aurora-emerge-1 {
        0% {
          stroke-dashoffset: 1800;
          opacity: 0;
          transform: translateY(0);
        }
        25% {
          opacity: 0.35;
        }
        55% {
          stroke-dashoffset: 0;
          opacity: 0.45;
          transform: translateY(-8px);
        }
        75% {
          opacity: 0.35;
          transform: translateY(5px);
        }
        100% {
          stroke-dashoffset: 0;
          opacity: 0.25;
          transform: translateY(0);
        }
      }
      @keyframes aurora-emerge-2 {
        0% {
          stroke-dashoffset: 2200;
          opacity: 0;
          transform: translateY(0);
        }
        15% {
          opacity: 0.5;
        }
        45% {
          stroke-dashoffset: 0;
          opacity: 0.55;
          transform: translateY(-3px);
        }
        65% {
          opacity: 0.45;
          transform: translateY(7px);
        }
        100% {
          stroke-dashoffset: 0;
          opacity: 0.35;
          transform: translateY(0);
        }
      }
      @keyframes aurora-emerge-3 {
        0% {
          stroke-dashoffset: 1600;
          opacity: 0;
          transform: translateY(0);
        }
        30% {
          opacity: 0.3;
        }
        60% {
          stroke-dashoffset: 0;
          opacity: 0.4;
          transform: translateY(-10px);
        }
        80% {
          opacity: 0.3;
          transform: translateY(2px);
        }
        100% {
          stroke-dashoffset: 0;
          opacity: 0.2;
          transform: translateY(0);
        }
      }
      .aurora-band-0 {
        stroke-dasharray: 2000;
        stroke-dashoffset: 2000;
        animation: aurora-emerge-0 8s ease-in-out infinite;
        animation-delay: calc(var(--i, 0) * 0.3s);
      }
      .aurora-band-1 {
        stroke-dasharray: 1800;
        stroke-dashoffset: 1800;
        animation: aurora-emerge-1 9s ease-in-out infinite;
        animation-delay: calc(var(--i, 0) * 0.35s);
      }
      .aurora-band-2 {
        stroke-dasharray: 2200;
        stroke-dashoffset: 2200;
        animation: aurora-emerge-2 10s ease-in-out infinite;
        animation-delay: calc(var(--i, 0) * 0.25s);
      }
      .aurora-band-3 {
        stroke-dasharray: 1600;
        stroke-dashoffset: 1600;
        animation: aurora-emerge-3 7s ease-in-out infinite;
        animation-delay: calc(var(--i, 0) * 0.4s);
      }
    </style>
    """
  end
end
