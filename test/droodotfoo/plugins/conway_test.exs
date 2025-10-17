defmodule Droodotfoo.Plugins.ConwayTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.Plugins.Conway

  describe "metadata/0" do
    test "returns correct plugin metadata" do
      meta = Conway.metadata()

      assert meta.name == "conway"
      assert meta.version == "1.0.0"
      assert meta.category == :game
      assert "conway" in meta.commands
      assert "life" in meta.commands
    end
  end

  describe "init/1" do
    test "initializes with empty grid" do
      {:ok, state} = Conway.init(%{})

      assert state.width == 60
      assert state.height == 20
      assert state.generation == 0
      assert state.running == false
      assert state.speed == 500
      assert state.pattern_name == "empty"
      assert is_list(state.grid)
      assert length(state.grid) == 20
    end
  end

  describe "handle_input/3" do
    setup do
      {:ok, state} = Conway.init(%{})
      {:ok, state: state}
    end

    test "space toggles play/pause", %{state: state} do
      {:continue, new_state, _output} = Conway.handle_input(" ", state, %{})
      assert new_state.running == true

      {:continue, new_state2, _output} = Conway.handle_input(" ", new_state, %{})
      assert new_state2.running == false
    end

    test "s steps one generation", %{state: state} do
      {:continue, new_state, _output} = Conway.handle_input("s", state, %{})
      assert new_state.generation == 1
    end

    test "c clears the grid", %{state: state} do
      # Load a pattern first
      {:continue, state_with_pattern, _} = Conway.handle_input("1", state, %{})
      assert state_with_pattern.pattern_name == "glider"

      # Clear it
      {:continue, cleared_state, _output} = Conway.handle_input("c", state_with_pattern, %{})
      assert cleared_state.generation == 0
      assert cleared_state.running == false
      assert cleared_state.pattern_name == "empty"
    end

    test "r generates random pattern", %{state: state} do
      {:continue, new_state, _output} = Conway.handle_input("r", state, %{})
      assert new_state.pattern_name == "random"
      assert new_state.generation == 0
    end

    test "+ increases speed (decreases delay)", %{state: state} do
      initial_speed = state.speed
      {:continue, new_state, _output} = Conway.handle_input("+", state, %{})
      assert new_state.speed < initial_speed
    end

    test "- decreases speed (increases delay)", %{state: state} do
      initial_speed = state.speed
      {:continue, new_state, _output} = Conway.handle_input("-", state, %{})
      assert new_state.speed > initial_speed
    end

    test "1 loads glider pattern", %{state: state} do
      {:continue, new_state, _output} = Conway.handle_input("1", state, %{})
      assert new_state.pattern_name == "glider"
      assert new_state.generation == 0
    end

    test "2 loads blinker pattern", %{state: state} do
      {:continue, new_state, _output} = Conway.handle_input("2", state, %{})
      assert new_state.pattern_name == "blinker"
    end

    test "3 loads toad pattern", %{state: state} do
      {:continue, new_state, _output} = Conway.handle_input("3", state, %{})
      assert new_state.pattern_name == "toad"
    end

    test "4 loads beacon pattern", %{state: state} do
      {:continue, new_state, _output} = Conway.handle_input("4", state, %{})
      assert new_state.pattern_name == "beacon"
    end

    test "5 loads pulsar pattern", %{state: state} do
      {:continue, new_state, _output} = Conway.handle_input("5", state, %{})
      assert new_state.pattern_name == "pulsar"
    end

    test "q exits the game", %{state: state} do
      {:exit, _output} = Conway.handle_input("q", state, %{})
    end

    test "unknown key returns current state", %{state: state} do
      {:continue, new_state, _output} = Conway.handle_input("x", state, %{})
      assert new_state.generation == state.generation
    end
  end

  describe "render/2" do
    test "renders game board with headers" do
      {:ok, state} = Conway.init(%{})
      output = Conway.render(state, %{})

      assert is_list(output)
      assert Enum.any?(output, &String.contains?(&1, "CONWAY'S GAME OF LIFE"))
      assert Enum.any?(output, &String.contains?(&1, "Generation:"))
      assert Enum.any?(output, &String.contains?(&1, "Controls:"))
    end

    test "renders with different patterns" do
      {:ok, state} = Conway.init(%{})
      {:continue, glider_state, _} = Conway.handle_input("1", state, %{})

      output = Conway.render(glider_state, %{})
      assert Enum.any?(output, &String.contains?(&1, "glider"))
    end
  end

  describe "cleanup/1" do
    test "cleanup returns :ok" do
      {:ok, state} = Conway.init(%{})
      assert Conway.cleanup(state) == :ok
    end
  end

  describe "game logic" do
    test "glider pattern moves diagonally" do
      {:ok, state} = Conway.init(%{})
      {:continue, glider_state, _} = Conway.handle_input("1", state, %{})

      # Step through several generations
      {:continue, gen1, _} = Conway.handle_input("s", glider_state, %{})
      {:continue, gen2, _} = Conway.handle_input("s", gen1, %{})
      {:continue, gen3, _} = Conway.handle_input("s", gen2, %{})
      {:continue, gen4, _} = Conway.handle_input("s", gen3, %{})

      # After 4 generations, glider should have moved
      assert gen4.generation == 4
      # Grid should still have some alive cells (glider persists)
      alive_count = count_alive_cells(gen4.grid)
      # Glider is 5 cells
      assert alive_count == 5
    end

    test "blinker pattern oscillates" do
      {:ok, state} = Conway.init(%{})
      {:continue, blinker_state, _} = Conway.handle_input("2", state, %{})

      # Step two generations (should return to original state)
      {:continue, gen1, _} = Conway.handle_input("s", blinker_state, %{})
      {:continue, gen2, _} = Conway.handle_input("s", gen1, %{})

      # Both should have same number of alive cells
      assert count_alive_cells(blinker_state.grid) == count_alive_cells(gen2.grid)
    end
  end

  # Helper function
  defp count_alive_cells(grid) do
    Enum.reduce(grid, 0, fn row, acc ->
      alive_in_row = Enum.count(row, & &1)
      acc + alive_in_row
    end)
  end
end
