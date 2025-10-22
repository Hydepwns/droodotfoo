defmodule Droodotfoo.Plugins.Wordle do
  @moduledoc """
  Wordle - Guess the 5-letter word in 6 attempts.

  Color coding:
  - █ : Correct letter in correct position
  - * : Correct letter in wrong position
  -   : Letter not in word

  Controls:
  - Type letters to build your guess
  - Enter: Submit guess
  - Backspace: Delete last letter
  - r: New word
  - q: Quit

  This module has been refactored into focused submodules:
  - WordList - Word list management and validation
  - GameLogic - Game state and guess submission logic
  - Renderer - All rendering functions
  """

  use Droodotfoo.Plugins.GameBase
  alias Droodotfoo.Plugins.Wordle.{GameLogic, Renderer, WordList}

  defstruct [
    :target_word,
    :guesses,
    :current_guess,
    :game_over,
    :won,
    :max_guesses
  ]

  @max_guesses 6

  @impl true
  def metadata do
    game_metadata(
      "wordle",
      "1.0.0",
      "Wordle - Guess the 5-letter word in 6 attempts",
      "droo.foo",
      ["wordle"]
    )
  end

  @impl true
  def init(_terminal_state) do
    {:ok,
     %__MODULE__{
       target_word: WordList.random(),
       guesses: [],
       current_guess: "",
       game_over: false,
       won: false,
       max_guesses: @max_guesses
     }}
  end

  @impl true
  def handle_input("Enter", state, _terminal_state) do
    if GameLogic.game_blocked?(state) do
      {:continue, state, Renderer.render_game(state, nil)}
    else
      handle_enter_guess(state)
    end
  end

  def handle_input("Backspace", state, _terminal_state) do
    if GameLogic.game_blocked?(state) do
      {:continue, state, Renderer.render_game(state, nil)}
    else
      new_guess = String.slice(state.current_guess, 0..-2//1)
      new_state = %{state | current_guess: new_guess}
      {:continue, new_state, Renderer.render_game(new_state, nil)}
    end
  end

  def handle_input("r", _state, terminal_state) do
    handle_restart(__MODULE__, terminal_state)
  end

  def handle_input("q", _state, _terminal_state) do
    {:exit, ["Exiting Wordle"]}
  end

  def handle_input(key, state, _terminal_state) do
    if GameLogic.game_blocked?(state) do
      {:continue, state, Renderer.render_game(state, nil)}
    else
      # Check if it's a letter
      if String.match?(key, ~r/^[a-zA-Z]$/) and
           String.length(state.current_guess) < GameLogic.word_length() do
        new_guess = state.current_guess <> String.downcase(key)
        new_state = %{state | current_guess: new_guess}
        {:continue, new_state, Renderer.render_game(new_state, nil)}
      else
        {:continue, state, Renderer.render_game(state, nil)}
      end
    end
  end

  @impl true
  def render(state, _terminal_state) do
    Renderer.render_game(state, nil)
  end

  @impl true
  def cleanup(_state) do
    :ok
  end

  # Private helper functions

  defp handle_enter_guess(state) do
    if String.length(state.current_guess) == GameLogic.word_length() do
      validate_and_submit_guess(state)
    else
      {:continue, state, Renderer.render_game(state, nil)}
    end
  end

  defp validate_and_submit_guess(state) do
    if GameLogic.valid_word?(state.current_guess) do
      new_state = GameLogic.submit_guess(state)
      {:continue, new_state, Renderer.render_game(new_state, nil)}
    else
      {:continue, state, Renderer.render_game(state, "Not a valid word")}
    end
  end
end
