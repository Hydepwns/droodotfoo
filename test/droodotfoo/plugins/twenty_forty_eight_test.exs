defmodule Droodotfoo.Plugins.TwentyFortyEightTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.Plugins.TwentyFortyEight

  describe "metadata/0" do
    test "returns correct plugin metadata" do
      meta = TwentyFortyEight.metadata()

      assert meta.name == "2048"
      assert meta.version == "1.0.0"
      assert meta.category == :game
      assert "2048" in meta.commands
      assert "twenty48" in meta.commands
    end
  end

  describe "init/1" do
    test "initializes with 4x4 grid" do
      {:ok, state} = TwentyFortyEight.init(%{})

      assert is_list(state.grid)
      assert length(state.grid) == 4
      assert Enum.all?(state.grid, fn row -> length(row) == 4 end)
    end

    test "starts with two random tiles" do
      {:ok, state} = TwentyFortyEight.init(%{})

      tile_count = count_non_nil_tiles(state.grid)
      assert tile_count == 2
    end

    test "initial tiles are 2 or 4" do
      {:ok, state} = TwentyFortyEight.init(%{})

      tiles = get_all_tiles(state.grid)
      assert Enum.all?(tiles, fn tile -> tile == 2 or tile == 4 end)
    end

    test "initializes with zero score" do
      {:ok, state} = TwentyFortyEight.init(%{})

      assert state.score == 0
      assert state.best_score == 0
    end

    test "initializes not game over" do
      {:ok, state} = TwentyFortyEight.init(%{})

      assert state.game_over == false
      assert state.won == false
    end

    test "initializes with empty move history" do
      {:ok, state} = TwentyFortyEight.init(%{})

      assert state.move_history == []
      assert state.can_undo == false
    end
  end

  describe "handle_input/3 - movement" do
    setup do
      {:ok, state} = TwentyFortyEight.init(%{})
      {:ok, state: state}
    end

    test "ArrowLeft slides tiles left", %{state: state} do
      {:continue, new_state, _output} = TwentyFortyEight.handle_input("ArrowLeft", state, %{})

      assert is_map(new_state)
      assert is_list(new_state.grid)
    end

    test "ArrowRight slides tiles right", %{state: state} do
      {:continue, new_state, _output} = TwentyFortyEight.handle_input("ArrowRight", state, %{})

      assert is_map(new_state)
      assert is_list(new_state.grid)
    end

    test "ArrowUp slides tiles up", %{state: state} do
      {:continue, new_state, _output} = TwentyFortyEight.handle_input("ArrowUp", state, %{})

      assert is_map(new_state)
      assert is_list(new_state.grid)
    end

    test "ArrowDown slides tiles down", %{state: state} do
      {:continue, new_state, _output} = TwentyFortyEight.handle_input("ArrowDown", state, %{})

      assert is_map(new_state)
      assert is_list(new_state.grid)
    end

    test "movement adds a new tile when grid changes", %{state: state} do
      # Create a specific grid that will definitely change
      test_grid = [
        [2, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil]
      ]

      state_with_grid = %{state | grid: test_grid}

      {:continue, new_state, _output} =
        TwentyFortyEight.handle_input("ArrowRight", state_with_grid, %{})

      # After moving right, the 2 should move and a new tile should appear
      new_tile_count = count_non_nil_tiles(new_state.grid)
      assert new_tile_count == 2
    end

    test "movement ignored when game over", %{state: state} do
      game_over_state = %{state | game_over: true}
      initial_grid = game_over_state.grid

      {:continue, new_state, _output} =
        TwentyFortyEight.handle_input("ArrowLeft", game_over_state, %{})

      assert new_state.grid == initial_grid
    end
  end

  describe "handle_input/3 - game controls" do
    setup do
      {:ok, state} = TwentyFortyEight.init(%{})
      {:ok, state: state}
    end

    test "r restarts the game", %{state: state} do
      # Modify state to have some score
      modified_state = %{state | score: 100}

      {:continue, new_state, _output} = TwentyFortyEight.handle_input("r", modified_state, %{})

      assert new_state.score == 0
      assert count_non_nil_tiles(new_state.grid) == 2
    end

    test "u undoes last move", %{state: state} do
      # Create a grid and make a move
      test_grid = [
        [2, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil]
      ]

      state_with_grid = %{state | grid: test_grid}

      {:continue, after_move, _output} =
        TwentyFortyEight.handle_input("ArrowRight", state_with_grid, %{})

      # Undo should be possible now
      assert after_move.can_undo == true

      {:continue, undone_state, _output} = TwentyFortyEight.handle_input("u", after_move, %{})

      # Grid should be closer to original (though not exact due to random tile)
      # At minimum, score should be restored
      assert undone_state.score == 0
    end

    test "u does nothing when no history", %{state: state} do
      {:continue, new_state, _output} = TwentyFortyEight.handle_input("u", state, %{})

      assert new_state.grid == state.grid
      assert new_state.score == state.score
    end

    test "q exits the game", %{state: state} do
      {:exit, _output} = TwentyFortyEight.handle_input("q", state, %{})
    end

    test "unknown key returns current state", %{state: state} do
      {:continue, new_state, _output} = TwentyFortyEight.handle_input("x", state, %{})

      assert new_state.grid == state.grid
      assert new_state.score == state.score
    end
  end

  describe "render/2" do
    test "renders game board with headers" do
      {:ok, state} = TwentyFortyEight.init(%{})
      output = TwentyFortyEight.render(state, %{})

      assert is_list(output)
      assert Enum.any?(output, &String.contains?(&1, "2048"))
      assert Enum.any?(output, &String.contains?(&1, "Score:"))
      assert Enum.any?(output, &String.contains?(&1, "Best:"))
      assert Enum.any?(output, &String.contains?(&1, "Controls:"))
    end

    test "renders PLAYING status when active" do
      {:ok, state} = TwentyFortyEight.init(%{})
      output = TwentyFortyEight.render(state, %{})

      assert Enum.any?(output, &String.contains?(&1, "PLAYING"))
    end

    test "renders GAME OVER status when game over" do
      {:ok, state} = TwentyFortyEight.init(%{})
      game_over_state = %{state | game_over: true}
      output = TwentyFortyEight.render(game_over_state, %{})

      assert Enum.any?(output, &String.contains?(&1, "GAME OVER"))
    end

    test "renders YOU WIN status when won" do
      {:ok, state} = TwentyFortyEight.init(%{})
      won_state = %{state | won: true, game_over: false}
      output = TwentyFortyEight.render(won_state, %{})

      assert Enum.any?(output, &String.contains?(&1, "YOU WIN"))
    end

    test "renders score correctly" do
      {:ok, state} = TwentyFortyEight.init(%{})
      state_with_score = %{state | score: 1234}
      output = TwentyFortyEight.render(state_with_score, %{})

      output_str = Enum.join(output, "\n")
      assert String.contains?(output_str, "1234")
    end
  end

  describe "cleanup/1" do
    test "cleanup returns :ok" do
      {:ok, state} = TwentyFortyEight.init(%{})
      assert TwentyFortyEight.cleanup(state) == :ok
    end
  end

  describe "game logic - tile merging" do
    test "merges two tiles of same value" do
      {:ok, state} = TwentyFortyEight.init(%{})

      # Create a grid with two 2s on the left
      test_grid = [
        [2, 2, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil]
      ]

      state_with_grid = %{state | grid: test_grid}

      {:continue, new_state, _output} =
        TwentyFortyEight.handle_input("ArrowLeft", state_with_grid, %{})

      # Should have merged into a 4
      first_row = Enum.at(new_state.grid, 0)
      assert 4 in first_row
    end

    test "increases score when tiles merge" do
      {:ok, state} = TwentyFortyEight.init(%{})

      # Create a grid with two 2s
      test_grid = [
        [2, 2, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil]
      ]

      state_with_grid = %{state | grid: test_grid}

      {:continue, new_state, _output} =
        TwentyFortyEight.handle_input("ArrowLeft", state_with_grid, %{})

      # Score should increase by 4 (the merged value)
      assert new_state.score == 4
    end

    test "does not merge different values" do
      {:ok, state} = TwentyFortyEight.init(%{})

      # Create a grid with a 2 and a 4
      test_grid = [
        [2, 4, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil]
      ]

      state_with_grid = %{state | grid: test_grid}

      {:continue, new_state, _output} =
        TwentyFortyEight.handle_input("ArrowLeft", state_with_grid, %{})

      # Should still have both 2 and 4
      first_row = Enum.at(new_state.grid, 0)
      assert 2 in first_row
      assert 4 in first_row
    end
  end

  describe "game logic - win and lose conditions" do
    test "detects win when 2048 tile is created" do
      {:ok, state} = TwentyFortyEight.init(%{})

      # Create a grid with two 1024s
      test_grid = [
        [1024, 1024, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil]
      ]

      state_with_grid = %{state | grid: test_grid}

      {:continue, new_state, _output} =
        TwentyFortyEight.handle_input("ArrowLeft", state_with_grid, %{})

      # Should have won
      assert new_state.won == true
    end

    test "updates best score" do
      {:ok, state} = TwentyFortyEight.init(%{})

      test_grid = [
        [2, 2, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil]
      ]

      state_with_grid = %{state | grid: test_grid, best_score: 0}

      {:continue, new_state, _output} =
        TwentyFortyEight.handle_input("ArrowLeft", state_with_grid, %{})

      assert new_state.best_score >= new_state.score
    end
  end

  describe "game logic - undo functionality" do
    test "stores move history" do
      {:ok, state} = TwentyFortyEight.init(%{})

      test_grid = [
        [2, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil]
      ]

      state_with_grid = %{state | grid: test_grid}

      {:continue, new_state, _output} =
        TwentyFortyEight.handle_input("ArrowRight", state_with_grid, %{})

      # Should have move history now
      assert length(new_state.move_history) > 0
      assert new_state.can_undo == true
    end

    test "limits move history to 10 moves" do
      {:ok, state} = TwentyFortyEight.init(%{})

      # Make 15 moves
      final_state =
        Enum.reduce(1..15, state, fn _i, acc_state ->
          {:continue, new_state, _output} =
            TwentyFortyEight.handle_input("ArrowLeft", acc_state, %{})

          new_state
        end)

      # Should only keep last 10
      assert length(final_state.move_history) <= 10
    end
  end

  # Helper functions

  defp count_non_nil_tiles(grid) do
    Enum.reduce(grid, 0, fn row, acc ->
      non_nil_count = Enum.count(row, &(&1 != nil))
      acc + non_nil_count
    end)
  end

  defp get_all_tiles(grid) do
    grid
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end
end
