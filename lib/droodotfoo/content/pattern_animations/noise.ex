defmodule Droodotfoo.Content.PatternAnimations.Noise do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes noise-flicker {
        0% { opacity: 0.7; }
        25% { opacity: 0.3; }
        50% { opacity: 0.9; }
        75% { opacity: 0.5; }
        100% { opacity: 0.7; }
      }
      .noise-cell {
        animation: noise-flicker 2.5s ease-in-out infinite;
        animation-delay: calc(var(--delay, 0) * 0.08s);
      }
    </style>
    """
  end
end
