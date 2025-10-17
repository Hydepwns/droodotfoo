defmodule Droodotfoo.Terminal.Commands.Plugins do
  @moduledoc """
  Plugin command implementations for the terminal.

  Provides commands for:
  - Plugin management: List available plugins
  - Game plugins: Snake, Calculator, Matrix Rain, Conway's Life, Tetris, 2048, Wordle, Typing Test
  - Feature plugins: Spotify, GitHub integration
  """

  # Plugin Management

  @doc """
  List all available plugins.
  """
  def plugins([], _state) do
    case Droodotfoo.PluginSystem.list_plugins() do
      [] ->
        {:ok, "No plugins available"}

      plugins ->
        output =
          [
            "Available Plugins:",
            ""
          ] ++
            Enum.map(plugins, fn plugin ->
              "  #{plugin.name} (v#{plugin.version}) - #{plugin.description}"
            end)

        {:ok, Enum.join(output, "\n")}
    end
  end

  def plugins(["list"], state), do: plugins([], state)

  def plugins(args, _state) do
    {:error, "Unknown plugins command: #{Enum.join(args, " ")}"}
  end

  # Game Plugins

  @doc """
  Launch Snake game plugin.
  """
  def snake([], state), do: launch_plugin("snake", state)

  @doc """
  Launch Calculator plugin.
  """
  def calc([], state), do: launch_plugin("calc", state)
  def calculator(args, state), do: calc(args, state)

  @doc """
  Launch Matrix Rain animation plugin.
  """
  def matrix([], state), do: launch_plugin("matrix", state)
  def rain(args, state), do: matrix(args, state)

  @doc """
  Launch Conway's Game of Life plugin.
  """
  def conway([], state), do: launch_plugin("conway", state)
  def life(args, state), do: conway(args, state)

  @doc """
  Launch Tetris game plugin.
  """
  def tetris([], state), do: launch_plugin("tetris", state)
  def t(args, state), do: tetris(args, state)

  @doc """
  Launch 2048 game plugin.
  """
  def twenty48([], state), do: launch_plugin("2048", state)
  def game48(args, state), do: twenty48(args, state)

  @doc """
  Launch Wordle game plugin.
  """
  def wordle([], state), do: launch_plugin("wordle", state)
  def word(args, state), do: wordle(args, state)

  @doc """
  Launch Typing Test plugin.
  """
  def typing([], state), do: launch_plugin("typing_test", state)
  def type(args, state), do: typing(args, state)
  def wpm(args, state), do: typing(args, state)

  # Feature Plugins

  @doc """
  Spotify player integration with authentication support.

  Subcommands:
  - spotify        - Open Spotify player interface
  - spotify auth   - Authenticate with Spotify
  - spotify play   - Open Spotify player
  """
  def spotify([], state) do
    new_state = Map.put(state, :section_change, :spotify)
    {:ok, "Opening Spotify player interface...", new_state}
  end

  def spotify(["auth" | _], state) do
    new_state =
      state
      |> Map.put(:section_change, :spotify)
      |> Map.put(:spotify_action, :start_auth)

    {:ok, "Initiating Spotify authentication...", new_state}
  end

  def spotify(["play" | _], state) do
    new_state = Map.put(state, :section_change, :spotify)
    {:ok, "Opening Spotify player...", new_state}
  end

  def spotify([subcommand | _], _state) do
    {:error,
     "Unknown spotify subcommand: #{subcommand}\n\nUsage:\n  spotify        - Open Spotify player\n  spotify auth   - Authenticate with Spotify\n  spotify play   - Open Spotify player"}
  end

  def music(args, state), do: spotify(args, state)

  @doc """
  Launch GitHub integration plugin.
  """
  def github([], state), do: launch_plugin("github", state)
  def gh(args, state), do: github(args, state)

  # Helper Functions

  @doc false
  defp launch_plugin(plugin_name, state) do
    case Droodotfoo.PluginSystem.start_plugin(plugin_name, state) do
      {:ok, output} -> {:plugin, plugin_name, output}
      {:error, reason} -> {:error, reason}
    end
  end
end
