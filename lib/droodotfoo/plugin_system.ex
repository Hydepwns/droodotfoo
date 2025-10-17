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

  alias Droodotfoo.PluginSystem.Plugin

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

  ## Examples

      iex> {:ok, pid} = Droodotfoo.PluginSystem.start_link()
      iex> Process.alive?(pid)
      true

  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Register a new plugin module.

  Validates that the module implements the `Plugin` behaviour before registration.

  ## Parameters

  - `plugin_module`: Module implementing `Droodotfoo.PluginSystem.Plugin` behaviour

  ## Returns

  - `{:ok, plugin_name}` - Plugin successfully registered
  - `{:error, reason}` - Plugin validation failed

  ## Examples

      iex> Droodotfoo.PluginSystem.register_plugin(MyGame)
      {:ok, "my_game"}

  """
  @spec register_plugin(plugin_module()) :: {:ok, plugin_name()} | {:error, String.t()}
  def register_plugin(plugin_module) do
    GenServer.call(__MODULE__, {:register, plugin_module})
  end

  @doc """
  List all registered plugins.

  Returns metadata for all available plugins.

  ## Examples

      iex> plugins = Droodotfoo.PluginSystem.list_plugins()
      iex> is_list(plugins)
      true
      iex> length(plugins) > 0
      true

  """
  @spec list_plugins() :: [plugin_metadata()]
  def list_plugins do
    GenServer.call(__MODULE__, :list_plugins)
  end

  @doc """
  Start a plugin by name.

  Initializes the plugin with the current terminal state and returns initial render output.
  Only one plugin can be active at a time.

  ## Parameters

  - `plugin_name`: Name of registered plugin (e.g., "snake", "tetris")
  - `terminal_state`: Current terminal state to pass to plugin

  ## Returns

  - `{:ok, render_output}` - Plugin started successfully
  - `{:error, reason}` - Plugin not found or initialization failed

  ## Examples

      iex> {:ok, render} = Droodotfoo.PluginSystem.start_plugin("snake", %{})
      iex> is_binary(render) or is_list(render)
      true

  """
  @spec start_plugin(plugin_name(), terminal_state()) ::
          {:ok, render_output()} | {:error, String.t()}
  def start_plugin(plugin_name, terminal_state) do
    GenServer.call(__MODULE__, {:start_plugin, plugin_name, terminal_state})
  end

  @doc """
  Stop the currently active plugin.

  Calls the plugin's `cleanup/1` callback and clears active plugin state.

  ## Returns

  - `:ok` - Plugin stopped successfully
  - `{:error, reason}` - No active plugin

  ## Examples

      iex> Droodotfoo.PluginSystem.start_plugin("snake", %{})
      iex> Droodotfoo.PluginSystem.stop_plugin()
      :ok

  """
  @spec stop_plugin() :: :ok | {:error, String.t()}
  def stop_plugin do
    GenServer.call(__MODULE__, :stop_plugin)
  end

  @doc """
  Send input to the active plugin.

  Routes input to the plugin's `handle_input/3` callback.

  ## Parameters

  - `input`: Input string from user
  - `terminal_state`: Current terminal state

  ## Returns

  - `{:continue, output}` - Plugin processed input and continues running
  - `{:exit, output}` - Plugin requests to exit
  - `{:error, reason}` - No active plugin or input handling failed

  ## Examples

      iex> Droodotfoo.PluginSystem.start_plugin("snake", %{})
      iex> {:continue, output} = Droodotfoo.PluginSystem.handle_input("w", %{})
      iex> is_binary(output) or is_list(output)
      true

  """
  @spec handle_input(String.t(), terminal_state()) ::
          {:continue, render_output()} | {:exit, render_output()} | {:error, String.t()}
  def handle_input(input, terminal_state) do
    GenServer.call(__MODULE__, {:handle_input, input, terminal_state})
  end

  @doc """
  Send key event to the active plugin.

  Routes keyboard events to the plugin's optional `handle_key/3` callback.
  Falls back to `:pass` if the plugin doesn't implement `handle_key/3`.

  ## Parameters

  - `key`: Key name (e.g., "ArrowUp", "Enter")
  - `terminal_state`: Current terminal state

  ## Returns

  - `{:ok, render_output}` - Plugin handled key and returned new render
  - `:pass` - Plugin passed on the key (no handling)

  ## Examples

      iex> Droodotfoo.PluginSystem.start_plugin("tetris", %{})
      iex> result = Droodotfoo.PluginSystem.handle_key("ArrowLeft", %{})
      iex> match?({:ok, _}, result) or result == :pass
      true

  """
  @spec handle_key(String.t(), terminal_state()) :: {:ok, render_output()} | :pass
  def handle_key(key, terminal_state) do
    GenServer.call(__MODULE__, {:handle_key, key, terminal_state})
  end

  @doc """
  Get the name of the currently active plugin.

  ## Returns

  - `plugin_name` - Name of active plugin
  - `nil` - No plugin is active

  ## Examples

      iex> Droodotfoo.PluginSystem.start_plugin("wordle", %{})
      iex> Droodotfoo.PluginSystem.get_active_plugin()
      "wordle"

  """
  @spec get_active_plugin() :: plugin_name() | nil
  def get_active_plugin do
    GenServer.call(__MODULE__, :get_active_plugin)
  end

  @doc """
  Reset the plugin system state.

  Clears active plugin but preserves registered plugins.
  Useful for testing or recovering from error states.

  ## Examples

      iex> Droodotfoo.PluginSystem.reset_state()
      :ok

  """
  @spec reset_state() :: :ok
  def reset_state do
    GenServer.call(__MODULE__, :reset_state)
  end

  ## Server Callbacks

  # Server Callbacks

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      plugins: %{},
      active_plugin: nil,
      plugin_state: nil,
      terminal_state: %{}
    }

    # Auto-register built-in plugins after initialization
    Process.send_after(self(), :register_builtin, 100)

    {:ok, state}
  end

  @impl true
  def handle_call({:register, plugin_module}, _from, state) do
    case validate_plugin(plugin_module) do
      :ok ->
        metadata = plugin_module.metadata()
        name = metadata.name

        new_plugins =
          Map.put(state.plugins, name, %{
            module: plugin_module,
            metadata: metadata
          })

        Logger.info("Registered plugin: #{name}")
        {:reply, {:ok, name}, %{state | plugins: new_plugins}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:list_plugins, _from, state) do
    plugin_list =
      Enum.map(state.plugins, fn {_name, plugin} ->
        plugin.metadata
      end)

    {:reply, plugin_list, state}
  end

  @impl true
  def handle_call({:start_plugin, plugin_name, terminal_state}, _from, state) do
    case Map.get(state.plugins, plugin_name) do
      nil ->
        {:reply, {:error, "Plugin not found: #{plugin_name}"}, state}

      plugin_info ->
        case plugin_info.module.init(terminal_state) do
          {:ok, plugin_state} ->
            Logger.info("Started plugin: #{plugin_name}")

            new_state = %{
              state
              | active_plugin: plugin_info,
                plugin_state: plugin_state,
                terminal_state: terminal_state
            }

            initial_render = plugin_info.module.render(plugin_state, terminal_state)
            {:reply, {:ok, initial_render}, new_state}

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
        plugin_info.module.cleanup(state.plugin_state)
        Logger.info("Stopped plugin: #{plugin_info.metadata.name}")

        new_state = %{state | active_plugin: nil, plugin_state: nil}

        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:handle_input, input, terminal_state}, _from, state) do
    case state.active_plugin do
      nil ->
        {:reply, {:error, "No active plugin"}, state}

      plugin_info ->
        case plugin_info.module.handle_input(input, state.plugin_state, terminal_state) do
          {:continue, new_plugin_state, output} ->
            new_state = %{state | plugin_state: new_plugin_state, terminal_state: terminal_state}
            {:reply, {:continue, output}, new_state}

          {:exit, output} ->
            plugin_info.module.cleanup(state.plugin_state)
            new_state = %{state | active_plugin: nil, plugin_state: nil}
            {:reply, {:exit, output}, new_state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  @impl true
  def handle_call({:handle_key, key, terminal_state}, _from, state) do
    case state.active_plugin do
      nil ->
        {:reply, :pass, state}

      plugin_info ->
        handle_plugin_key(plugin_info, key, state, terminal_state)
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

  # Private Functions

  defp validate_plugin(module) do
    behaviours = module.__info__(:attributes)[:behaviour] || []

    if Plugin in behaviours do
      :ok
    else
      {:error, "Module does not implement Plugin behaviour"}
    end
  rescue
    _ -> {:error, "Invalid plugin module"}
  end

  @impl true
  def handle_info(:register_builtin, state) do
    # Register built-in plugins
    plugins = [
      Droodotfoo.Plugins.SnakeGame,
      Droodotfoo.Plugins.Calculator,
      Droodotfoo.Plugins.MatrixRain,
      Droodotfoo.Plugins.Spotify,
      Droodotfoo.Plugins.Conway,
      Droodotfoo.Plugins.TypingTest,
      Droodotfoo.Plugins.GitHub,
      Droodotfoo.Plugins.Tetris,
      Droodotfoo.Plugins.TwentyFortyEight,
      Droodotfoo.Plugins.Wordle
    ]

    new_state = Enum.reduce(plugins, state, &register_builtin_plugin/2)

    {:noreply, new_state}
  end

  # Additional private helper functions

  defp handle_plugin_key(plugin_info, key, state, terminal_state) do
    if function_exported?(plugin_info.module, :handle_key, 3) do
      process_plugin_key_result(plugin_info, key, state, terminal_state)
    else
      {:reply, :pass, state}
    end
  end

  defp process_plugin_key_result(plugin_info, key, state, terminal_state) do
    case plugin_info.module.handle_key(key, state.plugin_state, terminal_state) do
      {:ok, new_plugin_state} ->
        new_state = %{
          state
          | plugin_state: new_plugin_state,
            terminal_state: terminal_state
        }

        render = plugin_info.module.render(new_plugin_state, terminal_state)
        {:reply, {:ok, render}, new_state}

      :pass ->
        {:reply, :pass, state}
    end
  end

  defp register_builtin_plugin(plugin, acc_state) do
    case Code.ensure_loaded(plugin) do
      {:module, _} ->
        register_validated_plugin(plugin, acc_state)

      _ ->
        acc_state
    end
  end

  defp register_validated_plugin(plugin, acc_state) do
    case validate_plugin(plugin) do
      :ok ->
        metadata = plugin.metadata()
        name = metadata.name

        new_plugins =
          Map.put(acc_state.plugins, name, %{
            module: plugin,
            metadata: metadata
          })

        Logger.info("Registered built-in plugin: #{name}")
        %{acc_state | plugins: new_plugins}

      {:error, reason} ->
        Logger.warning("Failed to register plugin #{inspect(plugin)}: #{reason}")
        acc_state
    end
  end
end
