defmodule Droodotfoo.PluginSystem.Config do
  @moduledoc """
  Configuration for the plugin system, including built-in plugin list.
  """

  @doc """
  List of built-in plugin modules that are auto-registered on startup.
  """
  @spec builtin_plugins() :: [module()]
  def builtin_plugins do
    [
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
  end
end
