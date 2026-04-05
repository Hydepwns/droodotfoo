defmodule Droodotfoo.Content.PatternAnimations.Dots do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes dot-morph {
        0% {
          transform: scale(0.92);
          opacity: 0.6;
        }
        25% {
          transform: scale(1.05);
          opacity: 0.85;
        }
        50% {
          transform: scale(1.08);
          opacity: 1;
        }
        75% {
          transform: scale(1.02);
          opacity: 0.8;
        }
        100% {
          transform: scale(0.92);
          opacity: 0.6;
        }
      }
      .dot-pulse {
        animation: dot-morph 8s ease-in-out infinite;
        animation-delay: calc(var(--delay, 0) * 0.15s);
      }
    </style>
    """
  end
end
