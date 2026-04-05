defmodule Droodotfoo.Content.PatternAnimations.Topology do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes topo-draw-0 {
        0% {
          stroke-dashoffset: 1000;
          opacity: 0.3;
        }
        50% {
          stroke-dashoffset: 0;
          opacity: 0.7;
        }
        100% {
          stroke-dashoffset: -1000;
          opacity: 0.3;
        }
      }
      @keyframes topo-draw-1 {
        0% {
          stroke-dashoffset: 800;
          opacity: 0.4;
        }
        50% {
          stroke-dashoffset: 0;
          opacity: 0.6;
        }
        100% {
          stroke-dashoffset: -800;
          opacity: 0.4;
        }
      }
      @keyframes topo-draw-2 {
        0% {
          stroke-dashoffset: 600;
          opacity: 0.35;
        }
        50% {
          stroke-dashoffset: 0;
          opacity: 0.65;
        }
        100% {
          stroke-dashoffset: -600;
          opacity: 0.35;
        }
      }
      .topo-line-0 {
        stroke-dasharray: 10 5;
        animation: topo-draw-0 15s linear infinite;
      }
      .topo-line-1 {
        stroke-dasharray: 8 4;
        animation: topo-draw-1 18s linear infinite;
      }
      .topo-line-2 {
        stroke-dasharray: 12 6;
        animation: topo-draw-2 12s linear infinite;
      }
    </style>
    """
  end
end
