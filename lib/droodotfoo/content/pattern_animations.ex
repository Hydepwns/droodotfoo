defmodule Droodotfoo.Content.PatternAnimations do
  @moduledoc """
  CSS animation definitions for pattern styles.
  Separates animation logic from pattern generation.
  """

  @doc """
  Returns CSS animations for a specific pattern style.
  Returns empty string if style has no animations or is unknown.
  """
  @spec get_animations(atom) :: String.t()
  def get_animations(:waves), do: waves_animations()
  def get_animations(:noise), do: noise_animations()
  def get_animations(:lines), do: lines_animations()
  def get_animations(:dots), do: dots_animations()
  def get_animations(:circuit), do: circuit_animations()
  def get_animations(:glitch), do: glitch_animations()
  def get_animations(:geometric), do: geometric_animations()
  def get_animations(:grid), do: grid_animations()
  def get_animations(:flow_field), do: flow_field_animations()
  def get_animations(:interference), do: interference_animations()
  def get_animations(:topology), do: topology_animations()
  def get_animations(:voronoi), do: voronoi_animations()
  def get_animations(:isometric), do: isometric_animations()
  def get_animations(:composite), do: ""
  def get_animations(_), do: ""

  @doc """
  Waves pattern animations - flowing sine wave motion.
  """
  def waves_animations do
    """
    <style>
      @keyframes wave-morph-1 {
        0% { transform: translateX(0) translateY(0) scaleY(1); opacity: 0.7; filter: blur(0px); }
        15% { transform: translateX(10px) translateY(-5px) scaleY(1.05); opacity: 0.85; filter: blur(0.3px); }
        30% { transform: translateX(25px) translateY(-2px) scaleY(0.95); opacity: 1; filter: blur(0px); }
        45% { transform: translateX(35px) translateY(2px) scaleY(1.03); opacity: 0.9; filter: blur(0.2px); }
        60% { transform: translateX(25px) translateY(5px) scaleY(1); opacity: 0.8; filter: blur(0px); }
        75% { transform: translateX(10px) translateY(3px) scaleY(0.98); opacity: 0.85; filter: blur(0.1px); }
        100% { transform: translateX(0) translateY(0) scaleY(1); opacity: 0.7; filter: blur(0px); }
      }
      @keyframes wave-morph-2 {
        0% { transform: translateX(0) translateY(0) scaleY(1) rotate(0deg); opacity: 0.8; }
        20% { transform: translateX(-8px) translateY(3px) scaleY(1.04) rotate(-1deg); opacity: 0.95; }
        40% { transform: translateX(-18px) translateY(-2px) scaleY(0.96) rotate(0deg); opacity: 1; }
        60% { transform: translateX(-28px) translateY(2px) scaleY(1.02) rotate(1deg); opacity: 0.9; }
        80% { transform: translateX(-15px) translateY(-1px) scaleY(0.98) rotate(-0.5deg); opacity: 0.85; }
        100% { transform: translateX(0) translateY(0) scaleY(1) rotate(0deg); opacity: 0.8; }
      }
      @keyframes wave-morph-3 {
        0% { transform: translateX(0) scale(1) rotate(0deg); opacity: 0.6; filter: blur(0px); }
        25% { transform: translateX(12px) scale(1.05) rotate(0.5deg); opacity: 0.9; filter: blur(0.5px); }
        50% { transform: translateX(20px) scale(1.08) rotate(0deg); opacity: 1; filter: blur(0.8px); }
        75% { transform: translateX(12px) scale(1.03) rotate(-0.5deg); opacity: 0.85; filter: blur(0.4px); }
        100% { transform: translateX(0) scale(1) rotate(0deg); opacity: 0.6; filter: blur(0px); }
      }
      .wave-0 { animation: wave-morph-1 7s ease-in-out infinite; }
      .wave-1 { animation: wave-morph-2 9s ease-in-out infinite; }
      .wave-2 { animation: wave-morph-3 11s ease-in-out infinite; }
    </style>
    """
  end

  @doc """
  Noise pattern animations - TV static flicker effect.
  """
  def noise_animations do
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

  @doc """
  Lines pattern animations - pulsing line effect.
  """
  def lines_animations do
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

  @doc """
  Dots pattern animations - gentle breathing scale effect.
  """
  def dots_animations do
    """
    <style>
      @keyframes dot-morph {
        0% {
          transform: scale(0.92);
          opacity: 0.6;
        }
        25% {
          transform: scale(1.05);
          opacity: 0.85;
        }
        50% {
          transform: scale(1.08);
          opacity: 1;
        }
        75% {
          transform: scale(1.02);
          opacity: 0.8;
        }
        100% {
          transform: scale(0.92);
          opacity: 0.6;
        }
      }
      .dot-pulse {
        animation: dot-morph 8s ease-in-out infinite;
        animation-delay: calc(var(--delay, 0) * 0.15s);
      }
    </style>
    """
  end

  @doc """
  Circuit pattern animations - energy flowing through traces.
  """
  def circuit_animations do
    """
    <style>
      @keyframes circuit-energy {
        0%, 100% {
          opacity: 0.3;
          filter: drop-shadow(0 0 0px #ffffff);
          stroke-width: 0.8;
          transform: scale(1);
        }
        10% {
          opacity: 0.6;
          filter: drop-shadow(0 0 1px #ffffff);
          stroke-width: 1.2;
          transform: scale(1.01);
        }
        20% {
          opacity: 0.9;
          filter: drop-shadow(0 0 3px #ffffff) drop-shadow(0 0 6px #ffffff);
          stroke-width: 1.8;
          transform: scale(1.02);
        }
        30% {
          opacity: 1;
          filter: drop-shadow(0 0 6px #ffffff) drop-shadow(0 0 12px #ffffff) drop-shadow(0 0 18px #ffffff);
          stroke-width: 2.5;
          transform: scale(1.03);
        }
        45% {
          opacity: 0.85;
          filter: drop-shadow(0 0 4px #ffffff) drop-shadow(0 0 8px #ffffff);
          stroke-width: 2;
          transform: scale(1.01);
        }
        60% {
          opacity: 0.6;
          filter: drop-shadow(0 0 2px #ffffff);
          stroke-width: 1.5;
          transform: scale(1);
        }
        80% {
          opacity: 0.4;
          filter: drop-shadow(0 0 1px #ffffff);
          stroke-width: 1;
          transform: scale(0.99);
        }
      }
      .circuit-glow {
        animation: circuit-energy 4s ease-in-out infinite;
        animation-delay: calc(var(--index, 0) * 0.18s);
      }
    </style>
    """
  end

  @doc """
  Glitch pattern animations - digital corruption effect.
  """
  def glitch_animations do
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

  @doc """
  Geometric pattern animations - independent shape rotation.
  """
  def geometric_animations do
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

  @doc """
  Grid pattern animations - cellular breathing effect.
  """
  def grid_animations do
    """
    <style>
      @keyframes grid-breathe {
        0% {
          opacity: 0.3;
          transform: scale(0.95) rotate(0deg);
          filter: blur(0px);
        }
        15% {
          opacity: 0.6;
          transform: scale(0.98) rotate(0.5deg);
          filter: blur(0.1px);
        }
        30% {
          opacity: 0.85;
          transform: scale(1.02) rotate(0deg);
          filter: blur(0.2px);
        }
        50% {
          opacity: 1;
          transform: scale(1.06) rotate(-0.5deg);
          filter: blur(0.3px);
        }
        70% {
          opacity: 0.85;
          transform: scale(1.02) rotate(0deg);
          filter: blur(0.2px);
        }
        85% {
          opacity: 0.6;
          transform: scale(0.98) rotate(0.5deg);
          filter: blur(0.1px);
        }
        100% {
          opacity: 0.3;
          transform: scale(0.95) rotate(0deg);
          filter: blur(0px);
        }
      }
      .grid-cell {
        animation: grid-breathe 6s ease-in-out infinite;
        animation-delay: calc(var(--delay, 0) * 0.12s);
      }
    </style>
    """
  end

  @doc """
  Flow field pattern animations - gentle flowing motion along paths.
  """
  def flow_field_animations do
    """
    <style>
      @keyframes flow-drift-0 {
        0% {
          opacity: 0.4;
          stroke-dashoffset: 0;
          filter: blur(0px);
        }
        25% {
          opacity: 0.7;
          stroke-dashoffset: -50;
          filter: blur(0.2px);
        }
        50% {
          opacity: 1;
          stroke-dashoffset: -100;
          filter: blur(0px);
        }
        75% {
          opacity: 0.6;
          stroke-dashoffset: -150;
          filter: blur(0.1px);
        }
        100% {
          opacity: 0.4;
          stroke-dashoffset: -200;
          filter: blur(0px);
        }
      }
      @keyframes flow-drift-1 {
        0% {
          opacity: 0.5;
          stroke-dashoffset: 0;
          transform: translateX(0);
        }
        50% {
          opacity: 0.9;
          stroke-dashoffset: -80;
          transform: translateX(2px);
        }
        100% {
          opacity: 0.5;
          stroke-dashoffset: -160;
          transform: translateX(0);
        }
      }
      @keyframes flow-drift-2 {
        0% {
          opacity: 0.3;
          stroke-dashoffset: 0;
          transform: translateY(0);
        }
        33% {
          opacity: 0.8;
          stroke-dashoffset: -60;
          transform: translateY(-1px);
        }
        66% {
          opacity: 0.95;
          stroke-dashoffset: -120;
          transform: translateY(1px);
        }
        100% {
          opacity: 0.3;
          stroke-dashoffset: -180;
          transform: translateY(0);
        }
      }
      @keyframes flow-drift-3 {
        0% {
          opacity: 0.6;
          stroke-dashoffset: 0;
        }
        25% {
          opacity: 0.85;
          stroke-dashoffset: -40;
        }
        75% {
          opacity: 0.75;
          stroke-dashoffset: -120;
        }
        100% {
          opacity: 0.6;
          stroke-dashoffset: -160;
        }
      }
      .flow-line-0 {
        stroke-dasharray: 20 10;
        animation: flow-drift-0 8s linear infinite;
      }
      .flow-line-1 {
        stroke-dasharray: 15 8;
        animation: flow-drift-1 10s linear infinite;
      }
      .flow-line-2 {
        stroke-dasharray: 25 12;
        animation: flow-drift-2 12s linear infinite;
      }
      .flow-line-3 {
        stroke-dasharray: 18 6;
        animation: flow-drift-3 9s linear infinite;
      }
    </style>
    """
  end

  @doc """
  Interference pattern animations - pulsing and phase shift effects.
  """
  def interference_animations do
    """
    <style>
      @keyframes interference-pulse {
        0% {
          opacity: 0.3;
          transform: scale(1);
        }
        50% {
          opacity: 0.6;
          transform: scale(1.002);
        }
        100% {
          opacity: 0.3;
          transform: scale(1);
        }
      }
      @keyframes interference-phase-0 {
        0% {
          stroke-dashoffset: 0;
          opacity: 0.4;
        }
        100% {
          stroke-dashoffset: 50;
          opacity: 0.4;
        }
      }
      @keyframes interference-phase-1 {
        0% {
          stroke-dashoffset: 0;
          opacity: 0.35;
        }
        100% {
          stroke-dashoffset: -50;
          opacity: 0.35;
        }
      }
      @keyframes interference-grid-shift-0 {
        0% {
          transform: translateX(0) translateY(0);
          opacity: 0.3;
        }
        50% {
          transform: translateX(2px) translateY(1px);
          opacity: 0.5;
        }
        100% {
          transform: translateX(0) translateY(0);
          opacity: 0.3;
        }
      }
      @keyframes interference-grid-shift-1 {
        0% {
          transform: translateX(0) translateY(0);
          opacity: 0.35;
        }
        50% {
          transform: translateX(-2px) translateY(-1px);
          opacity: 0.45;
        }
        100% {
          transform: translateX(0) translateY(0);
          opacity: 0.35;
        }
      }
      .interference-ring {
        animation: interference-pulse 4s ease-in-out infinite;
        transform-origin: center;
      }
      .interference-wave-0 {
        stroke-dasharray: 10 5;
        animation: interference-phase-0 6s linear infinite;
      }
      .interference-wave-1 {
        stroke-dasharray: 8 4;
        animation: interference-phase-1 8s linear infinite;
      }
      .interference-wave-2 {
        stroke-dasharray: 12 6;
        animation: interference-phase-0 10s linear infinite;
      }
      .interference-grid-0 {
        animation: interference-grid-shift-0 5s ease-in-out infinite;
      }
      .interference-grid-1 {
        animation: interference-grid-shift-1 7s ease-in-out infinite;
      }
    </style>
    """
  end

  @doc """
  Topology pattern animations - contour line drawing effect.
  """
  def topology_animations do
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

  @doc """
  Voronoi pattern animations - cell pulsing effect.
  """
  def voronoi_animations do
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

  @doc """
  Isometric pattern animations - 3D cube depth effect.
  """
  def isometric_animations do
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
