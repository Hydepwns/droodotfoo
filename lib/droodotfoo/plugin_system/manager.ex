defmodule Droodotfoo.PluginSystem.Manager do
  @moduledoc """
  Manages terminal plugins - loading, executing, and managing their lifecycle
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

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def register_plugin(plugin_module) do
    GenServer.call(__MODULE__, {:register, plugin_module})
  end

  def list_plugins do
    GenServer.call(__MODULE__, :list_plugins)
  end

  def start_plugin(plugin_name, terminal_state) do
    GenServer.call(__MODULE__, {:start_plugin, plugin_name, terminal_state})
  end

  def stop_plugin do
    GenServer.call(__MODULE__, :stop_plugin)
  end

  def handle_input(input, terminal_state) do
    GenServer.call(__MODULE__, {:handle_input, input, terminal_state})
  end

  def handle_key(key, terminal_state) do
    GenServer.call(__MODULE__, {:handle_key, key, terminal_state})
  end

  def get_active_plugin do
    GenServer.call(__MODULE__, :get_active_plugin)
  end

  def reset_state do
    GenServer.call(__MODULE__, :reset_state)
  end

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
        if function_exported?(plugin_info.module, :handle_key, 3) do
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
        else
          {:reply, :pass, state}
        end
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
      Droodotfoo.Plugins.GitHub
    ]

    new_state =
      Enum.reduce(plugins, state, fn plugin, acc_state ->
        case Code.ensure_loaded(plugin) do
          {:module, _} ->
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

          _ ->
            acc_state
        end
      end)

    {:noreply, new_state}
  end
end
