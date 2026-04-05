defmodule Droodotfoo.Content.PatternAnimations.Interference do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes interference-pulse {
        0% {
          opacity: 0.3;
          transform: scale(1);
        }
        50% {
          opacity: 0.6;
          transform: scale(1.002);
        }
        100% {
          opacity: 0.3;
          transform: scale(1);
        }
      }
      @keyframes interference-phase-0 {
        0% {
          stroke-dashoffset: 0;
          opacity: 0.4;
        }
        100% {
          stroke-dashoffset: 50;
          opacity: 0.4;
        }
      }
      @keyframes interference-phase-1 {
        0% {
          stroke-dashoffset: 0;
          opacity: 0.35;
        }
        100% {
          stroke-dashoffset: -50;
          opacity: 0.35;
        }
      }
      @keyframes interference-grid-shift-0 {
        0% {
          transform: translateX(0) translateY(0);
          opacity: 0.3;
        }
        50% {
          transform: translateX(2px) translateY(1px);
          opacity: 0.5;
        }
        100% {
          transform: translateX(0) translateY(0);
          opacity: 0.3;
        }
      }
      @keyframes interference-grid-shift-1 {
        0% {
          transform: translateX(0) translateY(0);
          opacity: 0.35;
        }
        50% {
          transform: translateX(-2px) translateY(-1px);
          opacity: 0.45;
        }
        100% {
          transform: translateX(0) translateY(0);
          opacity: 0.35;
        }
      }
      .interference-ring {
        animation: interference-pulse 4s ease-in-out infinite;
        transform-origin: center;
      }
      .interference-wave-0 {
        stroke-dasharray: 10 5;
        animation: interference-phase-0 6s linear infinite;
      }
      .interference-wave-1 {
        stroke-dasharray: 8 4;
        animation: interference-phase-1 8s linear infinite;
      }
      .interference-wave-2 {
        stroke-dasharray: 12 6;
        animation: interference-phase-0 10s linear infinite;
      }
      .interference-grid-0 {
        animation: interference-grid-shift-0 5s ease-in-out infinite;
      }
      .interference-grid-1 {
        animation: interference-grid-shift-1 7s ease-in-out infinite;
      }
    </style>
    """
  end
end
