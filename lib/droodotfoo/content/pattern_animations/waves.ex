defmodule Droodotfoo.Content.PatternAnimations.Waves do
  @moduledoc false

  @spec css :: String.t()
  def css do
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
end
