defmodule Droodotfoo.StateResetHelper do
  @moduledoc """
  Resets all shared GenServer state between tests to prevent interference.
  Call this in test setup blocks.
  """

  def reset_all_state do
    # Reset PerformanceMonitor metrics
    if Process.whereis(Droodotfoo.PerformanceMonitor) do
      Droodotfoo.PerformanceMonitor.reset_metrics()
    end

    # Small delay to ensure all resets complete
    Process.sleep(10)
    :ok
  end
end
