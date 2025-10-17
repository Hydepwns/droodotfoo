defmodule Droodotfoo.Plugins.SnakeGame do
  @moduledoc """
  Classic Snake game plugin for the terminal.

  Control a growing snake to eat food while avoiding walls and self-collision.
  The snake grows longer with each food item eaten, increasing difficulty.

  ## Gameplay

  - Start with 3-segment snake moving right
  - Food appears at random positions (marked with `*`)
  - Eating food adds 10 points and grows snake by 1 segment
  - Game ends on wall collision or self-collision

  ## Controls

  - **WASD**: Move up/left/down/right
  - **Arrow Keys**: Alternative movement controls
  - **R**: Restart game (when game over)
  - **Q**: Quit game

  ## Visuals

  - `@`: Snake head
  - `o`: Snake body segments
  - `*`: Food item
  - Bordered 40x20 game board

  ## Scoring

  - +10 points per food item
  - No time bonus or combo system
  """

  use Droodotfoo.Plugins.GameBase

  alias Droodotfoo.Plugins.GameUI

  @type position :: {integer(), integer()}
  @type direction :: :up | :down | :left | :right
  @type state :: %__MODULE__{
          snake: [position()],
          food: position(),
          direction: direction(),
          score: integer(),
          game_over: boolean(),
          width: integer(),
          height: integer()
        }
  @type terminal_state :: map()
  @type render_output :: [String.t()]

  defstruct [
    :snake,
    :food,
    :direction,
    :score,
    :game_over,
    :width,
    :height
  ]

  @width 40
  @height 20

  # Plugin Behaviour Callbacks

  @impl true
  @spec metadata() :: map()
  def metadata do
    %{
      name: "snake",
      version: "1.0.0",
      description: "Classic Snake game - use WASD or arrow keys to move",
      author: "droo.foo",
      commands: ["snake", "play snake"],
      category: :game
    }
  end

  @impl true
  @spec init(terminal_state()) :: {:ok, state()}
  def init(_terminal_state) do
    initial_state = %__MODULE__{
      snake: [{10, 10}, {9, 10}, {8, 10}],
      food: generate_food([{10, 10}, {9, 10}, {8, 10}]),
      direction: :right,
      score: 0,
      game_over: false,
      width: @width,
      height: @height
    }

    {:ok, initial_state}
  end

  @impl true
  @spec handle_input(String.t(), state(), terminal_state()) ::
          {:continue, state(), render_output()}
          | {:exit, [String.t()]}
  def handle_input(input, state, terminal_state) do
    cond do
      input in ["q", "Q", "exit"] ->
        exit_game(state)

      state.game_over and input in ["r", "R"] ->
        handle_restart(__MODULE__, terminal_state)

      game_blocked?(state) ->
        {:continue, state, render(state, terminal_state)}

      true ->
        process_direction_input(input, state, terminal_state)
    end
  end

  defp exit_game(state) do
    {:exit, ["Thanks for playing Snake! Final score: #{state.score}"]}
  end

  defp process_direction_input(input, state, terminal_state) do
    new_direction = parse_direction_input(input, state.direction)
    new_state = %{state | direction: new_direction} |> update_game()
    {:continue, new_state, render(new_state, terminal_state)}
  end

  defp parse_direction_input(input, current_direction) do
    case String.downcase(input) do
      "w" when current_direction != :down -> :up
      "s" when current_direction != :up -> :down
      "a" when current_direction != :right -> :left
      "d" when current_direction != :left -> :right
      _ -> current_direction
    end
  end

  @impl true
  @spec handle_key(atom(), state(), terminal_state()) :: {:ok, state()} | :pass
  def handle_key(key, state, _terminal_state) do
    if state.game_over do
      :pass
    else
      new_direction =
        case key do
          :arrow_up when state.direction != :down -> :up
          :arrow_down when state.direction != :up -> :down
          :arrow_left when state.direction != :right -> :left
          :arrow_right when state.direction != :left -> :right
          _ -> state.direction
        end

      if new_direction != state.direction do
        {:ok, %{state | direction: new_direction}}
      else
        :pass
      end
    end
  end

  @impl true
  @spec render(state(), terminal_state()) :: render_output()
  def render(state, terminal_state) do
    # Calculate available space for the game
    # 3 header + 4 footer lines
    available_height = terminal_state.height - 7
    board_height = min(@height, available_height)

    # Only show the part of the board that fits
    board = draw_board(state) |> Enum.take(board_height)

    header = [
      "=" |> String.duplicate(min(@width + 2, terminal_state.width)),
      "  SNAKE GAME - Score: #{state.score}  ",
      "=" |> String.duplicate(min(@width + 2, terminal_state.width))
    ]

    instructions =
      if state.game_over do
        [
          "",
          "  GAME OVER! Final Score: #{state.score}  ",
          "  Press 'R' to restart or 'Q' to quit  ",
          ""
        ]
      else
        [
          "",
          "  Use WASD or arrow keys to move  ",
          "  Press Q to quit  ",
          ""
        ]
      end

    result = header ++ board ++ instructions

    # Ensure we don't exceed terminal height
    Enum.take(result, terminal_state.height)
  end

  @impl true
  @spec cleanup(state()) :: :ok
  def cleanup(_state) do
    :ok
  end

  # Private Functions

  defp update_game(state) do
    if state.game_over do
      state
    else
      # Move snake
      new_head = move_head(hd(state.snake), state.direction)

      # Check collisions
      cond do
        # Wall collision
        elem(new_head, 0) < 0 or elem(new_head, 0) >= @width or
          elem(new_head, 1) < 0 or elem(new_head, 1) >= @height ->
          %{state | game_over: true}

        # Self collision
        new_head in state.snake ->
          %{state | game_over: true}

        # Food collision
        new_head == state.food ->
          new_snake = [new_head | state.snake]
          %{state | snake: new_snake, food: generate_food(new_snake), score: state.score + 10}

        # Normal move
        true ->
          new_snake = [new_head | Enum.drop(state.snake, -1)]
          %{state | snake: new_snake}
      end
    end
  end

  defp move_head({x, y}, direction) do
    case direction do
      :up -> {x, y - 1}
      :down -> {x, y + 1}
      :left -> {x - 1, y}
      :right -> {x + 1, y}
    end
  end

  defp generate_food(snake) do
    # Generate random position not occupied by snake
    Enum.reduce_while(1..1000, nil, fn _, _ ->
      pos = {:rand.uniform(@width) - 1, :rand.uniform(@height) - 1}

      if pos in snake do
        {:cont, nil}
      else
        {:halt, pos}
      end
    end) || {0, 0}
  end

  defp draw_board(state) do
    # Create empty board
    board =
      for y <- 0..(@height - 1) do
        for x <- 0..(@width - 1) do
          cond do
            # Snake head
            {x, y} == hd(state.snake) -> "@"
            # Snake body
            {x, y} in state.snake -> "o"
            # Food
            {x, y} == state.food -> "*"
            # Empty
            true -> " "
          end
        end
        |> Enum.join()
      end

    # Add borders using GameUI helper
    border_top = GameUI.horizontal_border(@width + 2, "+", "-", "+")
    border_bottom = GameUI.horizontal_border(@width + 2, "+", "-", "+")

    board_with_borders =
      Enum.map(board, fn line ->
        "|" <> line <> "|"
      end)

    [border_top] ++ board_with_borders ++ [border_bottom]
  end
end
