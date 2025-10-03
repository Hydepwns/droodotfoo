defmodule Droodotfoo.Plugins.SnakeGame do
  @moduledoc """
  Classic Snake game plugin for the terminal
  """

  @behaviour Droodotfoo.PluginSystem.Plugin

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
  def handle_input(input, state, terminal_state) do
    cond do
      input in ["q", "Q", "exit"] ->
        {:exit, ["Thanks for playing Snake! Final score: #{state.score}"]}

      state.game_over and input in ["r", "R"] ->
        {:ok, new_state} = init(terminal_state)
        {:continue, new_state, render(new_state, terminal_state)}

      state.game_over ->
        {:continue, state, render(state, terminal_state)}

      true ->
        new_direction =
          case String.downcase(input) do
            "w" when state.direction != :down -> :up
            "s" when state.direction != :up -> :down
            "a" when state.direction != :right -> :left
            "d" when state.direction != :left -> :right
            _ -> state.direction
          end

        new_state = %{state | direction: new_direction} |> update_game()
        {:continue, new_state, render(new_state, terminal_state)}
    end
  end

  @impl true
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
  def render(state, terminal_state) do
    # Calculate available space for the game
    available_height = terminal_state.height - 7  # 3 header + 4 footer lines
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

      if pos not in snake do
        {:halt, pos}
      else
        {:cont, nil}
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

    # Add borders
    border_top = "+" <> String.duplicate("-", @width) <> "+"
    border_bottom = "+" <> String.duplicate("-", @width) <> "+"

    board_with_borders =
      Enum.map(board, fn line ->
        "|" <> line <> "|"
      end)

    [border_top] ++ board_with_borders ++ [border_bottom]
  end
end
