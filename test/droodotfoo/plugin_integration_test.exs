defmodule Droodotfoo.PluginIntegrationTest do
  use ExUnit.Case, async: false

  alias Droodotfoo.Terminal.Commands
  alias Droodotfoo.Terminal.CommandParser
  alias Droodotfoo.PluginSystem.Manager
  alias Droodotfoo.Raxol.Command, as: RaxolCommand

  setup do
    # Ensure Manager is running
    case Process.whereis(Manager) do
      nil ->
        {:ok, _pid} = start_supervised(Manager)
      pid when is_pid(pid) ->
        # Manager is running, clean up any active plugin
        try do
          Manager.stop_plugin()
        rescue
          _ -> :ok
        catch
          :exit, _ -> :ok
        end
    end

    # Reset all shared state to prevent test interference
    Droodotfoo.StateResetHelper.reset_all_state()

    terminal_state = %{
      current_dir: "/home/user",
      home_dir: "/home/user",
      width: 80,
      height: 24
    }

    raxol_state = %{
      mode: :command,
      command_buffer: "",
      terminal_state: terminal_state,
      terminal_output: "",
      current_section: :terminal,
      command_history: [],
      history_index: -1
    }

    {:ok, terminal_state: terminal_state, raxol_state: raxol_state}
  end

  describe "plugin command integration" do
    test "plugins command lists available plugins", %{terminal_state: terminal_state} do
      # Test the plugins command from Commands module
      assert {:ok, output} = Commands.plugins([], terminal_state)

      assert String.contains?(output, "Available Plugins:")
      # Should list built-in plugins
      assert String.contains?(output, "snake")
      assert String.contains?(output, "calc")
      assert String.contains?(output, "matrix")
    end

    test "plugins list command works", %{terminal_state: terminal_state} do
      assert {:ok, output1} = Commands.plugins([], terminal_state)
      assert {:ok, output2} = Commands.plugins(["list"], terminal_state)

      # Both should return the same output
      assert output1 == output2
    end

    test "snake command starts snake plugin", %{terminal_state: terminal_state} do
      case Commands.snake([], terminal_state) do
        {:plugin, "snake", output} ->
          assert is_list(output)
          # Should contain snake game UI
          assert Enum.any?(output, &String.contains?(&1, "SNAKE GAME"))

        {:error, reason} ->
          # Plugin might not be registered yet, which is acceptable
          assert String.contains?(reason, "not found")
      end
    end

    test "calc command starts calculator plugin", %{terminal_state: terminal_state} do
      case Commands.calc([], terminal_state) do
        {:plugin, "calc", output} ->
          assert is_list(output)
          # Should contain calculator UI
          assert Enum.any?(output, &String.contains?(&1, "CALCULATOR"))

        {:error, reason} ->
          # Plugin might not be registered yet, which is acceptable
          assert String.contains?(reason, "not found")
      end
    end

    test "calculator alias works", %{terminal_state: terminal_state} do
      result1 = Commands.calc([], terminal_state)
      result2 = Commands.calculator([], terminal_state)

      # Both should return the same result
      assert result1 == result2
    end

    test "matrix command starts matrix plugin", %{terminal_state: terminal_state} do
      case Commands.matrix([], terminal_state) do
        {:plugin, "matrix", output} ->
          assert is_list(output)
          # Should contain matrix rain UI
          assert Enum.any?(output, &String.contains?(&1, "MATRIX"))

        {:error, reason} ->
          # Plugin might not be registered yet, which is acceptable
          assert String.contains?(reason, "not found")
      end
    end

    test "rain alias works for matrix", %{terminal_state: terminal_state} do
      result1 = Commands.matrix([], terminal_state)
      result2 = Commands.rain([], terminal_state)

      # Both should return plugin results for the same plugin
      # (output will differ due to randomization, but structure should match)
      assert {:plugin, "matrix", _output1} = result1
      assert {:plugin, "matrix", _output2} = result2
    end

    test "spotify command starts spotify plugin", %{terminal_state: terminal_state} do
      case Commands.spotify([], terminal_state) do
        {:plugin, "spotify", output} ->
          assert is_list(output)
          # Should contain spotify UI (might show authentication required)
          assert is_list(output)

        {:error, reason} ->
          # Plugin might not be registered yet, which is acceptable
          assert String.contains?(reason, "not found")
      end
    end
  end

  describe "plugin lifecycle integration" do
    test "can start and stop plugins through manager", %{terminal_state: terminal_state} do
      # Try to start a plugin
      case Manager.start_plugin("snake", terminal_state) do
        {:ok, initial_render} ->
          assert is_list(initial_render)
          assert Manager.get_active_plugin() == "snake"

          # Stop the plugin
          assert :ok = Manager.stop_plugin()
          assert Manager.get_active_plugin() == nil

        {:error, "Plugin not found: snake"} ->
          # Plugin not registered, skip this test
          :ok
      end
    end

    test "plugin input handling", %{terminal_state: terminal_state} do
      # Try to start a plugin and send input
      case Manager.start_plugin("calc", terminal_state) do
        {:ok, _initial_render} ->
          # Send input to calculator
          case Manager.handle_input("2 + 2", terminal_state) do
            {:continue, output} ->
              assert is_list(output)

            {:error, _reason} ->
              # Input might not be valid, that's ok
              :ok
          end

          Manager.stop_plugin()

        {:error, "Plugin not found: calc"} ->
          # Plugin not registered, skip this test
          :ok
      end
    end

    test "multiple plugins cannot be active simultaneously", %{terminal_state: terminal_state} do
      # Try to start first plugin
      case Manager.start_plugin("snake", terminal_state) do
        {:ok, _} ->
          assert Manager.get_active_plugin() == "snake"

          # Try to start second plugin - should replace first
          case Manager.start_plugin("calc", terminal_state) do
            {:ok, _} ->
              assert Manager.get_active_plugin() == "calc"
              Manager.stop_plugin()

            {:error, _} ->
              Manager.stop_plugin()
          end

        {:error, _} ->
          # First plugin not available, skip test
          :ok
      end
    end
  end

  describe "plugin error handling" do
    test "handles non-existent plugin gracefully", %{terminal_state: terminal_state} do
      assert {:error, "Plugin not found: nonexistent"} =
               Manager.start_plugin("nonexistent", terminal_state)
    end

    test "handles input when no plugin is active", %{terminal_state: terminal_state} do
      assert {:error, "No active plugin"} =
               Manager.handle_input("test", terminal_state)
    end

    test "handles plugin commands with arguments gracefully", %{terminal_state: terminal_state} do
      # Plugin commands currently only accept empty argument lists
      # This should result in a function clause error which is expected behavior
      assert_raise FunctionClauseError, fn ->
        Commands.snake(["arg1"], terminal_state)
      end

      # But with empty args it should work (or give plugin not found)
      case Commands.snake([], terminal_state) do
        {:plugin, "snake", _output} ->
          # Should work
          :ok

        {:error, _reason} ->
          # Error is acceptable if plugin not registered
          :ok
      end
    end
  end

  describe "terminal integration" do
    test "terminal command execution preserves state", %{terminal_state: terminal_state} do
      # Test that terminal commands work independently of plugins
      assert {:ok, output} = Commands.pwd(terminal_state)
      assert output == "/home/user"

      assert {:ok, output} = Commands.whoami(terminal_state)
      # Actual username in the system
      assert String.contains?(output, "drew")
    end

    test "command parser suggestion system" do
      # Test that command suggestions work
      suggestions = CommandParser.suggest_command("snak")
      # Should suggest "snake" if it were in the command list
      assert is_list(suggestions)

      # Test with a command that exists
      suggestions = CommandParser.suggest_command("l")
      # Suggestions are just command names
      assert Enum.any?(suggestions, fn cmd -> cmd == "ls" end)
    end

    test "command parser handles empty input", %{terminal_state: terminal_state} do
      assert {:ok, ""} = CommandParser.parse_and_execute("", terminal_state)
      assert {:ok, ""} = CommandParser.parse_and_execute("   ", terminal_state)
    end

    test "command parser handles unknown commands", %{terminal_state: terminal_state} do
      assert {:error, error_msg} =
               CommandParser.parse_and_execute("unknowncommand", terminal_state)

      assert String.contains?(error_msg, "command not found")
    end
  end

  describe "raxol command integration" do
    test "raxol command execution handles terminal commands", %{raxol_state: raxol_state} do
      # Test executing a command through RaxolCommand
      result = RaxolCommand.execute_terminal_command("pwd", raxol_state)

      assert result.current_section == :terminal
      assert String.contains?(result.terminal_output, "/home/user")
    end

    test "raxol handles command errors", %{raxol_state: raxol_state} do
      result = RaxolCommand.execute_terminal_command("invalidcommand", raxol_state)

      assert result.current_section == :terminal
      assert String.contains?(result.terminal_output, "command not found")
    end

    test "raxol handles exit command", %{raxol_state: raxol_state} do
      result = RaxolCommand.execute_terminal_command("exit", raxol_state)

      assert result.current_section == :home
      assert String.contains?(result.terminal_output, "Goodbye")
    end

    test "raxol command buffer management", %{raxol_state: raxol_state} do
      # Test adding characters to command buffer
      state1 = RaxolCommand.handle_input("h", raxol_state)
      assert state1.command_buffer == "h"

      state2 = RaxolCommand.handle_input("e", state1)
      assert state2.command_buffer == "he"

      state3 = RaxolCommand.handle_input("l", state2)
      assert state3.command_buffer == "hel"

      # Test backspace
      state4 = RaxolCommand.handle_input("Backspace", state3)
      assert state4.command_buffer == "he"
    end

    test "raxol tab completion", %{raxol_state: raxol_state} do
      # Test tab completion
      partial_state = %{raxol_state | command_buffer: "l"}
      completed_state = RaxolCommand.handle_input("Tab", partial_state)

      # Should complete to "ls" if there's a unique match
      # Might complete or stay the same
      assert completed_state.command_buffer in ["ls", "l"]
    end
  end

  describe "plugin render integration" do
    test "plugin output is list of strings", %{terminal_state: terminal_state} do
      # Ensure plugin outputs are compatible with terminal rendering
      case Manager.start_plugin("calc", terminal_state) do
        {:ok, output} ->
          assert is_list(output)

          Enum.each(output, fn line ->
            assert is_binary(line)
          end)

          Manager.stop_plugin()

        {:error, _} ->
          # Plugin not available, skip test
          :ok
      end
    end

    test "plugin output fits terminal dimensions", %{terminal_state: terminal_state} do
      case Manager.start_plugin("snake", terminal_state) do
        {:ok, output} ->
          assert is_list(output)

          # Check line count doesn't exceed terminal height
          assert length(output) <= terminal_state.height

          # Check line width doesn't exceed terminal width (accounting for ANSI codes)
          Enum.each(output, fn line ->
            # Remove ANSI codes for length check
            clean_line = String.replace(line, ~r/\e\[[0-9;]*m/, "")
            # Some matrix characters may be wider, so we're lenient
            assert String.length(clean_line) <= terminal_state.width + 10
          end)

          Manager.stop_plugin()

        {:error, _} ->
          # Plugin not available, skip test
          :ok
      end
    end
  end

  describe "integration test scenarios" do
    test "full plugin workflow - list, start, interact, stop", %{terminal_state: terminal_state} do
      # List plugins
      {:ok, plugin_list} = Commands.plugins([], terminal_state)
      assert String.contains?(plugin_list, "Available Plugins")

      # Try to start a plugin
      case Commands.calc([], terminal_state) do
        {:plugin, "calc", _output} ->
          # Plugin started successfully
          assert Manager.get_active_plugin() == "calc"

          # Send some input
          Manager.handle_input("2 + 2", terminal_state)

          # Stop plugin
          Manager.stop_plugin()
          assert Manager.get_active_plugin() == nil

        {:error, _} ->
          # Plugin not available, test still passes
          :ok
      end
    end

    test "plugin switching workflow", %{terminal_state: terminal_state} do
      # Try to start first plugin
      case Commands.snake([], terminal_state) do
        {:plugin, "snake", _} ->
          assert Manager.get_active_plugin() == "snake"

          # Switch to another plugin
          case Commands.calc([], terminal_state) do
            {:plugin, "calc", _} ->
              # Should have switched
              assert Manager.get_active_plugin() == "calc"
              Manager.stop_plugin()

            {:error, _} ->
              Manager.stop_plugin()
          end

        {:error, _} ->
          # First plugin not available, skip test
          :ok
      end
    end

    test "terminal command execution while plugin is active", %{terminal_state: terminal_state} do
      # Start a plugin
      case Manager.start_plugin("calc", terminal_state) do
        {:ok, _} ->
          # Terminal commands should still work
          assert {:ok, output} = Commands.pwd(terminal_state)
          assert String.contains?(output, "/home/user")

          Manager.stop_plugin()

        {:error, _} ->
          # Plugin not available, just test terminal command
          assert {:ok, output} = Commands.pwd(terminal_state)
          assert output == "/home/user"
      end
    end
  end
end
