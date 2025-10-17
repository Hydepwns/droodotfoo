defmodule Droodotfoo.StateResetHelper do
  @moduledoc """
  Resets all shared GenServer state between tests to prevent interference.
  Call this in test setup blocks.
  """

  def reset_all_state do
    # Reset RaxolApp state (cursor, buffer, mode, etc)
    if Process.whereis(Droodotfoo.RaxolApp) do
      Droodotfoo.RaxolApp.reset_state()
    end

    # Reset TerminalBridge cache
    if Process.whereis(Droodotfoo.TerminalBridge) do
      Droodotfoo.TerminalBridge.invalidate_cache()
    end

    # Reset PluginSystem.Manager (clear active plugin)
    if Process.whereis(Droodotfoo.PluginSystem) do
      Droodotfoo.PluginSystem.reset_state()
    end

    # Reset PerformanceMonitor metrics
    if Process.whereis(Droodotfoo.PerformanceMonitor) do
      Droodotfoo.PerformanceMonitor.reset_metrics()
    end

    # Small delay to ensure all resets complete
    Process.sleep(10)
    :ok
  end
end
