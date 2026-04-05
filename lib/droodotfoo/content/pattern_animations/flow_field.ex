defmodule Droodotfoo.Content.PatternAnimations.FlowField do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes flow-emerge-0 {
        0% {
          stroke-dashoffset: 1000;
          opacity: 0;
        }
        5% {
          opacity: 0.6;
        }
        40% {
          stroke-dashoffset: 0;
          opacity: 0.8;
        }
        60% {
          stroke-dashoffset: 0;
          opacity: 0.8;
        }
        95% {
          opacity: 0;
        }
        100% {
          stroke-dashoffset: 0;
          opacity: 0;
        }
      }
      @keyframes flow-emerge-1 {
        0% {
          stroke-dashoffset: 800;
          opacity: 0;
        }
        8% {
          opacity: 0.5;
        }
        45% {
          stroke-dashoffset: 0;
          opacity: 0.7;
        }
        65% {
          stroke-dashoffset: 0;
          opacity: 0.7;
        }
        92% {
          opacity: 0;
        }
        100% {
          stroke-dashoffset: 0;
          opacity: 0;
        }
      }
      @keyframes flow-emerge-2 {
        0% {
          stroke-dashoffset: 1200;
          opacity: 0;
        }
        3% {
          opacity: 0.4;
        }
        35% {
          stroke-dashoffset: 0;
          opacity: 0.6;
        }
        55% {
          stroke-dashoffset: 0;
          opacity: 0.6;
        }
        90% {
          opacity: 0;
        }
        100% {
          stroke-dashoffset: 0;
          opacity: 0;
        }
      }
      @keyframes flow-emerge-3 {
        0% {
          stroke-dashoffset: 600;
          opacity: 0;
        }
        10% {
          opacity: 0.7;
        }
        50% {
          stroke-dashoffset: 0;
          opacity: 0.9;
        }
        70% {
          stroke-dashoffset: 0;
          opacity: 0.9;
        }
        97% {
          opacity: 0;
        }
        100% {
          stroke-dashoffset: 0;
          opacity: 0;
        }
      }
      .flow-line-0 {
        stroke-dasharray: 1000;
        stroke-dashoffset: 1000;
        animation: flow-emerge-0 6s ease-out infinite;
        animation-delay: calc(var(--i, 0) * 0.08s);
      }
      .flow-line-1 {
        stroke-dasharray: 800;
        stroke-dashoffset: 800;
        animation: flow-emerge-1 7s ease-out infinite;
        animation-delay: calc(var(--i, 0) * 0.12s);
      }
      .flow-line-2 {
        stroke-dasharray: 1200;
        stroke-dashoffset: 1200;
        animation: flow-emerge-2 8s ease-out infinite;
        animation-delay: calc(var(--i, 0) * 0.06s);
      }
      .flow-line-3 {
        stroke-dasharray: 600;
        stroke-dashoffset: 600;
        animation: flow-emerge-3 5s ease-out infinite;
        animation-delay: calc(var(--i, 0) * 0.1s);
      }
    </style>
    """
  end
end
