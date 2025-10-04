defmodule Droodotfoo.Plugins.WordleTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.Plugins.Wordle

  describe "metadata/0" do
    test "returns correct plugin metadata" do
      meta = Wordle.metadata()

      assert meta.name == "wordle"
      assert meta.version == "1.0.0"
      assert meta.category == :game
      assert "wordle" in meta.commands
    end
  end

  describe "init/1" do
    test "initializes with a target word" do
      {:ok, state} = Wordle.init(%{})

      assert is_binary(state.target_word)
      assert String.length(state.target_word) == 5
    end

    test "initializes with empty guesses" do
      {:ok, state} = Wordle.init(%{})

      assert state.guesses == []
      assert state.current_guess == ""
    end

    test "initializes not game over" do
      {:ok, state} = Wordle.init(%{})

      assert state.game_over == false
      assert state.won == false
    end

    test "sets max guesses to 6" do
      {:ok, state} = Wordle.init(%{})

      assert state.max_guesses == 6
    end

    test "target word is from word list" do
      {:ok, state} = Wordle.init(%{})

      # The target word should be a valid English word
      assert String.match?(state.target_word, ~r/^[a-z]{5}$/)
    end
  end

  describe "handle_input/3 - letter input" do
    setup do
      {:ok, state} = Wordle.init(%{})
      {:ok, state: state}
    end

    test "accepts single letters", %{state: state} do
      {:continue, new_state, _output} = Wordle.handle_input("a", state, %{})

      assert new_state.current_guess == "a"
    end

    test "builds up a guess with multiple letters", %{state: state} do
      {:continue, state1, _} = Wordle.handle_input("h", state, %{})
      {:continue, state2, _} = Wordle.handle_input("e", state1, %{})
      {:continue, state3, _} = Wordle.handle_input("l", state2, %{})
      {:continue, state4, _} = Wordle.handle_input("l", state3, %{})
      {:continue, state5, _} = Wordle.handle_input("o", state4, %{})

      assert state5.current_guess == "hello"
    end

    test "limits guess to 5 letters", %{state: state} do
      {:continue, state1, _} = Wordle.handle_input("a", state, %{})
      {:continue, state2, _} = Wordle.handle_input("b", state1, %{})
      {:continue, state3, _} = Wordle.handle_input("c", state2, %{})
      {:continue, state4, _} = Wordle.handle_input("d", state3, %{})
      {:continue, state5, _} = Wordle.handle_input("e", state4, %{})
      {:continue, state6, _} = Wordle.handle_input("f", state5, %{})

      assert String.length(state6.current_guess) == 5
      assert state6.current_guess == "abcde"
    end

    test "converts uppercase to lowercase", %{state: state} do
      {:continue, new_state, _output} = Wordle.handle_input("A", state, %{})

      assert new_state.current_guess == "a"
    end

    test "ignores non-letter input", %{state: state} do
      {:continue, new_state, _output} = Wordle.handle_input("1", state, %{})

      assert new_state.current_guess == ""
    end

    test "input ignored when game over", %{state: state} do
      game_over_state = %{state | game_over: true}

      {:continue, new_state, _output} = Wordle.handle_input("a", game_over_state, %{})

      assert new_state.current_guess == ""
    end
  end

  describe "handle_input/3 - backspace" do
    setup do
      {:ok, state} = Wordle.init(%{})
      {:ok, state: state}
    end

    test "removes last letter", %{state: state} do
      state_with_guess = %{state | current_guess: "hello"}

      {:continue, new_state, _output} = Wordle.handle_input("Backspace", state_with_guess, %{})

      assert new_state.current_guess == "hell"
    end

    test "does nothing on empty guess", %{state: state} do
      {:continue, new_state, _output} = Wordle.handle_input("Backspace", state, %{})

      assert new_state.current_guess == ""
    end

    test "backspace ignored when game over", %{state: state} do
      game_over_state = %{state | game_over: true, current_guess: "hello"}

      {:continue, new_state, _output} = Wordle.handle_input("Backspace", game_over_state, %{})

      assert new_state.current_guess == "hello"
    end
  end

  describe "handle_input/3 - submit guess" do
    setup do
      {:ok, state} = Wordle.init(%{})
      # Set a known target word for testing (must be in word list)
      state_with_target = %{state | target_word: "world"}
      {:ok, state: state_with_target}
    end

    test "submits valid 5-letter guess", %{state: state} do
      state_with_guess = %{state | current_guess: "world"}

      {:continue, new_state, _output} = Wordle.handle_input("Enter", state_with_guess, %{})

      assert length(new_state.guesses) == 1
      assert "world" in new_state.guesses
      assert new_state.current_guess == ""
    end

    test "does not submit if guess is incomplete", %{state: state} do
      state_with_guess = %{state | current_guess: "wor"}

      {:continue, new_state, _output} = Wordle.handle_input("Enter", state_with_guess, %{})

      assert length(new_state.guesses) == 0
      assert new_state.current_guess == "wor"
    end

    test "does not submit invalid word", %{state: state} do
      state_with_guess = %{state | current_guess: "zzzzz"}

      {:continue, new_state, _output} = Wordle.handle_input("Enter", state_with_guess, %{})

      # Should not add to guesses
      assert length(new_state.guesses) == 0
      assert new_state.current_guess == "zzzzz"
    end

    test "detects win when guessing correct word", %{state: state} do
      state_with_guess = %{state | current_guess: "world"}

      {:continue, new_state, _output} = Wordle.handle_input("Enter", state_with_guess, %{})

      assert new_state.won == true
      assert new_state.game_over == true
    end

    test "detects game over after 6 guesses", %{state: state} do
      # Make 5 incorrect guesses
      state_with_guesses = %{state | guesses: ["world", "earth", "brain", "smile", "track"]}
      state_with_final = %{state_with_guesses | current_guess: "wrong"}

      {:continue, new_state, _output} = Wordle.handle_input("Enter", state_with_final, %{})

      assert new_state.game_over == true
      assert new_state.won == false
      assert length(new_state.guesses) == 6
    end

    test "enter ignored when game over", %{state: state} do
      game_over_state = %{state | game_over: true, current_guess: "hello"}
      initial_guesses = game_over_state.guesses

      {:continue, new_state, _output} = Wordle.handle_input("Enter", game_over_state, %{})

      assert new_state.guesses == initial_guesses
    end
  end

  describe "handle_input/3 - game controls" do
    setup do
      {:ok, state} = Wordle.init(%{})
      {:ok, state: state}
    end

    test "r starts new game", %{state: state} do
      state_with_guesses = %{state | guesses: ["hello", "world"], current_guess: "abc"}

      {:continue, new_state, _output} = Wordle.handle_input("r", state_with_guesses, %{})

      assert new_state.guesses == []
      assert new_state.current_guess == ""
      assert new_state.game_over == false
    end

    test "q exits the game", %{state: state} do
      {:exit, _output} = Wordle.handle_input("q", state, %{})
    end
  end

  describe "render/2" do
    test "renders game board with headers" do
      {:ok, state} = Wordle.init(%{})
      output = Wordle.render(state, %{})

      assert is_list(output)
      assert Enum.any?(output, &String.contains?(&1, "WORDLE"))
      assert Enum.any?(output, &String.contains?(&1, "Guess"))
      assert Enum.any?(output, &String.contains?(&1, "q: Quit"))
    end

    test "renders current guess" do
      {:ok, state} = Wordle.init(%{})
      state_with_guess = %{state | current_guess: "hel"}
      output = Wordle.render(state_with_guess, %{})

      output_str = Enum.join(output, "\n")
      assert String.contains?(output_str, "H")
      assert String.contains?(output_str, "E")
      assert String.contains?(output_str, "L")
    end

    test "renders submitted guesses" do
      {:ok, state} = Wordle.init(%{})
      state_with_guesses = %{state | guesses: ["hello"], target_word: "world"}
      output = Wordle.render(state_with_guesses, %{})

      output_str = Enum.join(output, "\n")
      assert String.contains?(output_str, "H")
    end

    test "renders YOU WIN status when won" do
      {:ok, state} = Wordle.init(%{})
      won_state = %{state | won: true, game_over: true}
      output = Wordle.render(won_state, %{})

      assert Enum.any?(output, &String.contains?(&1, "YOU WIN"))
    end

    test "renders GAME OVER status when game over" do
      {:ok, state} = Wordle.init(%{})
      game_over_state = %{state | game_over: true, won: false, target_word: "hello"}
      output = Wordle.render(game_over_state, %{})

      assert Enum.any?(output, &String.contains?(&1, "GAME OVER"))
      assert Enum.any?(output, &String.contains?(&1, "HELLO"))
    end

    test "shows guess count" do
      {:ok, state} = Wordle.init(%{})
      state_with_guesses = %{state | guesses: ["hello", "world"]}
      output = Wordle.render(state_with_guesses, %{})

      assert Enum.any?(output, &String.contains?(&1, "Guess 3/6"))
    end
  end

  describe "cleanup/1" do
    test "cleanup returns :ok" do
      {:ok, state} = Wordle.init(%{})
      assert Wordle.cleanup(state) == :ok
    end
  end

  describe "game logic - word validation" do
    test "accepts valid 5-letter words" do
      {:ok, state} = Wordle.init(%{})
      state_with_guess = %{state | current_guess: "world"}

      {:continue, new_state, _output} = Wordle.handle_input("Enter", state_with_guess, %{})

      assert "world" in new_state.guesses
    end

    test "rejects invalid words" do
      {:ok, state} = Wordle.init(%{})
      state_with_guess = %{state | current_guess: "zzzzz"}

      {:continue, new_state, _output} = Wordle.handle_input("Enter", state_with_guess, %{})

      assert new_state.guesses == []
    end
  end

  describe "game logic - letter feedback" do
    setup do
      {:ok, state} = Wordle.init(%{})
      # Use a known word for predictable testing (must be in word list)
      state_with_target = %{state | target_word: "world"}
      {:ok, state: state_with_target}
    end

    test "tracks guess history", %{state: state} do
      state_with_guess1 = %{state | current_guess: "about"}
      {:continue, state1, _} = Wordle.handle_input("Enter", state_with_guess1, %{})

      state_with_guess2 = %{state1 | current_guess: "earth"}
      {:continue, state2, _} = Wordle.handle_input("Enter", state_with_guess2, %{})

      assert length(state2.guesses) == 2
      assert state2.guesses == ["about", "earth"]
    end

    test "maintains game state across guesses", %{state: state} do
      # Make a few guesses
      {:continue, state1, _} = Wordle.handle_input("h", state, %{})
      {:continue, state2, _} = Wordle.handle_input("a", state1, %{})
      {:continue, state3, _} = Wordle.handle_input("p", state2, %{})
      {:continue, state4, _} = Wordle.handle_input("p", state3, %{})
      {:continue, state5, _} = Wordle.handle_input("y", state4, %{})

      assert state5.current_guess == "happy"
      assert state5.game_over == false
    end
  end
end
