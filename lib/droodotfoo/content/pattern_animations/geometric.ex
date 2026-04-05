defmodule Droodotfoo.Content.PatternAnimations.Geometric do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes shape-spin-cw {
        0% { transform: rotate(0deg) scale(1); opacity: 0.6; }
        50% { transform: rotate(180deg) scale(1.08); opacity: 1; }
        100% { transform: rotate(360deg) scale(1); opacity: 0.6; }
      }
      @keyframes shape-spin-ccw {
        0% { transform: rotate(0deg) scale(1); opacity: 0.7; }
        50% { transform: rotate(-180deg) scale(1.05); opacity: 0.95; }
        100% { transform: rotate(-360deg) scale(1); opacity: 0.7; }
      }
      @keyframes shape-spin-slow {
        0% { transform: rotate(0deg) scale(0.95); opacity: 0.5; }
        50% { transform: rotate(180deg) scale(1.1); opacity: 0.9; }
        100% { transform: rotate(360deg) scale(0.95); opacity: 0.5; }
      }
      .shape-rotate {
        transform-origin: center;
      }
      .shape-rotate:nth-child(3n+1) {
        animation: shape-spin-cw 12s linear infinite;
      }
      .shape-rotate:nth-child(3n+2) {
        animation: shape-spin-ccw 16s linear infinite;
      }
      .shape-rotate:nth-child(3n) {
        animation: shape-spin-slow 20s linear infinite;
      }
    </style>
    """
  end
end
