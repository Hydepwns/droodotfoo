defmodule Droodotfoo.Content.PatternAnimations.Lines do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes line-wave {
        0% {
          opacity: 0.2;
          transform: translateY(0) scaleX(1);
          stroke-width: 0.5;
          filter: blur(0px);
        }
        20% {
          opacity: 0.6;
          transform: translateY(-3px) scaleX(1.02);
          stroke-width: 1.5;
          filter: blur(0.2px);
        }
        40% {
          opacity: 1;
          transform: translateY(-5px) scaleX(1.05);
          stroke-width: 2.5;
          filter: blur(0px);
        }
        60% {
          opacity: 0.8;
          transform: translateY(-3px) scaleX(1.02);
          stroke-width: 2;
          filter: blur(0.3px);
        }
        80% {
          opacity: 0.4;
          transform: translateY(-1px) scaleX(1);
          stroke-width: 1;
          filter: blur(0.1px);
        }
        100% {
          opacity: 0.2;
          transform: translateY(0) scaleX(1);
          stroke-width: 0.5;
          filter: blur(0px);
        }
      }
      .line-pulse {
        animation: line-wave 5s ease-in-out infinite;
        animation-delay: calc(var(--index, 0) * 0.08s);
      }
    </style>
    """
  end
end
