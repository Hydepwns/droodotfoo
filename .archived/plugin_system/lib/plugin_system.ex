defmodule Droodotfoo.PluginSystem do
  @moduledoc """
  Terminal plugin system GenServer for loading, executing, and managing plugin lifecycle.

  Responsibilities:
  - Register and validate plugin modules
  - Manage active plugin state and lifecycle
  - Route input to active plugins
  - Handle plugin initialization and cleanup
  - Auto-register built-in plugins at startup

  ## Plugin Lifecycle

  1. **Registration** - Plugin module is validated and registered
  2. **Initialization** - Plugin's `init/1` callback is called
  3. **Active State** - Plugin receives input and renders output
  4. **Cleanup** - Plugin's `cleanup/1` callback is called on exit

  ## Built-in Plugins

  The system auto-registers 10 built-in plugins:
  - Snake, Tetris, 2048, Wordle (games)
  - Conway's Game of Life (simulation)
  - Calculator, Typing Test (utilities)
  - Spotify, GitHub (integrations)
  - Matrix Rain (visual effect)

  ## Examples

      # Register a custom plugin
      Droodotfoo.PluginSystem.register_plugin(MyCustomPlugin)

      # Start a plugin
      {:ok, render} = Droodotfoo.PluginSystem.start_plugin("snake", terminal_state)

      # Send input to active plugin
      {:continue, output} = Droodotfoo.PluginSystem.handle_input("w", terminal_state)

      # Stop active plugin
      :ok = Droodotfoo.PluginSystem.stop_plugin()

  """

  use GenServer
  require Logger

  alias Droodotfoo.PluginSystem.{Config, Executor, Registry}

  defstruct [
    :plugins,
    :active_plugin,
    :plugin_state,
    :terminal_state
  ]

  # Type definitions

  @type plugin_name :: String.t()
  @type plugin_module :: module()
  @type plugin_metadata :: %{
          name: String.t(),
          version: String.t(),
          description: String.t(),
          author: String.t(),
          commands: [String.t()],
          category: atom()
        }
  @type plugin_info :: %{module: plugin_module(), metadata: plugin_metadata()}
  @type plugin_state :: any()
  @type terminal_state :: map()
  @type render_output :: String.t() | [String.t()]

  ## Client API

  @doc """
  Start the PluginSystem GenServer.

  Auto-registers built-in plugins after 100ms delay.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Register a new plugin module.

  Validates that the module implements the `Plugin` behaviour before registration.
  """
  @spec register_plugin(plugin_module()) :: {:ok, plugin_name()} | {:error, String.t()}
  def register_plugin(plugin_module) do
    GenServer.call(__MODULE__, {:register, plugin_module})
  end

  @doc """
  List all registered plugins.
  """
  @spec list_plugins() :: [plugin_metadata()]
  def list_plugins do
    GenServer.call(__MODULE__, :list_plugins)
  end

  @doc """
  Start a plugin by name.

  Initializes the plugin with the current terminal state and returns initial render output.
  """
  @spec start_plugin(plugin_name(), terminal_state()) ::
          {:ok, render_output()} | {:error, String.t()}
  def start_plugin(plugin_name, terminal_state) do
    GenServer.call(__MODULE__, {:start_plugin, plugin_name, terminal_state})
  end

  @doc """
  Stop the currently active plugin.
  """
  @spec stop_plugin() :: :ok | {:error, String.t()}
  def stop_plugin do
    GenServer.call(__MODULE__, :stop_plugin)
  end

  @doc """
  Send input to the active plugin.
  """
  @spec handle_input(String.t(), terminal_state()) ::
          {:continue, render_output()} | {:exit, render_output()} | {:error, String.t()}
  def handle_input(input, terminal_state) do
    GenServer.call(__MODULE__, {:handle_input, input, terminal_state})
  end

  @doc """
  Send key event to the active plugin.
  """
  @spec handle_key(String.t(), terminal_state()) :: {:ok, render_output()} | :pass
  def handle_key(key, terminal_state) do
    GenServer.call(__MODULE__, {:handle_key, key, terminal_state})
  end

  @doc """
  Get the name of the currently active plugin.
  """
  @spec get_active_plugin() :: plugin_name() | nil
  def get_active_plugin do
    GenServer.call(__MODULE__, :get_active_plugin)
  end

  @doc """
  Reset the plugin system state.
  """
  @spec reset_state() :: :ok
  def reset_state do
    GenServer.call(__MODULE__, :reset_state)
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      plugins: %{},
      active_plugin: nil,
      plugin_state: nil,
      terminal_state: %{}
    }

    Process.send_after(self(), :register_builtin, 100)
    {:ok, state}
  end

  @impl true
  def handle_call({:register, plugin_module}, _from, state) do
    case Registry.register(plugin_module, state.plugins) do
      {:ok, name, new_plugins} ->
        Logger.info("Registered plugin: #{name}")
        {:reply, {:ok, name}, %{state | plugins: new_plugins}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:list_plugins, _from, state) do
    {:reply, Registry.list_metadata(state.plugins), state}
  end

  @impl true
  def handle_call({:start_plugin, plugin_name, terminal_state}, _from, state) do
    case Map.get(state.plugins, plugin_name) do
      nil ->
        {:reply, {:error, "Plugin not found: #{plugin_name}"}, state}

      plugin_info ->
        case Executor.init_plugin(plugin_info.module, terminal_state) do
          {:ok, plugin_state, render} ->
            Logger.info("Started plugin: #{plugin_name}")

            new_state = %{
              state
              | active_plugin: plugin_info,
                plugin_state: plugin_state,
                terminal_state: terminal_state
            }

            {:reply, {:ok, render}, new_state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  @impl true
  def handle_call(:stop_plugin, _from, state) do
    case state.active_plugin do
      nil ->
        {:reply, {:error, "No active plugin"}, state}

      plugin_info ->
        Executor.cleanup(plugin_info.module, state.plugin_state)
        Logger.info("Stopped plugin: #{plugin_info.metadata.name}")
        {:reply, :ok, %{state | active_plugin: nil, plugin_state: nil}}
    end
  end

  @impl true
  def handle_call({:handle_input, input, terminal_state}, _from, state) do
    case state.active_plugin do
      nil ->
        {:reply, {:error, "No active plugin"}, state}

      plugin_info ->
        handle_input_result(plugin_info, input, terminal_state, state)
    end
  end

  @impl true
  def handle_call({:handle_key, key, terminal_state}, _from, state) do
    case state.active_plugin do
      nil ->
        {:reply, :pass, state}

      plugin_info ->
        handle_key_result(plugin_info, key, terminal_state, state)
    end
  end

  @impl true
  def handle_call(:get_active_plugin, _from, state) do
    plugin_name =
      case state.active_plugin do
        nil -> nil
        plugin_info -> plugin_info.metadata.name
      end

    {:reply, plugin_name, state}
  end

  @impl true
  def handle_call(:reset_state, _from, state) do
    new_state = %__MODULE__{
      plugins: state.plugins,
      active_plugin: nil,
      plugin_state: nil,
      terminal_state: %{}
    }

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info(:register_builtin, state) do
    new_plugins =
      Config.builtin_plugins()
      |> Enum.reduce(state.plugins, &Registry.register_builtin/2)

    {:noreply, %{state | plugins: new_plugins}}
  end

  # Private helpers

  defp handle_input_result(plugin_info, input, terminal_state, state) do
    case Executor.handle_input(plugin_info.module, input, state.plugin_state, terminal_state) do
      {:continue, new_plugin_state, output} ->
        new_state = %{state | plugin_state: new_plugin_state, terminal_state: terminal_state}
        {:reply, {:continue, output}, new_state}

      {:exit, output} ->
        Executor.cleanup(plugin_info.module, state.plugin_state)
        {:reply, {:exit, output}, %{state | active_plugin: nil, plugin_state: nil}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp handle_key_result(plugin_info, key, terminal_state, state) do
    case Executor.handle_key(plugin_info.module, key, state.plugin_state, terminal_state) do
      {:handled, new_plugin_state, render} ->
        new_state = %{state | plugin_state: new_plugin_state, terminal_state: terminal_state}
        {:reply, {:ok, render}, new_state}

      :pass ->
        {:reply, :pass, state}
    end
  end
end
