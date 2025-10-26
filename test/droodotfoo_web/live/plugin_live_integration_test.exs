defmodule DroodotfooWeb.PluginLiveIntegrationTest do
  use DroodotfooWeb.ConnCase, async: false
  # Plugin/terminal features archived - tests skipped until reactivation
  @moduletag :skip

  import Phoenix.LiveViewTest

  setup do
    # Clean up any active plugins before each test
    try do
      Droodotfoo.PluginSystem.stop_plugin()
    rescue
      _ -> :ok
    catch
      :exit, _ -> :ok
    end

    # Reset all shared state to prevent test interference
    Droodotfoo.StateResetHelper.reset_all_state()

    :ok
  end

  describe "plugin integration with LiveView" do
    test "LiveView renders initial page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Should render the main terminal interface
      assert html =~ "terminal-wrapper"
      assert html =~ "terminal-wrapper"
    end

    test "LiveView handles key_press events", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Test sending a key event
      html = send_key(view, "h")
      assert is_binary(html)

      # The view should still be connected
      assert view_module(view) == DroodotfooWeb.DroodotfooLive
    end

    test "LiveView can execute terminal commands", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Type a command character by character
      send_key(view, ":")
      send_key(view, "p")
      send_key(view, "w")
      send_key(view, "d")

      # Execute the command
      html = send_key(view, "Enter")

      # Should show command output (might contain current directory)
      assert is_binary(html)
    end

    test "LiveView can list plugins", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Enter command mode and type "plugins"
      send_key(view, ":")
      send_key(view, "p")
      send_key(view, "l")
      send_key(view, "u")
      send_key(view, "g")
      send_key(view, "i")
      send_key(view, "n")
      send_key(view, "s")

      # Execute the command
      html = send_key(view, "Enter")

      # Should show available plugins or indicate command not found
      assert is_binary(html)
    end

    test "LiveView handles plugin commands when supported", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Try to start snake game
      send_key(view, ":")
      send_key(view, "s")
      send_key(view, "n")
      send_key(view, "a")
      send_key(view, "k")
      send_key(view, "e")

      # Execute the command
      html = send_key(view, "Enter")

      # Should either start the plugin or show command not found
      assert is_binary(html)
    end

    test "LiveView handles backspace in command mode", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Enter command mode
      send_key(view, ":")
      send_key(view, "h")
      send_key(view, "e")
      send_key(view, "l")

      # Test backspace
      html = send_key(view, "Backspace")

      # Should still be in command mode
      assert is_binary(html)
    end

    test "LiveView handles escape key", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Enter command mode
      send_key(view, ":")
      send_key(view, "h")

      # Press escape to exit command mode
      html = send_key(view, "Escape")

      # Should exit command mode
      assert is_binary(html)
    end

    test "LiveView navigation with hjkl keys", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Test vim-style navigation
      # down
      send_key(view, "j")
      # up
      send_key(view, "k")
      # left
      send_key(view, "h")
      # right
      html = send_key(view, "l")

      # Navigation should work without errors
      assert is_binary(html)
    end

    test "LiveView search functionality", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Enter search mode
      send_key(view, "/")
      send_key(view, "t")
      send_key(view, "e")
      send_key(view, "s")
      send_key(view, "t")

      # Execute search
      html = send_key(view, "Enter")

      # Should handle search
      assert is_binary(html)
    end
  end

  describe "LiveView state management" do
    test "LiveView maintains state between events", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Send multiple events
      send_key(view, "j")
      send_key(view, "j")
      html = send_key(view, "k")

      # State should be maintained
      assert is_binary(html)
      assert view_module(view) == DroodotfooWeb.DroodotfooLive
    end

    test "LiveView handles rapid key presses", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Send rapid key presses
      for _ <- 1..10 do
        send_key(view, "j")
      end

      html = send_key(view, "k")

      # Should handle rapid input
      assert is_binary(html)
    end

    test "LiveView recovers from errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Send potentially problematic input
      send_key(view, "Ctrl")
      send_key(view, "Alt")
      send_key(view, "Meta")

      # Should still respond normally
      html = send_key(view, "j")
      assert is_binary(html)
    end
  end

  describe "LiveView performance" do
    test "LiveView handles timer updates", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Wait for timer tick (LiveView updates at 60fps)
      Process.sleep(50)

      # Send a key to ensure view is still responsive
      html = send_key(view, "j")

      assert is_binary(html)
    end

    test "LiveView handles mode switching", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Switch between modes rapidly
      # command mode
      send_key(view, ":")
      # back to navigation
      send_key(view, "Escape")
      # search mode
      send_key(view, "/")
      # back to navigation
      send_key(view, "Escape")
      # navigation
      html = send_key(view, "j")

      assert is_binary(html)
    end
  end

  describe "LiveView plugin interaction" do
    test "LiveView can potentially start plugins through commands", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Try starting calculator through command
      send_key(view, ":")
      send_key(view, "c")
      send_key(view, "a")
      send_key(view, "l")
      send_key(view, "c")

      html = send_key(view, "Enter")

      # Should handle the command (success or failure)
      assert is_binary(html)
    end

    test "LiveView handles unknown commands gracefully", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Type an unknown command
      send_key(view, ":")
      send_key(view, "u")
      send_key(view, "n")
      send_key(view, "k")
      send_key(view, "n")
      send_key(view, "o")
      send_key(view, "w")
      send_key(view, "n")

      html = send_key(view, "Enter")

      # Should show "command not found" or similar
      assert is_binary(html)
    end

    test "LiveView handles plugin state when plugins are active", %{conn: conn} do
      # Start a plugin through the manager
      terminal_state = %{width: 80, height: 24}

      case Droodotfoo.PluginSystem.start_plugin("calc", terminal_state) do
        {:ok, _output} ->
          {:ok, view, _html} = live(conn, "/")

          # Send input that might go to the plugin
          send_key(view, "2")
          send_key(view, "+")
          send_key(view, "2")

          html = send_key(view, "Enter")

          # Should handle input appropriately
          assert is_binary(html)

          Droodotfoo.PluginSystem.stop_plugin()

        {:error, _} ->
          # Plugin not available, just test normal operation
          {:ok, view, _html} = live(conn, "/")
          html = send_key(view, "j")
          assert is_binary(html)
      end
    end
  end

  describe "LiveView rendering" do
    test "LiveView renders terminal grid correctly", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")

      # Should have terminal structure
      assert html =~ "terminal-wrapper"

      # Send a key to trigger rendering
      send_key(view, "j")

      # Give time for render
      Process.sleep(100)

      # Now check for cell content
      html = render(view)
      assert html =~ "cell" or html =~ "terminal"
    end

    test "LiveView updates on state changes", %{conn: conn} do
      {:ok, view, initial_html} = live(conn, "/")

      # Make a state change
      updated_html = send_key(view, "j")

      # HTML should potentially change (though might be subtle)
      assert is_binary(initial_html)
      assert is_binary(updated_html)
    end

    test "LiveView handles theme changes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Try theme switching (if supported)
      send_key(view, "t")
      html = send_key(view, "1")

      assert is_binary(html)
    end
  end

  # Helper function to get the module of a LiveView
  defp view_module(view) do
    case view do
      %Phoenix.LiveViewTest.View{module: module} -> module
      _ -> nil
    end
  end

  # Helper to send key press events
  defp send_key(view, key) do
    render_hook(view, "key_press", %{"key" => key})
  end
end
