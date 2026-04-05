defmodule Droodotfoo.Content.PatternAnimations.Isometric do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes iso-glow-0 {
        0%, 100% {
          opacity: 0.5;
          filter: drop-shadow(0 0 0px #ffffff);
        }
        50% {
          opacity: 0.8;
          filter: drop-shadow(0 0 3px #ffffff);
        }
      }
      @keyframes iso-glow-1 {
        0%, 100% {
          opacity: 0.35;
          filter: drop-shadow(0 0 0px #ffffff);
        }
        50% {
          opacity: 0.55;
          filter: drop-shadow(0 0 2px #ffffff);
        }
      }
      @keyframes iso-glow-2 {
        0%, 100% {
          opacity: 0.25;
          filter: drop-shadow(0 0 0px #ffffff);
        }
        50% {
          opacity: 0.4;
          filter: drop-shadow(0 0 1px #ffffff);
        }
      }
      .iso-face-0 {
        animation: iso-glow-0 5s ease-in-out infinite;
        animation-delay: calc(var(--index, 0) * 0.1s);
      }
      .iso-face-1 {
        animation: iso-glow-1 6s ease-in-out infinite;
        animation-delay: calc(var(--index, 0) * 0.12s);
      }
      .iso-face-2 {
        animation: iso-glow-2 7s ease-in-out infinite;
        animation-delay: calc(var(--index, 0) * 0.15s);
      }
    </style>
    """
  end
end
