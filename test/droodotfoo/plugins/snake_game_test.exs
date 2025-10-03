defmodule Droodotfoo.Plugins.SnakeGameTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Plugins.SnakeGame

  describe "metadata/0" do
    test "returns correct plugin metadata" do
      metadata = SnakeGame.metadata()

      assert metadata.name == "snake"
      assert metadata.version == "1.0.0"
      assert metadata.description == "Classic Snake game - use WASD or arrow keys to move"
      assert metadata.author == "droo.foo"
      assert metadata.commands == ["snake", "play snake"]
      assert metadata.category == :game
    end
  end

  describe "init/1" do
    test "initializes game state correctly" do
      terminal_state = %{width: 80, height: 24}

      assert {:ok, state} = SnakeGame.init(terminal_state)
      assert %SnakeGame{} = state
      assert state.score == 0
      assert state.game_over == false
      assert state.direction == :right
      assert state.width == 40
      assert state.height == 20

      # Snake should have initial segments
      assert length(state.snake) == 3
      assert [{10, 10}, {9, 10}, {8, 10}] = state.snake

      # Food should be placed
      assert {_x, _y} = state.food
    end
  end

  describe "handle_input/3" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, initial_state} = SnakeGame.init(terminal_state)
      {:ok, state: initial_state, terminal_state: terminal_state}
    end

    test "handles direction changes with WASD", %{state: state, terminal_state: terminal_state} do
      # Snake starts moving right
      assert state.direction == :right

      # Test W (up) - can turn up from right
      {:continue, new_state, _output} = SnakeGame.handle_input("w", state, terminal_state)
      assert new_state.direction == :up

      # Test S (down) - blocked because we're moving up
      {:continue, new_state2, _output} = SnakeGame.handle_input("s", new_state, terminal_state)
      # Direction unchanged
      assert new_state2.direction == :up

      # Test A (left) - should work since we're moving up
      {:continue, new_state3, _output} = SnakeGame.handle_input("a", new_state2, terminal_state)
      assert new_state3.direction == :left

      # Test D (right) - blocked because we're moving left
      {:continue, new_state4, _output} = SnakeGame.handle_input("d", new_state3, terminal_state)
      # Direction unchanged
      assert new_state4.direction == :left
    end

    test "prevents reversing direction", %{state: state, terminal_state: terminal_state} do
      # Snake starts moving right, shouldn't be able to go left
      {:continue, new_state, _output} = SnakeGame.handle_input("a", state, terminal_state)
      # Direction unchanged
      assert new_state.direction == :right

      # Change to up first
      {:continue, new_state, _output} = SnakeGame.handle_input("w", state, terminal_state)
      assert new_state.direction == :up

      # Now shouldn't be able to go down
      {:continue, new_state, _output} = SnakeGame.handle_input("s", new_state, terminal_state)
      # Direction unchanged
      assert new_state.direction == :up
    end

    test "handles quit command", %{state: state, terminal_state: terminal_state} do
      assert {:exit, _output} = SnakeGame.handle_input("q", state, terminal_state)
    end

    test "handles restart after game over", %{state: state, terminal_state: terminal_state} do
      # Force game over state
      game_over_state = %{state | game_over: true, score: 100}

      # Press 'r' to restart
      {:continue, new_state, _output} =
        SnakeGame.handle_input("r", game_over_state, terminal_state)

      assert new_state.game_over == false
      assert new_state.score == 0
      assert length(new_state.snake) == 3
    end

    test "ignores input when game is over except 'r' and 'q'", %{
      state: state,
      terminal_state: terminal_state
    } do
      game_over_state = %{state | game_over: true}

      # Movement should be ignored
      {:continue, unchanged_state, _output} =
        SnakeGame.handle_input("w", game_over_state, terminal_state)

      assert unchanged_state.game_over == true

      # But 'q' should work
      assert {:exit, _output} = SnakeGame.handle_input("q", game_over_state, terminal_state)
    end

    test "moves snake on space/enter", %{state: state, terminal_state: terminal_state} do
      [{head_x, head_y} | _] = state.snake

      # Space should trigger a move
      {:continue, new_state, _output} = SnakeGame.handle_input(" ", state, terminal_state)

      # Snake head should have moved
      [{new_head_x, new_head_y} | _] = new_state.snake
      assert {new_head_x, new_head_y} != {head_x, head_y}
    end
  end

  describe "handle_key/3" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, initial_state} = SnakeGame.init(terminal_state)
      {:ok, state: initial_state, terminal_state: terminal_state}
    end

    test "handles arrow keys", %{state: state, terminal_state: terminal_state} do
      # Snake starts moving right
      assert state.direction == :right

      # Test arrow up (valid move from right)
      {:ok, new_state} = SnakeGame.handle_key(:arrow_up, state, terminal_state)
      assert new_state.direction == :up

      # Test arrow left (valid move from up)
      {:ok, new_state} = SnakeGame.handle_key(:arrow_left, new_state, terminal_state)
      assert new_state.direction == :left

      # Test arrow down (valid move from left)
      {:ok, new_state} = SnakeGame.handle_key(:arrow_down, new_state, terminal_state)
      assert new_state.direction == :down

      # Test arrow right (valid move from down)
      {:ok, new_state} = SnakeGame.handle_key(:arrow_right, new_state, terminal_state)
      assert new_state.direction == :right

      # Test invalid move (can't go left when moving right)
      assert :pass = SnakeGame.handle_key(:arrow_left, new_state, terminal_state)
    end

    test "passes through unknown keys", %{state: state, terminal_state: terminal_state} do
      assert :pass = SnakeGame.handle_key(:f1, state, terminal_state)
      assert :pass = SnakeGame.handle_key(:page_up, state, terminal_state)
    end
  end

  describe "render/2" do
    test "renders game board" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = SnakeGame.init(terminal_state)

      output = SnakeGame.render(state, terminal_state)

      # Should have title and score
      assert Enum.any?(output, &String.contains?(&1, "SNAKE GAME"))
      assert Enum.any?(output, &String.contains?(&1, "Score: 0"))

      # Should have borders (looking for corner characters)
      assert Enum.any?(output, &String.contains?(&1, "+"))

      # Should render snake segments
      # Head
      assert Enum.any?(output, &String.contains?(&1, "@"))
      # Body (uses 'o' character)
      assert Enum.any?(output, &String.contains?(&1, "o"))
    end

    test "renders game over screen" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = SnakeGame.init(terminal_state)
      game_over_state = %{state | game_over: true, score: 150}

      output = SnakeGame.render(game_over_state, terminal_state)

      # Should show game over message
      assert Enum.any?(output, &String.contains?(&1, "GAME OVER"))
      assert Enum.any?(output, &String.contains?(&1, "Final Score: 150"))
      assert Enum.any?(output, &String.contains?(&1, "Press 'R' to restart"))
    end
  end

  describe "cleanup/1" do
    test "cleanup returns ok" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = SnakeGame.init(terminal_state)

      assert :ok = SnakeGame.cleanup(state)
    end
  end

  describe "game mechanics" do
    test "snake grows when eating food" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = SnakeGame.init(terminal_state)

      # Place food at a known location next to snake head
      [{head_x, head_y} | _] = state.snake
      state_with_food = %{state | food: {head_x + 1, head_y}}

      # Move snake to eat food
      {:continue, new_state, _output} =
        SnakeGame.handle_input(" ", state_with_food, terminal_state)

      # Snake should be longer
      assert length(new_state.snake) == 4
      # Score should increase
      assert new_state.score == 10
      # New food should be generated
      assert new_state.food != {head_x + 1, head_y}
    end

    test "game ends on wall collision" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = SnakeGame.init(terminal_state)

      # Move snake to near right wall
      state_near_wall = %{state | snake: [{39, 10}, {38, 10}, {37, 10}], direction: :right}

      # Move into wall
      {:continue, new_state, _output} =
        SnakeGame.handle_input(" ", state_near_wall, terminal_state)

      assert new_state.game_over == true
    end

    test "game ends on self collision" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = SnakeGame.init(terminal_state)

      # Create a snake that will collide with itself
      # Make a longer snake in a position where it can hit itself
      snake_segments = [
        # head
        {10, 10},
        {9, 10},
        {9, 11},
        # This creates a loop
        {10, 11},
        {11, 11}
      ]

      state_with_loop = %{state | snake: snake_segments, direction: :down}

      # Move down - head should hit the segment at {10, 11}
      {:continue, new_state, _output} =
        SnakeGame.handle_input(" ", state_with_loop, terminal_state)

      assert new_state.game_over == true
    end
  end
end
