defmodule Droodotfoo.Plugins.Wordle.Renderer do
  @moduledoc """
  Rendering functions for Wordle game.
  Handles all UI rendering including guesses, current input, and game status.
  """

  alias Droodotfoo.Plugins.GameUI
  alias Droodotfoo.Plugins.Wordle.GameLogic

  @word_length 5

  @doc """
  Render the complete game UI.
  """
  def render_game(state, error_message) do
    status =
      cond do
        state.won -> GameUI.format_status(:won)
        state.game_over -> "GAME OVER - Word was: #{String.upcase(state.target_word)}"
        true -> "Guess #{length(state.guesses) + 1}/#{state.max_guesses}"
      end

    guess_rows = render_guesses(state)
    current_row = render_current_guess(state)
    width = 61

    lines =
      [
        GameUI.top_border(width),
        GameUI.title_line("WORDLE", width),
        GameUI.divider(width),
        GameUI.empty_line(width),
        GameUI.content_line(status, width),
        GameUI.empty_line(width)
      ] ++
        guess_rows ++
        [current_row] ++
        render_empty_rows(state) ++
        [
          GameUI.empty_line(width)
        ] ++
        if error_message do
          [GameUI.content_line("Error: #{error_message}", width)]
        else
          []
        end ++
        [
          GameUI.empty_line(width),
          GameUI.content_line("█ = Right letter, right spot", width),
          GameUI.content_line("* = Right letter, wrong spot", width),
          GameUI.empty_line(width),
          GameUI.content_line("Type your guess and press Enter", width),
          GameUI.content_line("r: New word  q: Quit", width),
          GameUI.empty_line(width),
          GameUI.bottom_border(width)
        ]

    lines
  end

  @doc """
  Render all submitted guesses.
  """
  def render_guesses(state) do
    Enum.map(state.guesses, fn guess ->
      render_guess_row(guess, state.target_word)
    end)
  end

  @doc """
  Render a single guess row with color coding.
  """
  def render_guess_row(guess, target_word) do
    guess_chars = String.graphemes(guess)
    target_chars = String.graphemes(target_word)

    colored_chars =
      Enum.with_index(guess_chars, fn char, idx ->
        target_char = Enum.at(target_chars, idx)

        cond do
          # Correct position
          char == target_char -> "█"
          # Wrong position
          char in target_chars -> "*"
          # Not in word
          true -> " "
        end
      end)

    guess_display =
      guess_chars
      |> Enum.zip(colored_chars)
      |> Enum.map_join(" ", fn {letter, marker} ->
        "#{String.upcase(letter)}#{marker}"
      end)

    "║    #{String.pad_trailing(guess_display, 52)} ║"
  end

  @doc """
  Render the current guess being typed.
  """
  def render_current_guess(state) do
    if GameLogic.game_blocked?(state) do
      "║                                                            ║"
    else
      guess_display =
        state.current_guess
        |> String.graphemes()
        |> Enum.map(&String.upcase/1)
        |> Enum.map_join(" ", fn letter -> "#{letter}_" end)

      # Add placeholders for remaining letters
      remaining = @word_length - String.length(state.current_guess)
      placeholders = List.duplicate("__", remaining) |> Enum.join(" ")

      full_display =
        if guess_display == "" do
          placeholders
        else
          guess_display <> " " <> placeholders
        end

      "║  > #{String.pad_trailing(full_display, 52)} ║"
    end
  end

  @doc """
  Render empty rows for unused guesses.
  """
  def render_empty_rows(state) do
    used_rows = length(state.guesses) + if(state.game_over, do: 0, else: 1)
    empty_count = state.max_guesses - used_rows

    for _i <- 1..empty_count do
      "║                                                            ║"
    end
  end
end
