defmodule Droodotfoo.Plugins.Wordle.GameLogic do
  @moduledoc """
  Game logic for Wordle.
  Handles guess submission and game state management.
  """

  alias Droodotfoo.Plugins.Wordle.WordList

  @word_length 5

  @doc """
  Check if a word is valid (exists in word list).
  """
  def valid_word?(word), do: WordList.valid?(word)

  @doc """
  Submit a guess and update game state.
  Returns the new state with the guess added and game_over/won flags updated.
  """
  def submit_guess(state) do
    new_guesses = state.guesses ++ [state.current_guess]
    won = state.current_guess == state.target_word
    game_over = won or length(new_guesses) >= state.max_guesses

    %{state | guesses: new_guesses, current_guess: "", won: won, game_over: game_over}
  end

  @doc """
  Check if the game is blocked (game over, can't accept more input).
  """
  def game_blocked?(state), do: state.game_over

  @doc """
  Get the word length for the game.
  """
  def word_length, do: @word_length
end
