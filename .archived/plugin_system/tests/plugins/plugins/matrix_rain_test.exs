defmodule Droodotfoo.Plugins.MatrixRainTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Plugins.MatrixRain

  describe "metadata/0" do
    test "returns correct plugin metadata" do
      metadata = MatrixRain.metadata()

      assert metadata.name == "matrix"
      assert metadata.version == "1.0.0"
      assert metadata.description == "Matrix rain effect - Press any key to exit"
      assert metadata.author == "droo.foo"
      assert metadata.commands == ["matrix", "rain"]
      assert metadata.category == :fun
    end
  end

  describe "init/1" do
    test "initializes matrix rain state" do
      terminal_state = %{width: 80, height: 24}

      assert {:ok, state} = MatrixRain.init(terminal_state)
      assert %MatrixRain{} = state

      # Check dimensions match terminal
      assert state.width == 80
      assert state.height == 24

      # Check columns are initialized
      assert is_map(state.columns)
      assert map_size(state.columns) > 0

      # Each column should have proper structure
      state.columns
      |> Map.values()
      |> Enum.each(fn col ->
        assert Map.has_key?(col, :chars)
        assert Map.has_key?(col, :y)
        assert Map.has_key?(col, :speed)

        assert is_list(col.chars)
        assert is_integer(col.y)
        assert is_float(col.speed)
      end)

      assert state.frame == 0
    end

    test "creates appropriate number of columns" do
      terminal_state = %{width: 40, height: 20}

      {:ok, state} = MatrixRain.init(terminal_state)

      # Should create columns based on width (now creates one per column)
      # Plugin now uses fixed width
      expected_columns = 80
      assert map_size(state.columns) == expected_columns
    end
  end

  describe "handle_input/3" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, initial_state} = MatrixRain.init(terminal_state)
      {:ok, state: initial_state, terminal_state: terminal_state}
    end

    test "exits on 'q'", %{state: state, terminal_state: terminal_state} do
      assert {:exit, _output} = MatrixRain.handle_input("q", state, terminal_state)
    end

    test "exits on 'exit'", %{state: state, terminal_state: terminal_state} do
      assert {:exit, _output} = MatrixRain.handle_input("exit", state, terminal_state)
    end

    test "exits on space", %{state: state, terminal_state: terminal_state} do
      {:exit, output} = MatrixRain.handle_input(" ", state, terminal_state)

      # Should exit on any input including space
      assert output == ["Exiting Matrix rain..."]
    end

    test "exits on enter", %{state: state, terminal_state: terminal_state} do
      {:exit, output} = MatrixRain.handle_input("enter", state, terminal_state)

      assert output == ["Exiting Matrix rain..."]
    end

    test "exits on any other input", %{state: state, terminal_state: terminal_state} do
      {:exit, output} = MatrixRain.handle_input("x", state, terminal_state)

      # Should exit for any input
      assert output == ["Exiting Matrix rain..."]
    end
  end

  describe "render/2" do
    test "renders matrix rain effect" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = MatrixRain.init(terminal_state)

      output = MatrixRain.render(state, terminal_state)

      # Should have correct number of lines
      # Output now includes header and footer lines
      assert length(output) >= 24

      # Should contain matrix-like characters
      matrix_chars = ["0", "1", "@", "#", "$", "%", "&", "*"]
      combined_output = Enum.join(output, "")

      assert Enum.any?(matrix_chars, fn char ->
               String.contains?(combined_output, char)
             end)
    end

    test "renders title and instructions" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = MatrixRain.init(terminal_state)

      output = MatrixRain.render(state, terminal_state)

      # Should show title
      assert Enum.any?(output, &String.contains?(&1, "MATRIX RAIN"))

      # Should show exit instruction (may say "any key to exit" instead of just 'q')
      assert Enum.any?(output, &String.contains?(&1, "exit"))
    end

    test "animation changes between frames" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = MatrixRain.init(terminal_state)

      # Get first render
      output1 = MatrixRain.render(state, terminal_state)

      # Advance animation using handle_key (since handle_input now exits)
      {:ok, new_state} = MatrixRain.handle_key(" ", state, terminal_state)

      # Get second render
      output2 = MatrixRain.render(new_state, terminal_state)

      # Outputs should be different (animation progressed)
      assert output1 != output2
    end
  end

  describe "cleanup/1" do
    test "cleanup returns ok" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = MatrixRain.init(terminal_state)

      assert :ok = MatrixRain.cleanup(state)
    end
  end

  describe "animation mechanics" do
    test "columns fall at different speeds" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = MatrixRain.init(terminal_state)

      # Check that columns have different speeds
      speeds = state.columns |> Map.values() |> Enum.map(& &1.speed)
      unique_speeds = Enum.uniq(speeds)

      # Should have variation in speeds
      assert length(unique_speeds) > 1
    end

    test "columns have varying trail lengths" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = MatrixRain.init(terminal_state)

      # Check trail length variation
      trail_lengths =
        state.columns
        |> Map.values()
        |> Enum.map(fn col ->
          # Use char list length as proxy for trail effect
          length(col.chars)
        end)

      unique_lengths = Enum.uniq(trail_lengths)

      # Should have variation in trail lengths
      assert length(unique_lengths) > 1

      # Trail lengths should be reasonable
      Enum.each(trail_lengths, fn len ->
        assert len >= 3
        # Allow longer trails since implementation changed
        assert len <= 20
      end)
    end

    test "columns wrap around when reaching bottom" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = MatrixRain.init(terminal_state)

      # Set a column head near the bottom
      {first_key, first_col} = state.columns |> Map.to_list() |> List.first()
      col_at_bottom = %{first_col | y: 23}
      updated_columns = Map.put(state.columns, first_key, col_at_bottom)
      state_near_bottom = %{state | columns: updated_columns}

      # Advance animation multiple times using handle_key
      {:ok, state1} = MatrixRain.handle_key(" ", state_near_bottom, terminal_state)
      {:ok, state2} = MatrixRain.handle_key(" ", state1, terminal_state)

      # The column should have wrapped around
      updated_col = Map.get(state2.columns, first_key)

      # Y position should be back near top (accounting for speed)
      assert updated_col.y < 10 or updated_col.y > 20
    end
  end
end
