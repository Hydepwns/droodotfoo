defmodule Droodotfoo.Content.PatternAnimations.GlassCube do
  @moduledoc false

  @spec css :: String.t()
  def css do
    """
    <style>
      @keyframes gc-breathe {
        0% { opacity: var(--gc-op); transform: scale(1); }
        50% { opacity: calc(var(--gc-op) * 1.5); transform: scale(1.015); }
        100% { opacity: var(--gc-op); transform: scale(1); }
      }
      @keyframes gc-ray-pulse {
        0%, 100% { opacity: var(--gc-op, 0.1); }
        50% { opacity: calc(var(--gc-op, 0.1) * 1.8); }
      }
      @keyframes gc-particle-drift {
        0%, 100% { transform: scale(1); opacity: var(--gc-op, 0.3); }
        50% { transform: scale(1.4); opacity: calc(var(--gc-op, 0.3) * 0.5); }
      }
      .gc-layer-0 { transform-origin: center; --gc-op: 0.07; animation: gc-breathe 8s ease-in-out infinite; }
      .gc-layer-1 { transform-origin: center; --gc-op: 0.14; animation: gc-breathe 8s ease-in-out infinite 1.3s; }
      .gc-layer-2 { transform-origin: center; --gc-op: 0.23; animation: gc-breathe 8s ease-in-out infinite 2.6s; }
      .gc-layer-3 { transform-origin: center; --gc-op: 0.36; animation: gc-breathe 8s ease-in-out infinite 3.9s; }
      .gc-layer-4 { transform-origin: center; --gc-op: 0.55; animation: gc-breathe 8s ease-in-out infinite 5.2s; }
      .gc-layer-5 { transform-origin: center; --gc-op: 0.85; animation: gc-breathe 8s ease-in-out infinite 6.5s; }
      @keyframes gc-halo-pulse {
        0%, 100% { opacity: 0.06; transform: scale(1); }
        50% { opacity: 0.12; transform: scale(1.03); }
      }
      .gc-ray { animation: gc-ray-pulse 5s ease-in-out infinite; }
      .gc-halo {
        transform-origin: center;
        animation: gc-halo-pulse 10s ease-in-out infinite;
      }
      .gc-particle {
        transform-origin: center;
        animation: gc-particle-drift 7s ease-in-out infinite;
        animation-delay: calc(var(--i, 0) * 0.2s);
      }
      @keyframes gc-fragment-flicker {
        0%, 100% { opacity: 0.06; }
        30% { opacity: 0.14; }
        70% { opacity: 0.04; }
      }
      .gc-fragment {
        animation: gc-fragment-flicker 4s ease-in-out infinite;
        animation-delay: calc(var(--i, 0) * 0.3s);
      }
      @keyframes gc-orbit-flow {
        0% { stroke-dashoffset: 200; opacity: 0.06; }
        50% { stroke-dashoffset: 0; opacity: 0.12; }
        100% { stroke-dashoffset: -200; opacity: 0.06; }
      }
      .gc-orbit {
        stroke-dasharray: 12 8;
        animation: gc-orbit-flow 12s linear infinite;
      }
    </style>
    """
  end
end
