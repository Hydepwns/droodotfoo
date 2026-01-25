defmodule Droodotfoo.PluginSystem.Executor do
  @moduledoc """
  Plugin execution helpers for handling input and key events.
  """

  @doc """
  Handle a key event for a plugin that implements handle_key/3.

  ## Returns
  - `{:handled, new_plugin_state, render}` - Key was handled
  - `:pass` - Plugin passed on the key
  """
  @spec handle_key(module(), String.t(), any(), map()) ::
          {:handled, any(), any()} | :pass
  def handle_key(plugin_module, key, plugin_state, terminal_state) do
    if function_exported?(plugin_module, :handle_key, 3) do
      process_key_result(plugin_module, key, plugin_state, terminal_state)
    else
      :pass
    end
  end

  defp process_key_result(plugin_module, key, plugin_state, terminal_state) do
    case plugin_module.handle_key(key, plugin_state, terminal_state) do
      {:ok, new_plugin_state} ->
        render = plugin_module.render(new_plugin_state, terminal_state)
        {:handled, new_plugin_state, render}

      :pass ->
        :pass
    end
  end

  @doc """
  Handle input for a plugin.

  ## Returns
  - `{:continue, new_state, output}` - Continue running
  - `{:exit, output}` - Plugin wants to exit
  - `{:error, reason}` - Error occurred
  """
  @spec handle_input(module(), String.t(), any(), map()) ::
          {:continue, any(), any()} | {:exit, any()} | {:error, any()}
  def handle_input(plugin_module, input, plugin_state, terminal_state) do
    plugin_module.handle_input(input, plugin_state, terminal_state)
  end

  @doc """
  Initialize a plugin and return initial state and render.
  """
  @spec init_plugin(module(), map()) :: {:ok, any(), any()} | {:error, any()}
  def init_plugin(plugin_module, terminal_state) do
    case plugin_module.init(terminal_state) do
      {:ok, plugin_state} ->
        render = plugin_module.render(plugin_state, terminal_state)
        {:ok, plugin_state, render}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Clean up a plugin state.
  """
  @spec cleanup(module(), any()) :: :ok
  def cleanup(plugin_module, plugin_state) do
    plugin_module.cleanup(plugin_state)
    :ok
  end
end
