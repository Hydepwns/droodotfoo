defmodule Droodotfoo.Content.PatternAnimations.Glitch do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes glitch-shift-1 {
        0%, 100% {
          transform: translateX(0) skew(0deg) scale(1);
          opacity: 0.9;
        }
        2% {
          transform: translateX(-15px) skew(-5deg) scale(1.15);
          opacity: 0.6;
        }
        4% {
          transform: translateX(12px) skew(3deg) scale(1.08);
          opacity: 1;
        }
        6% {
          transform: translateX(0) skew(0deg) scale(1);
          opacity: 0.8;
        }
      }
      @keyframes glitch-shift-2 {
        0%, 100% {
          transform: translateX(0) skew(0deg) scale(1);
          opacity: 0.8;
        }
        3% {
          transform: translateX(18px) skew(6deg) scale(1.2);
          opacity: 0.5;
        }
        5% {
          transform: translateX(-10px) skew(-4deg) scale(1.12);
          opacity: 0.95;
        }
        7% {
          transform: translateX(0) skew(0deg) scale(1);
          opacity: 0.7;
        }
      }
      @keyframes glitch-shift-3 {
        0%, 100% {
          transform: translateX(0) skew(0deg) scaleY(1);
          opacity: 0.7;
        }
        4% {
          transform: translateX(-20px) skew(-8deg) scaleY(1.25);
          opacity: 0.4;
        }
        6% {
          transform: translateX(15px) skew(5deg) scaleY(1.18);
          opacity: 1;
        }
        8% {
          transform: translateX(0) skew(0deg) scaleY(1);
          opacity: 0.6;
        }
      }
      @keyframes scanline-glitch {
        0%, 100% {
          opacity: 0.15;
          transform: translateY(0);
        }
        25% {
          opacity: 0.4;
          transform: translateY(-100%);
        }
        50% {
          opacity: 0.6;
          transform: translateY(100%);
        }
        75% {
          opacity: 0.3;
          transform: translateY(50%);
        }
      }
      .glitch-bar:nth-child(4n+1) {
        animation: glitch-shift-1 3s steps(2, end) infinite;
        animation-delay: calc(var(--index, 0) * 0.1s);
      }
      .glitch-bar:nth-child(4n+2) {
        animation: glitch-shift-2 3.5s steps(2, end) infinite;
        animation-delay: calc(var(--index, 0) * 0.15s);
      }
      .glitch-bar:nth-child(4n+3) {
        animation: glitch-shift-3 4s steps(2, end) infinite;
        animation-delay: calc(var(--index, 0) * 0.12s);
      }
      .glitch-bar:nth-child(4n) {
        animation: glitch-shift-1 2.8s steps(2, end) infinite;
        animation-delay: calc(var(--index, 0) * 0.18s);
      }
      .scanline {
        animation: scanline-glitch 4s linear infinite;
        animation-delay: calc(var(--index, 0) * 0.3s);
      }
    </style>
    """
  end
end
