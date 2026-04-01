defmodule Droodotfoo.Plugins.CalculatorTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Plugins.Calculator

  describe "metadata/0" do
    test "returns correct plugin metadata" do
      metadata = Calculator.metadata()

      assert metadata.name == "calc"
      assert metadata.version == "1.0.0"
      assert metadata.description == "Calculator with standard and RPN modes"
      assert metadata.author == "droo.foo"
      assert metadata.commands == ["calc", "calculator"]
      assert metadata.category == :tool
    end
  end

  describe "init/1" do
    test "initializes calculator state" do
      terminal_state = %{width: 80, height: 24}

      assert {:ok, state} = Calculator.init(terminal_state)
      assert %Calculator{} = state
      assert state.display == "0"
      assert state.mode == :standard
      assert state.stack == []
      assert state.history == []
      assert state.memory == 0
    end
  end

  describe "handle_input/3" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, initial_state} = Calculator.init(terminal_state)
      {:ok, state: initial_state, terminal_state: terminal_state}
    end

    test "exits on 'q'", %{state: state, terminal_state: terminal_state} do
      assert {:exit, output} = Calculator.handle_input("q", state, terminal_state)
      assert Enum.any?(output, &String.contains?(&1, "Calculator closed"))
    end

    test "exits on 'quit'", %{state: state, terminal_state: terminal_state} do
      assert {:exit, _output} = Calculator.handle_input("quit", state, terminal_state)
    end

    test "switches to RPN mode", %{state: state, terminal_state: terminal_state} do
      assert state.mode == :standard
      {:continue, new_state, _output} = Calculator.handle_input("rpn", state, terminal_state)
      assert new_state.mode == :rpn
    end

    test "switches to standard mode from RPN", %{state: state, terminal_state: terminal_state} do
      # First switch to RPN
      {:continue, rpn_state, _} = Calculator.handle_input("rpn", state, terminal_state)
      assert rpn_state.mode == :rpn

      # Then switch back to standard
      {:continue, std_state, _} = Calculator.handle_input("std", rpn_state, terminal_state)
      assert std_state.mode == :standard
    end

    test "clears display with 'c'", %{state: state, terminal_state: terminal_state} do
      # Set some state
      state_with_data = %{state | display: "42", stack: [1, 2, 3]}

      {:continue, cleared_state, _} =
        Calculator.handle_input("c", state_with_data, terminal_state)

      assert cleared_state.display == "0"
      assert cleared_state.stack == []
    end

    test "clears display with 'clear'", %{state: state, terminal_state: terminal_state} do
      state_with_data = %{state | display: "42"}

      {:continue, cleared_state, _} =
        Calculator.handle_input("clear", state_with_data, terminal_state)

      assert cleared_state.display == "0"
    end

    test "shows help", %{state: state, terminal_state: terminal_state} do
      {:continue, same_state, output} = Calculator.handle_input("help", state, terminal_state)

      # State shouldn't change
      assert same_state == state

      # Output should contain help text
      combined = Enum.join(output, "\n")
      assert String.contains?(combined, "HELP")
    end
  end

  describe "standard mode" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, initial_state} = Calculator.init(terminal_state)
      {:ok, state: initial_state, terminal_state: terminal_state}
    end

    test "evaluates simple addition", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _} = Calculator.handle_input("2 + 2", state, terminal_state)
      # Whole numbers display without .0
      assert new_state.display == "4"
      assert List.first(new_state.history) == "2 + 2 = 4"
    end

    test "evaluates subtraction", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _} = Calculator.handle_input("10 - 3", state, terminal_state)
      assert new_state.display == "7"
    end

    test "evaluates multiplication", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _} = Calculator.handle_input("6 * 7", state, terminal_state)
      assert new_state.display == "42"
    end

    test "evaluates division", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _} = Calculator.handle_input("15 / 3", state, terminal_state)
      assert new_state.display == "5"
    end

    test "handles order of operations", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _} = Calculator.handle_input("3 + 4 * 2", state, terminal_state)
      # Should respect order of operations: 3 + (4 * 2) = 3 + 8 = 11
      assert new_state.display == "11"
    end

    test "handles invalid expressions", %{state: state, terminal_state: terminal_state} do
      {:continue, same_state, output} = Calculator.handle_input("2 ++ 2", state, terminal_state)

      # State shouldn't change on error
      assert same_state == state

      # Should show error message
      assert Enum.any?(output, &String.contains?(&1, "Error"))
    end

    test "maintains history", %{state: state, terminal_state: terminal_state} do
      {:continue, state1, _} = Calculator.handle_input("2 + 2", state, terminal_state)
      {:continue, state2, _} = Calculator.handle_input("3 * 4", state1, terminal_state)

      assert length(state2.history) == 2
      assert "2 + 2 = 4" in state2.history
      assert "3 * 4 = 12" in state2.history
    end
  end

  describe "RPN mode" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, initial_state} = Calculator.init(terminal_state)
      {:continue, rpn_state, _} = Calculator.handle_input("rpn", initial_state, terminal_state)
      {:ok, state: rpn_state, terminal_state: terminal_state}
    end

    test "pushes numbers to stack", %{state: state, terminal_state: terminal_state} do
      {:continue, state1, _} = Calculator.handle_input("5", state, terminal_state)
      assert state1.stack == [5.0]

      {:continue, state2, _} = Calculator.handle_input("3", state1, terminal_state)
      assert state2.stack == [3.0, 5.0]
    end

    test "performs addition", %{state: state, terminal_state: terminal_state} do
      {:continue, state1, _} = Calculator.handle_input("5", state, terminal_state)
      {:continue, state2, _} = Calculator.handle_input("3", state1, terminal_state)
      {:continue, state3, _} = Calculator.handle_input("+", state2, terminal_state)

      # RPN operations also return integers when possible
      assert state3.stack == [8]
    end

    test "performs subtraction", %{state: state, terminal_state: terminal_state} do
      {:continue, state1, _} = Calculator.handle_input("10", state, terminal_state)
      {:continue, state2, _} = Calculator.handle_input("3", state1, terminal_state)
      {:continue, state3, _} = Calculator.handle_input("-", state2, terminal_state)

      assert state3.stack == [7]
    end

    test "performs multiplication", %{state: state, terminal_state: terminal_state} do
      {:continue, state1, _} = Calculator.handle_input("6", state, terminal_state)
      {:continue, state2, _} = Calculator.handle_input("7", state1, terminal_state)
      {:continue, state3, _} = Calculator.handle_input("*", state2, terminal_state)

      assert state3.stack == [42]
    end

    test "performs division", %{state: state, terminal_state: terminal_state} do
      {:continue, state1, _} = Calculator.handle_input("15", state, terminal_state)
      {:continue, state2, _} = Calculator.handle_input("3", state1, terminal_state)
      {:continue, state3, _} = Calculator.handle_input("/", state2, terminal_state)

      assert state3.stack == [5]
    end

    test "handles insufficient operands", %{state: state, terminal_state: terminal_state} do
      # Only one number on stack
      {:continue, state1, _} = Calculator.handle_input("5", state, terminal_state)
      {:continue, state2, output} = Calculator.handle_input("+", state1, terminal_state)

      # Stack should be unchanged
      assert state2.stack == [5.0]

      # Should show error
      assert Enum.any?(output, &String.contains?(&1, "Error"))
    end

    test "complex RPN calculation", %{state: state, terminal_state: terminal_state} do
      # Calculate: (3 + 4) * 2 = 14
      # RPN: 3 4 + 2 *
      {:continue, s1, _} = Calculator.handle_input("3", state, terminal_state)
      {:continue, s2, _} = Calculator.handle_input("4", s1, terminal_state)
      {:continue, s3, _} = Calculator.handle_input("+", s2, terminal_state)
      {:continue, s4, _} = Calculator.handle_input("2", s3, terminal_state)
      {:continue, s5, _} = Calculator.handle_input("*", s4, terminal_state)

      assert s5.stack == [14]
    end
  end

  describe "render/2" do
    test "renders standard mode display" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = Calculator.init(terminal_state)

      output = Calculator.render(state, terminal_state)

      assert Enum.any?(output, &String.contains?(&1, "CALCULATOR"))
      assert Enum.any?(output, &String.contains?(&1, "Mode: STANDARD"))
      assert Enum.any?(output, &String.contains?(&1, "Display: 0"))
    end

    test "renders RPN mode with stack" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = Calculator.init(terminal_state)
      rpn_state = %{state | mode: :rpn, stack: [3.0, 7.0, 12.0]}

      output = Calculator.render(rpn_state, terminal_state)

      assert Enum.any?(output, &String.contains?(&1, "Mode: RPN"))
      assert Enum.any?(output, &String.contains?(&1, "Stack:"))
      # Stack is shown in reverse order
      combined = Enum.join(output, "\n")
      assert String.contains?(combined, "12.0")
      assert String.contains?(combined, "7.0")
      assert String.contains?(combined, "3.0")
    end

    test "renders history" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = Calculator.init(terminal_state)
      state_with_history = %{state | history: ["2 + 2 = 4", "3 * 3 = 9"]}

      output = Calculator.render(state_with_history, terminal_state)
      combined = Enum.join(output, "\n")

      assert String.contains?(combined, "Recent:")
      assert String.contains?(combined, "2 + 2 = 4")
      assert String.contains?(combined, "3 * 3 = 9")
    end
  end

  describe "cleanup/1" do
    test "cleanup returns ok" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = Calculator.init(terminal_state)

      assert :ok = Calculator.cleanup(state)
    end
  end
end
