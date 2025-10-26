defmodule Droodotfoo.StateResetHelper do
  @moduledoc """
  Resets all shared GenServer state between tests to prevent interference.
  Call this in test setup blocks.

  Note: Some modules (RaxolApp, TerminalBridge, PluginSystem) are archived.
  Checks for module availability before attempting reset.
  """

  def reset_all_state do
    # Reset RaxolApp state (cursor, buffer, mode, etc) - ARCHIVED
    if Code.ensure_loaded?(Droodotfoo.RaxolApp) and
         Process.whereis(Droodotfoo.RaxolApp) do
      Droodotfoo.RaxolApp.reset_state()
    end

    # Reset TerminalBridge cache - ARCHIVED
    if Code.ensure_loaded?(Droodotfoo.TerminalBridge) and
         Process.whereis(Droodotfoo.TerminalBridge) do
      Droodotfoo.TerminalBridge.invalidate_cache()
    end

    # Reset PluginSystem.Manager (clear active plugin) - ARCHIVED
    if Code.ensure_loaded?(Droodotfoo.PluginSystem) and
         Process.whereis(Droodotfoo.PluginSystem) do
      Droodotfoo.PluginSystem.reset_state()
    end

    # Reset PerformanceMonitor metrics - ACTIVE
    if Process.whereis(Droodotfoo.PerformanceMonitor) do
      Droodotfoo.PerformanceMonitor.reset_metrics()
    end

    # Small delay to ensure all resets complete
    Process.sleep(10)
    :ok
  end
end
