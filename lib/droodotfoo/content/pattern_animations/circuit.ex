defmodule Droodotfoo.Content.PatternAnimations.Circuit do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes circuit-energy {
        0%, 100% {
          opacity: 0.4;
          filter: drop-shadow(0 0 0px #ffffff);
          stroke-width: 1;
        }
        50% {
          opacity: 0.7;
          filter: drop-shadow(0 0 2px #ffffff);
          stroke-width: 1.3;
        }
      }
      .circuit-glow {
        animation: circuit-energy 8s ease-in-out infinite;
        animation-delay: calc(var(--index, 0) * 0.25s);
      }
    </style>
    """
  end
end
