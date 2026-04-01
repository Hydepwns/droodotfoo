defmodule Droodotfoo.Plugins.TypingTestTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.Plugins.TypingTest

  describe "metadata/0" do
    test "returns correct plugin metadata" do
      meta = TypingTest.metadata()

      assert meta.name == "typing_test"
      assert meta.version == "1.0.0"
      assert meta.category == :game
      assert "typing" in meta.commands
      assert "type" in meta.commands
      assert "wpm" in meta.commands
    end
  end

  describe "init/1" do
    test "initializes with sample text" do
      {:ok, state} = TypingTest.init(%{})

      assert is_binary(state.text)
      assert String.length(state.text) > 0
      assert state.typed == ""
      assert state.started == false
      assert state.start_time == nil
      assert state.end_time == nil
      assert state.errors == 0
      assert state.finished == false
      assert state.current_sample == state.text
    end
  end

  describe "handle_input/3" do
    setup do
      # Use a fixed text for testing
      state = %TypingTest{
        text: "hello world",
        typed: "",
        started: false,
        start_time: nil,
        end_time: nil,
        errors: 0,
        finished: false,
        current_sample: "hello world"
      }

      {:ok, state: state}
    end

    test "typing first character starts the timer", %{state: state} do
      {:continue, new_state, _output} = TypingTest.handle_input("h", state, %{})

      assert new_state.started == true
      assert new_state.start_time != nil
      assert new_state.typed == "h"
      assert new_state.errors == 0
    end

    test "typing correct characters updates typed text", %{state: state} do
      {:continue, state1, _} = TypingTest.handle_input("h", state, %{})
      {:continue, state2, _} = TypingTest.handle_input("e", state1, %{})
      {:continue, state3, _} = TypingTest.handle_input("l", state2, %{})

      assert state3.typed == "hel"
      assert state3.errors == 0
    end

    test "typing incorrect character increments errors", %{state: state} do
      {:continue, state1, _} = TypingTest.handle_input("h", state, %{})
      {:continue, state2, _} = TypingTest.handle_input("x", state1, %{})

      assert state2.typed == "hx"
      assert state2.errors == 1
    end

    test "backspace deletes last character", %{state: state} do
      {:continue, state1, _} = TypingTest.handle_input("h", state, %{})
      {:continue, state2, _} = TypingTest.handle_input("e", state1, %{})
      {:continue, state3, _} = TypingTest.handle_input("Backspace", state2, %{})

      assert state3.typed == "h"
    end

    test "backspace on empty string does nothing", %{state: state} do
      {:continue, new_state, _} = TypingTest.handle_input("Backspace", state, %{})

      assert new_state.typed == ""
    end

    test "completing text sets finished flag", %{state: state} do
      # Type the entire text
      chars = String.graphemes("hello world")

      final_state =
        Enum.reduce(chars, state, fn char, acc_state ->
          {:continue, new_state, _} = TypingTest.handle_input(char, acc_state, %{})
          new_state
        end)

      assert final_state.finished == true
      assert final_state.end_time != nil
      assert final_state.typed == "hello world"
    end

    test "escape restarts test with new sample", %{state: state} do
      # Type some characters
      {:continue, state1, _} = TypingTest.handle_input("h", state, %{})
      {:continue, state2, _} = TypingTest.handle_input("e", state1, %{})

      # Restart
      {:continue, new_state, _} = TypingTest.handle_input("Escape", state2, %{})

      assert new_state.typed == ""
      assert new_state.started == false
      assert new_state.start_time == nil
      assert new_state.errors == 0
      assert new_state.finished == false
      # Text should be one of the sample texts
      assert is_binary(new_state.text)
    end

    test "q exits when not started", %{state: state} do
      {:exit, _output} = TypingTest.handle_input("q", state, %{})
    end

    test "q does not exit when typing has started", %{state: state} do
      {:continue, started_state, _} = TypingTest.handle_input("h", state, %{})
      {:continue, new_state, _} = TypingTest.handle_input("q", started_state, %{})

      # Should continue instead of exit
      assert new_state.started == true
    end

    test "cannot type more after finishing", %{state: state} do
      # Complete the text
      chars = String.graphemes("hello world")

      finished_state =
        Enum.reduce(chars, state, fn char, acc_state ->
          {:continue, new_state, _} = TypingTest.handle_input(char, acc_state, %{})
          new_state
        end)

      # Try to type more
      {:continue, final_state, _} = TypingTest.handle_input("x", finished_state, %{})

      assert final_state.typed == "hello world"
      assert final_state.finished == true
    end

    test "multi-character keys are ignored", %{state: state} do
      {:continue, new_state, _} = TypingTest.handle_input("ArrowUp", state, %{})

      assert new_state.typed == ""
      assert new_state.started == false
    end
  end

  describe "render/2" do
    test "renders initial state" do
      {:ok, state} = TypingTest.init(%{})
      output = TypingTest.render(state, %{})

      assert is_list(output)
      assert Enum.any?(output, &String.contains?(&1, "TYPING SPEED TEST"))
      assert Enum.any?(output, &String.contains?(&1, "WPM:"))
      assert Enum.any?(output, &String.contains?(&1, "Accuracy:"))
      assert Enum.any?(output, &String.contains?(&1, "Controls:"))
    end

    test "renders in progress state" do
      state = %TypingTest{
        text: "test",
        typed: "te",
        started: true,
        start_time: System.monotonic_time(:millisecond) - 1000,
        end_time: nil,
        errors: 0,
        finished: false,
        current_sample: "test"
      }

      output = TypingTest.render(state, %{})

      assert Enum.any?(output, &String.contains?(&1, "TYPING..."))
    end

    test "renders completed state" do
      state = %TypingTest{
        text: "test",
        typed: "test",
        started: true,
        start_time: System.monotonic_time(:millisecond) - 5000,
        end_time: System.monotonic_time(:millisecond),
        errors: 0,
        finished: true,
        current_sample: "test"
      }

      output = TypingTest.render(state, %{})

      assert Enum.any?(output, &String.contains?(&1, "COMPLETED!"))
    end
  end

  describe "cleanup/1" do
    test "cleanup returns :ok" do
      {:ok, state} = TypingTest.init(%{})
      assert TypingTest.cleanup(state) == :ok
    end
  end

  describe "statistics calculation" do
    test "calculates WPM correctly" do
      # Create state with specific timing
      start_time = System.monotonic_time(:millisecond)
      # Simulate 60 seconds elapsed
      end_time = start_time + 60_000

      # 50 characters in 60 seconds = 10 words = 10 WPM
      state = %TypingTest{
        text: String.duplicate("a", 50),
        typed: String.duplicate("a", 50),
        started: true,
        start_time: start_time,
        end_time: end_time,
        errors: 0,
        finished: true,
        current_sample: String.duplicate("a", 50)
      }

      output = TypingTest.render(state, %{})
      output_str = Enum.join(output, "\n")

      # Should show 10 WPM (50 chars / 5 chars per word / 1 minute)
      assert String.contains?(output_str, "10.0")
    end

    test "calculates accuracy correctly with errors" do
      state = %TypingTest{
        text: "hello",
        typed: "hello",
        started: true,
        start_time: System.monotonic_time(:millisecond) - 1000,
        end_time: System.monotonic_time(:millisecond),
        errors: 1,
        finished: true,
        current_sample: "hello"
      }

      output = TypingTest.render(state, %{})
      output_str = Enum.join(output, "\n")

      # 4 correct out of 5 = 80%
      assert String.contains?(output_str, "80.0%")
    end

    test "shows 100% accuracy with no errors" do
      state = %TypingTest{
        text: "hello",
        typed: "hello",
        started: true,
        start_time: System.monotonic_time(:millisecond) - 1000,
        end_time: System.monotonic_time(:millisecond),
        errors: 0,
        finished: true,
        current_sample: "hello"
      }

      output = TypingTest.render(state, %{})
      output_str = Enum.join(output, "\n")

      assert String.contains?(output_str, "100.0%")
    end
  end
end
