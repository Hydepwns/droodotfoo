defmodule Droodotfoo.RaxolAppTest do
  use ExUnit.Case, async: false

  alias Droodotfoo.RaxolApp

  setup do
    # Use the existing RaxolApp from the application supervisor
    # or start a supervised one if it doesn't exist
    pid = case Process.whereis(RaxolApp) do
      nil ->
        {:ok, pid} = start_supervised(RaxolApp)
        pid
      existing_pid ->
        existing_pid
    end

    # Reset all shared state to prevent test interference
    Droodotfoo.StateResetHelper.reset_all_state()

    # Verify the process is alive
    {:ok, pid: pid}
  end


  describe "start_link/1" do
    test "starts the GenServer with default state", %{pid: pid} do
      assert Process.alive?(pid)

      state = RaxolApp.get_buffer()
      assert is_map(state)
      assert Map.has_key?(state, :lines)
    end

    test "registers with the correct name" do
      assert Process.whereis(RaxolApp) != nil
    end
  end

  describe "handle_input/1 - navigation mode" do
    test "handles 'j' key to move cursor down" do
      # Enable vim mode first
      RaxolApp.send_input("v")

      initial_buffer = RaxolApp.get_buffer()
      RaxolApp.send_input("j")
      new_buffer = RaxolApp.get_buffer()

      # Buffer should have changed (cursor moved)
      refute initial_buffer == new_buffer
    end

    test "handles 'k' key to move cursor up" do
      # Enable vim mode first
      RaxolApp.send_input("v")

      # First move down a few times
      RaxolApp.send_input("j")
      RaxolApp.send_input("j")

      buffer_before = RaxolApp.get_buffer()
      RaxolApp.send_input("k")
      buffer_after = RaxolApp.get_buffer()

      refute buffer_before == buffer_after
    end

    test "handles 'h' key for left navigation" do
      _initial_buffer = RaxolApp.get_buffer()
      RaxolApp.send_input("h")
      new_buffer = RaxolApp.get_buffer()

      # In navigation mode, h might not change anything if at leftmost position
      assert is_map(new_buffer)
    end

    test "handles 'l' key for right navigation" do
      _initial_buffer = RaxolApp.get_buffer()
      RaxolApp.send_input("l")
      new_buffer = RaxolApp.get_buffer()

      assert is_map(new_buffer)
    end

    test "handles 'g' key to jump to top" do
      # Move down first
      RaxolApp.send_input("j")
      RaxolApp.send_input("j")
      RaxolApp.send_input("j")

      RaxolApp.send_input("g")
      buffer = RaxolApp.get_buffer()

      assert is_map(buffer)
    end

    test "handles 'G' key to jump to bottom" do
      RaxolApp.send_input("G")
      buffer = RaxolApp.get_buffer()

      assert is_map(buffer)
    end

    test "handles Enter key for selection" do
      RaxolApp.send_input("Enter")
      buffer = RaxolApp.get_buffer()

      assert is_map(buffer)
    end

    test "handles 't' key to enable trail" do
      RaxolApp.send_input("t")
      buffer = RaxolApp.get_buffer()

      assert is_map(buffer)
    end

    test "handles 'T' key to clear trail" do
      # First enable trail
      RaxolApp.send_input("t")
      # Then clear it
      RaxolApp.send_input("T")
      buffer = RaxolApp.get_buffer()

      assert is_map(buffer)
    end

    test "handles Tab key for autocomplete" do
      RaxolApp.send_input("Tab")
      buffer = RaxolApp.get_buffer()

      assert is_map(buffer)
    end

    test "ignores unknown keys in navigation mode" do
      _initial_buffer = RaxolApp.get_buffer()
      RaxolApp.send_input("xyz")
      new_buffer = RaxolApp.get_buffer()

      # Buffer might change due to rendering, but should be valid
      assert is_map(new_buffer)
    end
  end

  describe "handle_input/1 - command mode" do
    test "enters command mode with ':' key" do
      _initial_buffer = RaxolApp.get_buffer()
      RaxolApp.send_input(":")
      buffer = RaxolApp.get_buffer()

      # Should show command prompt
      buffer_text = buffer_to_text(buffer)
      assert String.contains?(buffer_text, ":") or String.contains?(buffer_text, "_")
    end

    test "exits command mode with Escape key" do
      # Enter command mode
      RaxolApp.send_input(":")
      # Exit command mode
      RaxolApp.send_input("Escape")

      buffer = RaxolApp.get_buffer()
      buffer_text = buffer_to_text(buffer)

      # Should show navigation hint instead of command prompt
      assert String.contains?(buffer_text, "? help") or
               String.contains?(buffer_text, ": cmd") or
               String.contains?(buffer_text, "/ search")
    end

    test "handles typing in command mode" do
      # Enter command mode
      RaxolApp.send_input(":")
      # Type command
      RaxolApp.send_input("h")
      RaxolApp.send_input("e")
      RaxolApp.send_input("l")
      RaxolApp.send_input("p")

      buffer = RaxolApp.get_buffer()
      buffer_text = buffer_to_text(buffer)

      # Should show the typed command
      assert String.contains?(buffer_text, "help") or String.contains?(buffer_text, ":help")
    end

    test "handles Backspace in command mode" do
      # Enter command mode and type
      RaxolApp.send_input(":")
      RaxolApp.send_input("h")
      RaxolApp.send_input("e")
      RaxolApp.send_input("l")
      RaxolApp.send_input("p")
      # Delete last character
      RaxolApp.send_input("Backspace")

      buffer = RaxolApp.get_buffer()
      buffer_text = buffer_to_text(buffer)

      # Should show "hel" instead of "help"
      assert String.contains?(buffer_text, "hel") or String.contains?(buffer_text, ":hel")
    end

    test "executes command with Enter key" do
      # Enter command mode and type help
      RaxolApp.send_input(":")
      RaxolApp.send_input("h")
      RaxolApp.send_input("e")
      RaxolApp.send_input("l")
      RaxolApp.send_input("p")
      RaxolApp.send_input("Enter")

      buffer = RaxolApp.get_buffer()
      buffer_text = buffer_to_text(buffer)

      # Should show help content
      assert String.contains?(buffer_text, "Available Commands") or
               String.contains?(buffer_text, "help") or
               String.contains?(buffer_text, "commands")
    end

    test "handles 'ls' command" do
      RaxolApp.send_input(":")
      RaxolApp.send_input("l")
      RaxolApp.send_input("s")
      RaxolApp.send_input("Enter")

      buffer = RaxolApp.get_buffer()
      buffer_text = buffer_to_text(buffer)

      # Should show directory listing
      assert String.contains?(buffer_text, "home") or
               String.contains?(buffer_text, "projects") or
               String.contains?(buffer_text, "Directory")
    end

    test "handles 'clear' command" do
      # Add some content first
      RaxolApp.send_input(":")
      RaxolApp.send_input("h")
      RaxolApp.send_input("e")
      RaxolApp.send_input("l")
      RaxolApp.send_input("p")
      RaxolApp.send_input("Enter")

      # Now clear
      RaxolApp.send_input(":")
      RaxolApp.send_input("c")
      RaxolApp.send_input("l")
      RaxolApp.send_input("e")
      RaxolApp.send_input("a")
      RaxolApp.send_input("r")
      RaxolApp.send_input("Enter")

      buffer = RaxolApp.get_buffer()

      # Should return to home view
      assert is_map(buffer)
    end
  end

  describe "handle_input/1 - search mode" do
    test "enters search mode with '/' key" do
      RaxolApp.send_input("/")
      buffer = RaxolApp.get_buffer()
      buffer_text = buffer_to_text(buffer)

      # Should show search prompt
      assert String.contains?(buffer_text, "/") or String.contains?(buffer_text, "search")
    end

    test "types search query" do
      RaxolApp.send_input("/")
      RaxolApp.send_input("e")
      RaxolApp.send_input("l")
      RaxolApp.send_input("i")
      RaxolApp.send_input("x")
      RaxolApp.send_input("i")
      RaxolApp.send_input("r")

      buffer = RaxolApp.get_buffer()
      buffer_text = buffer_to_text(buffer)

      # Should show the search query
      assert String.contains?(buffer_text, "elixir") or String.contains?(buffer_text, "/elixir")
    end

    test "exits search mode with Escape" do
      RaxolApp.send_input("/")
      RaxolApp.send_input("t")
      RaxolApp.send_input("e")
      RaxolApp.send_input("s")
      RaxolApp.send_input("t")
      RaxolApp.send_input("Escape")

      buffer = RaxolApp.get_buffer()
      buffer_text = buffer_to_text(buffer)

      # Should return to normal mode
      assert String.contains?(buffer_text, "Press") or
               String.contains?(buffer_text, "navigate") or
               not String.contains?(buffer_text, "/test")
    end
  end

  describe "get_buffer/0" do
    test "returns a valid buffer structure" do
      buffer = RaxolApp.get_buffer()

      assert is_map(buffer)
      assert Map.has_key?(buffer, :lines)
      assert is_list(buffer.lines)

      # Check buffer dimensions
      assert length(buffer.lines) == 45

      # Check each line structure
      Enum.each(buffer.lines, fn line ->
        assert is_map(line)
        assert Map.has_key?(line, :cells)
        assert is_list(line.cells)
        assert length(line.cells) == 110
      end)
    end

    test "buffer updates after input" do
      buffer1 = RaxolApp.get_buffer()
      # Use arrow key which always works (doesn't require vim mode)
      RaxolApp.send_input("ArrowDown")
      buffer2 = RaxolApp.get_buffer()

      # Buffers should be different after navigation
      refute buffer1 == buffer2
    end
  end

  describe "crash recovery" do
    test "recovers from invalid input" do
      # Send some invalid inputs
      RaxolApp.send_input(nil)
      RaxolApp.send_input("")
      RaxolApp.send_input(123)

      # Should still be able to get buffer
      buffer = RaxolApp.get_buffer()
      assert is_map(buffer)
    end

    test "maintains state consistency after errors" do
      # Enter command mode
      RaxolApp.send_input(":")

      # Send invalid input
      RaxolApp.send_input(nil)

      # Should still be able to continue
      RaxolApp.send_input("h")
      RaxolApp.send_input("e")
      RaxolApp.send_input("l")
      RaxolApp.send_input("p")
      RaxolApp.send_input("Enter")

      buffer = RaxolApp.get_buffer()
      assert is_map(buffer)
    end
  end

  describe "state transitions" do
    test "transitions from navigation to command mode" do
      # Start in navigation mode (default)
      buffer1 = RaxolApp.get_buffer()

      # Enter command mode
      RaxolApp.send_input(":")
      buffer2 = RaxolApp.get_buffer()

      # Buffers should be different
      refute buffer1 == buffer2
    end

    test "transitions from command to navigation mode" do
      # Enter command mode
      RaxolApp.send_input(":")
      buffer1 = RaxolApp.get_buffer()

      # Exit to navigation mode
      RaxolApp.send_input("Escape")
      buffer2 = RaxolApp.get_buffer()

      # Buffers should be different
      refute buffer1 == buffer2
    end

    test "transitions from navigation to search mode" do
      # Start in navigation mode
      buffer1 = RaxolApp.get_buffer()

      # Enter search mode
      RaxolApp.send_input("/")
      buffer2 = RaxolApp.get_buffer()

      # Buffers should be different
      refute buffer1 == buffer2
    end

    test "command execution returns to navigation mode" do
      # Enter command mode and execute
      RaxolApp.send_input(":")
      RaxolApp.send_input("l")
      RaxolApp.send_input("s")
      RaxolApp.send_input("Enter")

      # Should be back in navigation mode
      buffer = RaxolApp.get_buffer()
      buffer_text = buffer_to_text(buffer)

      # Should not show command prompt
      refute String.starts_with?(String.trim(buffer_text), ":")
    end
  end

  describe "buffer boundaries" do
    test "cursor movement respects top boundary" do
      # Try to move up from top
      # Go to top
      RaxolApp.send_input("g")
      # Try to go up
      RaxolApp.send_input("k")
      RaxolApp.send_input("k")
      RaxolApp.send_input("k")

      # Should not crash
      buffer = RaxolApp.get_buffer()
      assert is_map(buffer)
    end

    test "cursor movement respects bottom boundary" do
      # Try to move down from bottom
      # Go to bottom
      RaxolApp.send_input("G")
      # Try to go down
      RaxolApp.send_input("j")
      RaxolApp.send_input("j")
      RaxolApp.send_input("j")

      # Should not crash
      buffer = RaxolApp.get_buffer()
      assert is_map(buffer)
    end
  end

  describe "command validation" do
    test "handles unknown commands gracefully" do
      RaxolApp.send_input(":")
      RaxolApp.send_input("x")
      RaxolApp.send_input("y")
      RaxolApp.send_input("z")
      RaxolApp.send_input("Enter")

      # Should not crash
      buffer = RaxolApp.get_buffer()
      assert is_map(buffer)
    end

    test "handles empty command" do
      RaxolApp.send_input(":")
      RaxolApp.send_input("Enter")

      # Should not crash
      buffer = RaxolApp.get_buffer()
      assert is_map(buffer)
    end

    test "handles very long command" do
      RaxolApp.send_input(":")

      # Type a very long command
      for _ <- 1..100 do
        RaxolApp.send_input("a")
      end

      RaxolApp.send_input("Enter")

      # Should not crash
      buffer = RaxolApp.get_buffer()
      assert is_map(buffer)
    end
  end

  # Helper functions

  defp buffer_to_text(buffer) do
    buffer.lines
    |> Enum.map(fn line ->
      line.cells
      |> Enum.map(& &1.char)
      |> Enum.join()
    end)
    |> Enum.join("\n")
  end
end
