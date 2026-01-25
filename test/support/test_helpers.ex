defmodule Droodotfoo.TestHelpers do
  @moduledoc """
  Helper functions for tests, including retry logic for timing-dependent assertions.
  """

  import ExUnit.Assertions

  @doc """
  Retries an assertion function until it passes or times out.
  Useful for eventually consistent operations.

  ## Examples

      eventually(fn ->
        assert Process.alive?(pid)
      end)

      eventually(fn ->
        html = render(view)
        assert html =~ "expected content"
      end, timeout: 5000, delay: 100)
  """
  def eventually(assertion_fn, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 2000)
    delay = Keyword.get(opts, :delay, 50)

    deadline = System.monotonic_time(:millisecond) + timeout

    do_eventually(assertion_fn, deadline, delay)
  end

  defp do_eventually(assertion_fn, deadline, delay) do
    assertion_fn.()
  rescue
    error in [ExUnit.AssertionError] ->
      now = System.monotonic_time(:millisecond)

      if now < deadline do
        Process.sleep(delay)
        do_eventually(assertion_fn, deadline, delay)
      else
        # Re-raise the last error if we've timed out
        reraise error, __STACKTRACE__
      end
  end

  @doc """
  Waits for a GenServer to be ready by checking if it responds to a call.
  """
  def wait_for_genserver(name, timeout \\ 1000) do
    eventually(
      fn ->
        case Process.whereis(name) do
          nil ->
            flunk("GenServer #{inspect(name)} is not running")

          pid ->
            assert Process.alive?(pid)
            # Try a simple call to ensure it's responsive
            try do
              GenServer.call(pid, :ping, 100)
            catch
              :exit, {:timeout, _} ->
                flunk("GenServer #{inspect(name)} is not responding")

              :exit, {:noproc, _} ->
                flunk("GenServer #{inspect(name)} died")
            end
        end
      end,
      timeout: timeout
    )
  end

  @doc """
  Helper to send a keydown event and wait for the view to update.
  """
  def send_key_and_wait(view, key, value \\ nil) do
    value = value || %{"key" => key}

    # Send the key event
    html = Phoenix.LiveViewTest.render_keydown(view, "key_press", value)

    # Give the view a moment to process
    Process.sleep(20)

    html
  end
end
