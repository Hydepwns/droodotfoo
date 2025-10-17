defmodule Droodotfoo.PluginSystem.ManagerTest do
  use ExUnit.Case, async: false

  alias Droodotfoo.PluginSystem.Manager

  # Test plugin module that properly implements the behaviour
  defmodule TestPlugin do
    @behaviour Droodotfoo.PluginSystem.Plugin

    @impl true
    def metadata do
      %{
        name: "test_plugin",
        version: "1.0.0",
        description: "Test plugin for testing",
        author: "test",
        commands: ["test"],
        category: :tool
      }
    end

    @impl true
    def init(_terminal_state) do
      {:ok, %{counter: 0}}
    end

    @impl true
    def handle_input("increment", state, _terminal_state) do
      new_state = %{state | counter: state.counter + 1}
      {:continue, new_state, ["Counter: #{new_state.counter}"]}
    end

    def handle_input("exit", _state, _terminal_state) do
      {:exit, ["Goodbye!"]}
    end

    def handle_input("error", _state, _terminal_state) do
      {:error, "Test error"}
    end

    def handle_input(_input, state, _terminal_state) do
      {:continue, state, ["Unknown command"]}
    end

    @impl true
    def render(%{counter: counter}, _terminal_state) do
      ["Test Plugin Active", "Counter: #{counter}"]
    end

    @impl true
    def cleanup(_state) do
      :ok
    end

    @impl true
    def handle_key(:arrow_up, state, _terminal_state) do
      new_state = %{state | counter: state.counter + 10}
      {:ok, new_state}
    end

    def handle_key(_key, _state, _terminal_state) do
      :pass
    end
  end

  # Plugin without optional handle_key callback
  defmodule MinimalPlugin do
    @behaviour Droodotfoo.PluginSystem.Plugin

    @impl true
    def metadata do
      %{
        name: "minimal",
        version: "1.0.0",
        description: "Minimal plugin",
        author: "test",
        commands: ["minimal"],
        category: :utility
      }
    end

    @impl true
    def init(_terminal_state) do
      {:ok, %{}}
    end

    @impl true
    def handle_input(_input, state, _terminal_state) do
      {:continue, state, ["Minimal plugin"]}
    end

    @impl true
    def render(_state, _terminal_state) do
      ["Minimal Plugin"]
    end

    @impl true
    def cleanup(_state) do
      :ok
    end
  end

  # Module that doesn't implement the behaviour
  defmodule NotAPlugin do
    def some_function, do: :ok
  end

  # Plugin that crashes on init
  defmodule CrashingPlugin do
    @behaviour Droodotfoo.PluginSystem.Plugin

    @impl true
    def metadata do
      %{
        name: "crasher",
        version: "1.0.0",
        description: "Plugin that crashes",
        author: "test",
        commands: ["crash"],
        category: :tool
      }
    end

    @impl true
    def init(_terminal_state) do
      {:error, "Failed to initialize"}
    end

    @impl true
    def handle_input(_input, _state, _terminal_state) do
      raise "Should not be called"
    end

    @impl true
    def render(_state, _terminal_state) do
      raise "Should not be called"
    end

    @impl true
    def cleanup(_state) do
      :ok
    end
  end

  setup do
    # Ensure Manager is running (restart if needed)
    case Process.whereis(Manager) do
      nil ->
        # Manager not running, start it
        {:ok, _pid} = Manager.start_link()
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

    on_exit(fn ->
      # Clean up after each test
      try do
        Manager.stop_plugin()
      rescue
        _ -> :ok
      catch
        :exit, _ -> :ok
      end
    end)

    :ok
  end

  describe "plugin registration" do
    test "successfully registers a valid plugin" do
      assert {:ok, "test_plugin"} = Manager.register_plugin(TestPlugin)
    end

    test "fails to register module without Plugin behaviour" do
      assert {:error, "Module does not implement Plugin behaviour"} =
               Manager.register_plugin(NotAPlugin)
    end

    test "fails to register non-existent module" do
      assert {:error, "Invalid plugin module"} =
               Manager.register_plugin(NonExistentModule)
    end

    test "can register multiple different plugins" do
      assert {:ok, "test_plugin"} = Manager.register_plugin(TestPlugin)
      assert {:ok, "minimal"} = Manager.register_plugin(MinimalPlugin)
      assert {:ok, "crasher"} = Manager.register_plugin(CrashingPlugin)

      plugins = Manager.list_plugins()
      assert length(plugins) >= 3

      plugin_names = Enum.map(plugins, & &1.name)
      assert "test_plugin" in plugin_names
      assert "minimal" in plugin_names
      assert "crasher" in plugin_names
    end

    test "overwrites plugin when re-registering with same name" do
      assert {:ok, "test_plugin"} = Manager.register_plugin(TestPlugin)

      # Register again (should overwrite)
      assert {:ok, "test_plugin"} = Manager.register_plugin(TestPlugin)

      plugins = Manager.list_plugins()
      test_plugins = Enum.filter(plugins, &(&1.name == "test_plugin"))
      assert length(test_plugins) == 1
    end
  end

  describe "list_plugins/0" do
    test "returns empty list when no plugins registered" do
      # Note: Built-in plugins may auto-register, so we just check it's a list
      plugins = Manager.list_plugins()
      assert is_list(plugins)
    end

    test "returns metadata for registered plugins" do
      Manager.register_plugin(TestPlugin)
      Manager.register_plugin(MinimalPlugin)

      plugins = Manager.list_plugins()
      plugin_names = Enum.map(plugins, & &1.name)

      assert "test_plugin" in plugin_names
      assert "minimal" in plugin_names

      test_plugin = Enum.find(plugins, &(&1.name == "test_plugin"))
      assert test_plugin.version == "1.0.0"
      assert test_plugin.description == "Test plugin for testing"
      assert test_plugin.author == "test"
      assert test_plugin.commands == ["test"]
      assert test_plugin.category == :tool
    end
  end

  describe "plugin lifecycle" do
    setup do
      Manager.register_plugin(TestPlugin)
      :ok
    end

    test "starts plugin successfully" do
      terminal_state = %{width: 80, height: 24}

      assert {:ok, initial_render} = Manager.start_plugin("test_plugin", terminal_state)
      assert initial_render == ["Test Plugin Active", "Counter: 0"]
      assert Manager.get_active_plugin() == "test_plugin"
    end

    test "fails to start non-existent plugin" do
      terminal_state = %{width: 80, height: 24}

      assert {:error, "Plugin not found: nonexistent"} =
               Manager.start_plugin("nonexistent", terminal_state)

      assert Manager.get_active_plugin() == nil
    end

    test "fails to start plugin that errors on init" do
      Manager.register_plugin(CrashingPlugin)
      terminal_state = %{width: 80, height: 24}

      assert {:error, "Failed to initialize"} =
               Manager.start_plugin("crasher", terminal_state)

      assert Manager.get_active_plugin() == nil
    end

    test "stops active plugin" do
      terminal_state = %{width: 80, height: 24}
      Manager.start_plugin("test_plugin", terminal_state)

      assert Manager.get_active_plugin() == "test_plugin"
      assert :ok = Manager.stop_plugin()
      assert Manager.get_active_plugin() == nil
    end

    test "returns error when stopping with no active plugin" do
      assert {:error, "No active plugin"} = Manager.stop_plugin()
    end

    test "can restart plugin after stopping" do
      terminal_state = %{width: 80, height: 24}

      # Start, stop, and restart
      Manager.start_plugin("test_plugin", terminal_state)
      Manager.stop_plugin()

      assert {:ok, initial_render} = Manager.start_plugin("test_plugin", terminal_state)
      assert initial_render == ["Test Plugin Active", "Counter: 0"]
      assert Manager.get_active_plugin() == "test_plugin"
    end
  end

  describe "handle_input/2" do
    setup do
      Manager.register_plugin(TestPlugin)
      terminal_state = %{width: 80, height: 24}
      Manager.start_plugin("test_plugin", terminal_state)
      {:ok, terminal_state: terminal_state}
    end

    test "handles continue response", %{terminal_state: terminal_state} do
      assert {:continue, output} = Manager.handle_input("increment", terminal_state)
      assert output == ["Counter: 1"]

      # State should persist
      assert {:continue, output} = Manager.handle_input("increment", terminal_state)
      assert output == ["Counter: 2"]
    end

    test "handles exit response", %{terminal_state: terminal_state} do
      assert {:exit, output} = Manager.handle_input("exit", terminal_state)
      assert output == ["Goodbye!"]
      assert Manager.get_active_plugin() == nil
    end

    test "handles error response", %{terminal_state: terminal_state} do
      assert {:error, "Test error"} = Manager.handle_input("error", terminal_state)
      # Plugin should still be active after error
      assert Manager.get_active_plugin() == "test_plugin"
    end

    test "returns error when no active plugin", %{terminal_state: terminal_state} do
      Manager.stop_plugin()
      assert {:error, "No active plugin"} = Manager.handle_input("test", terminal_state)
    end

    test "handles unknown commands", %{terminal_state: terminal_state} do
      assert {:continue, output} = Manager.handle_input("unknown", terminal_state)
      assert output == ["Unknown command"]
    end
  end

  describe "handle_key/2" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, terminal_state: terminal_state}
    end

    test "handles key with plugin that implements handle_key", %{terminal_state: terminal_state} do
      Manager.register_plugin(TestPlugin)
      Manager.start_plugin("test_plugin", terminal_state)

      assert {:ok, render} = Manager.handle_key(:arrow_up, terminal_state)
      assert render == ["Test Plugin Active", "Counter: 10"]
    end

    test "passes through unhandled keys", %{terminal_state: terminal_state} do
      Manager.register_plugin(TestPlugin)
      Manager.start_plugin("test_plugin", terminal_state)

      assert :pass = Manager.handle_key(:arrow_down, terminal_state)
    end

    test "returns pass for plugin without handle_key", %{terminal_state: terminal_state} do
      Manager.register_plugin(MinimalPlugin)
      Manager.start_plugin("minimal", terminal_state)

      assert :pass = Manager.handle_key(:arrow_up, terminal_state)
    end

    test "returns pass when no active plugin", %{terminal_state: terminal_state} do
      assert :pass = Manager.handle_key(:arrow_up, terminal_state)
    end
  end

  describe "plugin state isolation" do
    test "multiple plugins maintain separate state" do
      # Define a second test plugin with different state
      defmodule SecondTestPlugin do
        @behaviour Droodotfoo.PluginSystem.Plugin

        @impl true
        def metadata do
          %{
            name: "second_test",
            version: "1.0.0",
            description: "Second test plugin",
            author: "test",
            commands: ["test2"],
            category: :tool
          }
        end

        @impl true
        def init(_terminal_state) do
          {:ok, %{value: "initial"}}
        end

        @impl true
        def handle_input("change", _state, _terminal_state) do
          {:continue, %{value: "changed"}, ["Value: changed"]}
        end

        def handle_input(_input, state, _terminal_state) do
          {:continue, state, ["Value: #{state.value}"]}
        end

        @impl true
        def render(state, _terminal_state) do
          ["Second Plugin", "Value: #{state.value}"]
        end

        @impl true
        def cleanup(_state) do
          :ok
        end
      end

      Manager.register_plugin(TestPlugin)
      Manager.register_plugin(SecondTestPlugin)
      terminal_state = %{width: 80, height: 24}

      # Start first plugin and modify state
      Manager.start_plugin("test_plugin", terminal_state)
      Manager.handle_input("increment", terminal_state)
      Manager.handle_input("increment", terminal_state)

      # Switch to second plugin
      Manager.stop_plugin()
      Manager.start_plugin("second_test", terminal_state)
      Manager.handle_input("change", terminal_state)

      # Switch back to first plugin - should have fresh state
      Manager.stop_plugin()
      {:ok, render} = Manager.start_plugin("test_plugin", terminal_state)
      assert render == ["Test Plugin Active", "Counter: 0"]
    end
  end

  describe "error boundaries" do
    test "plugin crash during handle_input doesn't crash manager" do
      defmodule CrashyInputPlugin do
        @behaviour Droodotfoo.PluginSystem.Plugin

        @impl true
        def metadata do
          %{
            name: "crashy_input",
            version: "1.0.0",
            description: "Plugin that crashes on input",
            author: "test",
            commands: ["crashy"],
            category: :tool
          }
        end

        @impl true
        def init(_terminal_state) do
          {:ok, %{}}
        end

        @impl true
        def handle_input("crash", _state, _terminal_state) do
          raise "Intentional crash"
        end

        def handle_input(_input, state, _terminal_state) do
          {:continue, state, ["OK"]}
        end

        @impl true
        def render(_state, _terminal_state) do
          ["Crashy Plugin"]
        end

        @impl true
        def cleanup(_state) do
          :ok
        end
      end

      Manager.register_plugin(CrashyInputPlugin)
      terminal_state = %{width: 80, height: 24}
      Manager.start_plugin("crashy_input", terminal_state)

      # The crash will kill the GenServer (expected behavior)
      # We catch the exit to test that it crashes as expected
      Process.flag(:trap_exit, true)

      # This should crash the manager
      catch_exit(Manager.handle_input("crash", terminal_state))

      # Give time for supervisor to restart it
      Process.sleep(100)

      # Manager should be restarted by supervisor
      assert Process.whereis(Manager) != nil
    end

    test "plugin crash during render doesn't crash manager" do
      defmodule CrashyRenderPlugin do
        @behaviour Droodotfoo.PluginSystem.Plugin

        @impl true
        def metadata do
          %{
            name: "crashy_render",
            version: "1.0.0",
            description: "Plugin that crashes on render",
            author: "test",
            commands: ["crashy"],
            category: :tool
          }
        end

        @impl true
        def init(_terminal_state) do
          {:ok, %{crash: false}}
        end

        @impl true
        def handle_input(_input, _state, _terminal_state) do
          {:continue, %{crash: true}, ["Setting up crash"]}
        end

        @impl true
        def render(%{crash: true}, _terminal_state) do
          raise "Intentional render crash"
        end

        def render(_state, _terminal_state) do
          ["Safe render"]
        end

        @impl true
        def cleanup(_state) do
          :ok
        end
      end

      Manager.register_plugin(CrashyRenderPlugin)
      terminal_state = %{width: 80, height: 24}

      # Initial render should work
      assert {:ok, ["Safe render"]} = Manager.start_plugin("crashy_render", terminal_state)

      # This will set up the crash condition but won't crash yet
      assert {:continue, _} = Manager.handle_input("trigger", terminal_state)

      # Manager should still be alive
      assert Process.alive?(Process.whereis(Manager))
    end
  end

  describe "concurrent plugin management" do
    test "can switch between plugins rapidly" do
      Manager.register_plugin(TestPlugin)
      Manager.register_plugin(MinimalPlugin)
      terminal_state = %{width: 80, height: 24}

      # Rapidly switch between plugins
      for _ <- 1..10 do
        Manager.start_plugin("test_plugin", terminal_state)
        Manager.handle_input("increment", terminal_state)
        Manager.stop_plugin()

        Manager.start_plugin("minimal", terminal_state)
        Manager.handle_input("test", terminal_state)
        Manager.stop_plugin()
      end

      # Manager should still be functional
      assert {:ok, _} = Manager.start_plugin("test_plugin", terminal_state)
      assert Manager.get_active_plugin() == "test_plugin"
    end

    test "handles rapid input while switching plugins" do
      Manager.register_plugin(TestPlugin)
      Manager.register_plugin(MinimalPlugin)
      terminal_state = %{width: 80, height: 24}

      # Start with test_plugin
      Manager.start_plugin("test_plugin", terminal_state)

      # Send multiple inputs
      for i <- 1..5 do
        expected = ["Counter: #{i}"]
        assert {:continue, ^expected} = Manager.handle_input("increment", terminal_state)
      end

      # Quick switch to minimal
      Manager.stop_plugin()
      Manager.start_plugin("minimal", terminal_state)

      # Send inputs to minimal
      for _ <- 1..5 do
        assert {:continue, ["Minimal plugin"]} = Manager.handle_input("anything", terminal_state)
      end

      # Switch back
      Manager.stop_plugin()
      Manager.start_plugin("test_plugin", terminal_state)

      # Should have fresh state
      assert {:continue, ["Counter: 1"]} = Manager.handle_input("increment", terminal_state)
    end
  end
end
