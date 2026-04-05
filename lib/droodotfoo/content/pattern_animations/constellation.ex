defmodule Droodotfoo.Content.PatternAnimations.Constellation do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes star-appear-0 {
        0% {
          opacity: 0;
          transform: scale(0);
        }
        30% {
          opacity: 0.9;
          transform: scale(1.3);
        }
        50% {
          opacity: 0.7;
          transform: scale(1);
        }
        70% {
          opacity: 0.9;
          transform: scale(1.1);
        }
        100% {
          opacity: 0.6;
          transform: scale(1);
        }
      }
      @keyframes star-appear-1 {
        0% {
          opacity: 0;
          transform: scale(0);
        }
        40% {
          opacity: 0.8;
          transform: scale(1.2);
        }
        60% {
          opacity: 0.6;
          transform: scale(0.9);
        }
        100% {
          opacity: 0.5;
          transform: scale(1);
        }
      }
      @keyframes star-appear-2 {
        0% {
          opacity: 0;
          transform: scale(0);
        }
        25% {
          opacity: 1;
          transform: scale(1.4);
        }
        50% {
          opacity: 0.8;
          transform: scale(1);
        }
        75% {
          opacity: 0.9;
          transform: scale(1.2);
        }
        100% {
          opacity: 0.7;
          transform: scale(1);
        }
      }
      @keyframes line-draw-0 {
        0% {
          stroke-dashoffset: 300;
          opacity: 0;
        }
        20% {
          opacity: 0.3;
        }
        80% {
          stroke-dashoffset: 0;
          opacity: 0.3;
        }
        100% {
          stroke-dashoffset: 0;
          opacity: 0.2;
        }
      }
      @keyframes line-draw-1 {
        0% {
          stroke-dashoffset: 250;
          opacity: 0;
        }
        25% {
          opacity: 0.25;
        }
        85% {
          stroke-dashoffset: 0;
          opacity: 0.25;
        }
        100% {
          stroke-dashoffset: 0;
          opacity: 0.15;
        }
      }
      @keyframes line-draw-2 {
        0% {
          stroke-dashoffset: 350;
          opacity: 0;
        }
        15% {
          opacity: 0.35;
        }
        75% {
          stroke-dashoffset: 0;
          opacity: 0.35;
        }
        100% {
          stroke-dashoffset: 0;
          opacity: 0.25;
        }
      }
      @keyframes line-draw-3 {
        0% {
          stroke-dashoffset: 200;
          opacity: 0;
        }
        30% {
          opacity: 0.2;
        }
        90% {
          stroke-dashoffset: 0;
          opacity: 0.2;
        }
        100% {
          stroke-dashoffset: 0;
          opacity: 0.1;
        }
      }
      .constellation-star-0 {
        transform-origin: center;
        animation: star-appear-0 4s ease-out infinite;
        animation-delay: calc(var(--i, 0) * 0.1s);
      }
      .constellation-star-1 {
        transform-origin: center;
        animation: star-appear-1 5s ease-out infinite;
        animation-delay: calc(var(--i, 0) * 0.12s);
      }
      .constellation-star-2 {
        transform-origin: center;
        animation: star-appear-2 6s ease-out infinite;
        animation-delay: calc(var(--i, 0) * 0.08s);
      }
      .constellation-line-0 {
        stroke-dasharray: 300;
        stroke-dashoffset: 300;
        animation: line-draw-0 5s ease-out infinite;
        animation-delay: calc(var(--i, 0) * 0.15s);
      }
      .constellation-line-1 {
        stroke-dasharray: 250;
        stroke-dashoffset: 250;
        animation: line-draw-1 6s ease-out infinite;
        animation-delay: calc(var(--i, 0) * 0.18s);
      }
      .constellation-line-2 {
        stroke-dasharray: 350;
        stroke-dashoffset: 350;
        animation: line-draw-2 7s ease-out infinite;
        animation-delay: calc(var(--i, 0) * 0.12s);
      }
      .constellation-line-3 {
        stroke-dasharray: 200;
        stroke-dashoffset: 200;
        animation: line-draw-3 4s ease-out infinite;
        animation-delay: calc(var(--i, 0) * 0.2s);
      }
    </style>
    """
  end
end
