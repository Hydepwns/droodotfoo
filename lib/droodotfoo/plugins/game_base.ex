defmodule Droodotfoo.Plugins.GameBase do
  @moduledoc """
  Shared utilities and patterns for game plugins.
  Provides common functionality to reduce duplication across game implementations.

  ## Type Definitions

  - `state` - Game state map (varies by plugin)
  - `coordinates` - Tuple of {x, y} integers
  - `direction` - Atom representing movement: `:up`, `:down`, `:left`, `:right`
  - `grid` - 2D list representing game board: `[[any()]]`
  """

  @type state :: map()
  @type coordinates :: {integer(), integer()}
  @type direction :: :up | :down | :left | :right
  @type grid :: [[any()]]
  @type terminal_state :: map()

  @doc """
  Checks if game input should be blocked due to game state.
  Returns true if game is over or paused.
  """
  @spec game_blocked?(state()) :: boolean()
  def game_blocked?(state) do
    Map.get(state, :game_over, false) or Map.get(state, :paused, false)
  end

  @doc """
  Handles restart logic for games.
  Calls the module's init/1 function and formats the response.
  """
  @spec handle_restart(module(), terminal_state()) ::
          {:continue, state(), String.t() | [String.t()]} | {:error, any()}
  def handle_restart(module, terminal_state) do
    case module.init(terminal_state) do
      {:ok, new_state} ->
        {:continue, new_state, module.render(new_state, terminal_state)}

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
  @spec create_grid(integer(), integer(), any()) :: grid()
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

      import Droodotfoo.Plugins.GameBase,
        only: [game_blocked?: 1, handle_restart: 2, create_grid: 3]
    end
  end

  @doc """
  Generates common game metadata structure.
  """
  @spec game_metadata(String.t(), String.t(), String.t(), String.t(), [String.t()], atom()) ::
          map()
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
  @spec game_over_overlay([String.t()], boolean(), String.t()) :: [String.t()]
  def game_over_overlay(lines, game_over?, pause_text \\ "Press 'R' to restart") do
    if game_over? do
      lines ++ ["", "   *** GAME OVER ***", "   #{pause_text}"]
    else
      lines
    end
  end

  @doc """
  Creates a bordered box for game UI elements.
  """
  @spec create_border_box([String.t()], integer()) :: [String.t()]
  def create_border_box(content, width \\ 40) do
    top_bottom = String.duplicate("─", width - 2)
    border_line = "┌" <> top_bottom <> "┐"
    bottom_line = "└" <> top_bottom <> "┘"

    content_lines =
      Enum.map(content, fn line ->
        padded_line = String.pad_trailing(line, width - 4)
        "│ #{padded_line} │"
      end)

    [border_line] ++ content_lines ++ [bottom_line]
  end

  @doc """
  Centers text within a given width.
  """
  @spec center_text(String.t(), integer()) :: String.t()
  def center_text(text, width) when is_binary(text) and is_integer(width) do
    text_length = String.length(text)

    if text_length >= width do
      text
    else
      padding = div(width - text_length, 2)
      String.pad_leading(text, text_length + padding)
    end
  end

  @doc """
  Creates a progress bar for game elements.
  """
  @spec create_progress_bar(integer(), integer(), integer()) :: String.t()
  def create_progress_bar(current, max, width \\ 20)
      when is_integer(current) and is_integer(max) and is_integer(width) do
    percentage = if max > 0, do: current / max, else: 0.0
    filled = round(percentage * width)
    empty = width - filled

    "[" <> String.duplicate("█", filled) <> String.duplicate("░", empty) <> "]"
  end

  @doc """
  Generates random coordinates within bounds.
  """
  @spec random_coordinates(integer(), integer()) :: coordinates()
  def random_coordinates(width, height) when is_integer(width) and is_integer(height) do
    x = :rand.uniform(width) - 1
    y = :rand.uniform(height) - 1
    {x, y}
  end

  @doc """
  Checks if coordinates are within bounds.
  """
  @spec in_bounds?(coordinates(), integer(), integer()) :: boolean()
  def in_bounds?({x, y}, width, height)
      when is_integer(x) and is_integer(y) and is_integer(width) and is_integer(height) do
    x >= 0 and x < width and y >= 0 and y < height
  end

  @doc """
  Calculates distance between two points.
  """
  @spec distance(coordinates(), coordinates()) :: float()
  def distance({x1, y1}, {x2, y2})
      when is_integer(x1) and is_integer(y1) and is_integer(x2) and is_integer(y2) do
    dx = x2 - x1
    dy = y2 - y1
    :math.sqrt(dx * dx + dy * dy)
  end

  @doc """
  Formats score with proper padding.
  """
  @spec format_score(integer(), integer()) :: String.t()
  def format_score(score, max_score \\ 999_999)
      when is_integer(score) and is_integer(max_score) do
    score_str = Integer.to_string(score)
    max_str = Integer.to_string(max_score)
    max_length = String.length(max_str)
    String.pad_leading(score_str, max_length, "0")
  end

  @doc """
  Creates a countdown timer display.
  """
  @spec create_countdown(integer()) :: String.t()
  def create_countdown(seconds) when is_integer(seconds) and seconds >= 0 do
    minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(remaining_seconds), 2, "0")}"
  end

  @doc """
  Generates a random direction (up, down, left, right).
  """
  @spec random_direction() :: direction()
  def random_direction do
    [:up, :down, :left, :right] |> Enum.random()
  end

  @doc """
  Converts direction to coordinate delta.
  """
  @spec direction_to_delta(direction() | atom()) :: coordinates()
  def direction_to_delta(:up), do: {0, -1}
  def direction_to_delta(:down), do: {0, 1}
  def direction_to_delta(:left), do: {-1, 0}
  def direction_to_delta(:right), do: {1, 0}
  def direction_to_delta(_), do: {0, 0}

  @doc """
  Adds two coordinate tuples.
  """
  @spec add_coordinates(coordinates(), coordinates()) :: coordinates()
  def add_coordinates({x1, y1}, {x2, y2})
      when is_integer(x1) and is_integer(y1) and is_integer(x2) and is_integer(y2) do
    {x1 + x2, y1 + y2}
  end

  @doc """
  Subtracts two coordinate tuples.
  """
  @spec subtract_coordinates(coordinates(), coordinates()) :: coordinates()
  def subtract_coordinates({x1, y1}, {x2, y2})
      when is_integer(x1) and is_integer(y1) and is_integer(x2) and is_integer(y2) do
    {x1 - x2, y1 - y2}
  end
end
