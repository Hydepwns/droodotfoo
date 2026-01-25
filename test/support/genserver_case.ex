defmodule Droodotfoo.GenServerCase do
  @moduledoc """
  Test case for tests that need isolated GenServer processes.
  Ensures proper setup and teardown of GenServers between tests.
  """

  use ExUnit.CaseTemplate

  setup do
    # List of GenServers that need to be managed
    # Note: RaxolApp and TerminalBridge are archived
    genservers = [
      {Droodotfoo.PerformanceMonitor, []},
      {Droodotfoo.PluginSystem, []}
    ]

    # Stop any existing instances
    for {module, _opts} <- genservers do
      if pid = Process.whereis(module) do
        try do
          GenServer.stop(pid, :normal, 100)
        catch
          :exit, _ -> :ok
        end
      end
    end

    # Small delay to ensure cleanup
    Process.sleep(20)

    # Start fresh instances using start_supervised
    started_pids =
      for {module, opts} <- genservers do
        case start_supervised({module, opts}, restart: :temporary) do
          {:ok, pid} -> {module, pid}
          {:error, {:already_started, pid}} -> {module, pid}
          _ -> nil
        end
      end
      |> Enum.filter(& &1)

    # Reset any state if modules support it
    if Process.whereis(Droodotfoo.PerformanceMonitor) do
      try do
        Droodotfoo.PerformanceMonitor.reset_metrics()
      rescue
        _ -> :ok
      end
    end

    # Return the started processes for potential use in tests
    {:ok, genservers: started_pids}
  end
end
