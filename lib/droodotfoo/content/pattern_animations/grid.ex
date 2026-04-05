defmodule Droodotfoo.Content.PatternAnimations.Grid do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes grid-breathe {
        0% {
          opacity: 0.3;
          transform: scale(0.95) rotate(0deg);
          filter: blur(0px);
        }
        15% {
          opacity: 0.6;
          transform: scale(0.98) rotate(0.5deg);
          filter: blur(0.1px);
        }
        30% {
          opacity: 0.85;
          transform: scale(1.02) rotate(0deg);
          filter: blur(0.2px);
        }
        50% {
          opacity: 1;
          transform: scale(1.06) rotate(-0.5deg);
          filter: blur(0.3px);
        }
        70% {
          opacity: 0.85;
          transform: scale(1.02) rotate(0deg);
          filter: blur(0.2px);
        }
        85% {
          opacity: 0.6;
          transform: scale(0.98) rotate(0.5deg);
          filter: blur(0.1px);
        }
        100% {
          opacity: 0.3;
          transform: scale(0.95) rotate(0deg);
          filter: blur(0px);
        }
      }
      .grid-cell {
        animation: grid-breathe 6s ease-in-out infinite;
        animation-delay: calc(var(--delay, 0) * 0.12s);
      }
    </style>
    """
  end
end
