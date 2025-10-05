defmodule Droodotfoo.Plugins.GameBase do
  @moduledoc """
  Shared utilities and patterns for game plugins.
  Provides common functionality to reduce duplication across game implementations.
  """

  @doc """
  Checks if game input should be blocked due to game state.
  Returns true if game is over or paused.
  """
  def game_blocked?(state) do
    Map.get(state, :game_over, false) or Map.get(state, :paused, false)
  end

  @doc """
  Handles restart logic for games.
  Calls the module's init/1 function and formats the response.
  """
  def handle_restart(module, terminal_state) do
    case module.init(terminal_state) do
      {:ok, new_state} ->
        {:continue, new_state, module.render(new_state, %{})}

      error ->
        error
    end
  end

  @doc """
  Creates an empty grid with specified dimensions and default value.

  ## Examples

      iex> GameBase.create_grid(3, 2, nil)
      [[nil, nil, nil], [nil, nil, nil]]

      iex> GameBase.create_grid(2, 2, false)
      [[false, false], [false, false]]
  """
  def create_grid(width, height, default_value \\ nil) do
    for _y <- 1..height do
      for _x <- 1..width, do: default_value
    end
  end

  @doc """
  Wraps input handling to check game state before processing.

  ## Examples

      defmodule MyGame do
        import Droodotfoo.Plugins.GameBase

        def handle_input(key, state, _terminal_state) do
          if game_blocked?(state) do
            {:continue, state, render(state, %{})}
          else
            # Handle actual input
            process_input(key, state)
          end
        end
      end
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour Droodotfoo.PluginSystem.Plugin

      @impl true
      def cleanup(_state), do: :ok

      defoverridable cleanup: 1

      import Droodotfoo.Plugins.GameBase, only: [game_blocked?: 1, handle_restart: 2, create_grid: 3]
    end
  end

  @doc """
  Generates common game metadata structure.
  """
  def game_metadata(name, version, description, author, commands, category \\ :game) do
    %{
      name: name,
      version: version,
      description: description,
      author: author,
      commands: commands,
      category: category
    }
  end

  @doc """
  Common pattern for handling game over state in rendering.
  """
  def game_over_overlay(lines, game_over?, pause_text \\ "Press 'R' to restart") do
    if game_over? do
      lines ++ ["", "   *** GAME OVER ***", "   #{pause_text}"]
    else
      lines
    end
  end
end
