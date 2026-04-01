defmodule Droodotfoo.PluginSystem.Registry do
  @moduledoc """
  Plugin registration helpers.
  """

  require Logger

  alias Droodotfoo.PluginSystem.Validator

  @doc """
  Register a plugin module, returning updated plugins map.

  ## Returns
  - `{:ok, name, updated_plugins}` - Plugin registered successfully
  - `{:error, reason}` - Validation failed
  """
  @spec register(module(), map()) :: {:ok, String.t(), map()} | {:error, String.t()}
  def register(plugin_module, plugins) do
    case Validator.validate(plugin_module) do
      :ok ->
        metadata = plugin_module.metadata()
        name = metadata.name

        new_plugins =
          Map.put(plugins, name, %{
            module: plugin_module,
            metadata: metadata
          })

        {:ok, name, new_plugins}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Register a built-in plugin, logging the result.

  ## Returns
  Updated plugins map (unchanged if registration fails).
  """
  @spec register_builtin(module(), map()) :: map()
  def register_builtin(plugin, plugins) do
    if Validator.loadable?(plugin) do
      do_register_builtin(plugin, plugins)
    else
      plugins
    end
  end

  defp do_register_builtin(plugin, plugins) do
    case register(plugin, plugins) do
      {:ok, name, new_plugins} ->
        Logger.info("Registered built-in plugin: #{name}")
        new_plugins

      {:error, reason} ->
        Logger.warning("Failed to register plugin #{inspect(plugin)}: #{reason}")
        plugins
    end
  end

  @doc """
  Get plugin metadata list from plugins map.
  """
  @spec list_metadata(map()) :: [map()]
  def list_metadata(plugins) do
    Enum.map(plugins, fn {_name, plugin} -> plugin.metadata end)
  end
end
