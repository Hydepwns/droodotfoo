defmodule Droodotfoo.Content.PatternAnimations.Voronoi do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes voronoi-pulse-0 {
        0%, 100% {
          opacity: 0.3;
          stroke-width: 0.5;
        }
        50% {
          opacity: 0.6;
          stroke-width: 1.5;
        }
      }
      @keyframes voronoi-pulse-1 {
        0%, 100% {
          opacity: 0.4;
          stroke-width: 0.8;
        }
        50% {
          opacity: 0.7;
          stroke-width: 1.2;
        }
      }
      @keyframes voronoi-pulse-2 {
        0%, 100% {
          opacity: 0.35;
          stroke-width: 0.6;
        }
        50% {
          opacity: 0.55;
          stroke-width: 1.0;
        }
      }
      @keyframes voronoi-point-pulse {
        0%, 100% {
          transform: scale(1);
          opacity: 0.4;
        }
        50% {
          transform: scale(1.5);
          opacity: 0.8;
        }
      }
      .voronoi-edge-0 {
        animation: voronoi-pulse-0 6s ease-in-out infinite;
      }
      .voronoi-edge-1 {
        animation: voronoi-pulse-1 8s ease-in-out infinite;
      }
      .voronoi-edge-2 {
        animation: voronoi-pulse-2 10s ease-in-out infinite;
      }
      .voronoi-point-0 {
        animation: voronoi-point-pulse 4s ease-in-out infinite;
        transform-origin: center;
      }
      .voronoi-point-1 {
        animation: voronoi-point-pulse 5s ease-in-out infinite;
        animation-delay: 0.5s;
        transform-origin: center;
      }
    </style>
    """
  end
end
