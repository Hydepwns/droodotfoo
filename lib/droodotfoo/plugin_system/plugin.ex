defmodule Droodotfoo.PluginSystem.Plugin do
  @moduledoc """
  Behaviour definition for terminal plugins.
  Plugins can extend the terminal with new commands, games, and tools.
  """

  @type plugin_metadata :: %{
          name: String.t(),
          version: String.t(),
          description: String.t(),
          author: String.t(),
          commands: list(String.t()),
          category: :game | :tool | :utility | :fun
        }

  @type plugin_state :: any()
  @type terminal_state :: map()
  @type render_output :: list(String.t())

  @doc """
  Returns metadata about the plugin
  """
  @callback metadata() :: plugin_metadata()

  @doc """
  Initializes the plugin state
  """
  @callback init(terminal_state()) :: {:ok, plugin_state()} | {:error, String.t()}

  @doc """
  Handles input when the plugin is active
  """
  @callback handle_input(input :: String.t(), plugin_state(), terminal_state()) ::
              {:continue, plugin_state(), render_output()}
              | {:exit, render_output()}
              | {:error, String.t()}

  @doc """
  Renders the current plugin state
  """
  @callback render(plugin_state(), terminal_state()) :: render_output()

  @doc """
  Handles cleanup when exiting the plugin
  """
  @callback cleanup(plugin_state()) :: :ok

  @doc """
  Optional callback for handling special keys
  """
  @callback handle_key(key :: atom(), plugin_state(), terminal_state()) ::
              {:ok, plugin_state()} | :pass
  @optional_callbacks handle_key: 3
end
