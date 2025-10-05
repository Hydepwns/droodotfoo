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
  """

  use Droodotfoo.Plugins.GameBase
  alias Droodotfoo.Plugins.GameUI

  defstruct [
    :target_word,
    :guesses,
    :current_guess,
    :game_over,
    :won,
    :max_guesses
  ]

  @max_guesses 6
  @word_length 5

  # Common 5-letter words for the game
  @word_list [
    "about", "above", "abuse", "actor", "acute", "admit", "adopt", "adult",
    "after", "again", "agent", "agree", "ahead", "alarm", "album", "alert",
    "alien", "align", "alike", "alive", "allow", "alone", "along", "alter",
    "amber", "amuse", "angel", "anger", "angle", "angry", "apart", "apple",
    "apply", "arena", "argue", "arise", "array", "arrow", "aside", "asset",
    "audio", "avoid", "awake", "award", "aware", "badly", "baker", "bases",
    "basic", "beach", "began", "begin", "begun", "being", "below", "bench",
    "billy", "birth", "black", "blame", "blank", "blend", "blind", "block",
    "blood", "board", "boost", "booth", "bound", "brain", "brand", "bread",
    "break", "breed", "brief", "bring", "broad", "broke", "brown", "build",
    "built", "buyer", "cable", "calif", "camel", "canal", "candy", "canon",
    "cargo", "carry", "carve", "catch", "cause", "chain", "chair", "chaos",
    "charm", "chart", "chase", "cheap", "check", "chest", "chief", "child",
    "china", "chose", "civic", "civil", "claim", "class", "clean", "clear",
    "click", "cliff", "climb", "clock", "close", "cloth", "cloud", "coach",
    "coast", "could", "count", "court", "cover", "craft", "crash", "crazy",
    "cream", "crime", "cross", "crowd", "crown", "crude", "curve", "cycle",
    "daily", "dance", "dated", "dealt", "death", "debut", "delay", "delta",
    "dense", "depth", "doing", "doubt", "dozen", "draft", "drama", "drank",
    "drawn", "dream", "dress", "drill", "drink", "drive", "drove", "dying",
    "eager", "early", "earth", "eight", "elect", "elite", "empty", "enemy",
    "enjoy", "enter", "entry", "equal", "error", "event", "every", "exact",
    "exist", "extra", "faith", "false", "fancy", "fault", "fiber", "field",
    "fifth", "fifty", "fight", "final", "first", "fixed", "flash", "fleet",
    "floor", "fluid", "focus", "force", "forth", "forty", "forum", "found",
    "frame", "frank", "fraud", "fresh", "front", "fruit", "fully", "funny",
    "giant", "given", "glass", "globe", "going", "grace", "grade", "grand",
    "grant", "grass", "grave", "great", "green", "gross", "group", "grown",
    "guard", "guess", "guest", "guide", "happy", "harry", "heart", "heavy",
    "hence", "henry", "horse", "hotel", "house", "human", "ideal", "image",
    "imply", "index", "inner", "input", "issue", "japan", "jimmy", "joint",
    "jones", "judge", "known", "label", "large", "laser", "later", "laugh",
    "layer", "learn", "lease", "least", "leave", "legal", "lemon", "level",
    "lewis", "light", "limit", "links", "lives", "local", "logic", "loose",
    "lower", "lucky", "lunch", "lying", "magic", "major", "maker", "march",
    "maria", "match", "maybe", "mayor", "meant", "media", "metal", "might",
    "minor", "minus", "mixed", "model", "money", "month", "moral", "motor",
    "mount", "mouse", "mouth", "movie", "music", "needs", "never", "newly",
    "night", "noise", "north", "noted", "novel", "nurse", "occur", "ocean",
    "offer", "often", "order", "other", "ought", "paint", "panel", "paper",
    "party", "peace", "peter", "phase", "phone", "photo", "piece", "pilot",
    "pitch", "place", "plain", "plane", "plant", "plate", "point", "pound",
    "power", "press", "price", "pride", "prime", "print", "prior", "prize",
    "proof", "proud", "prove", "queen", "quick", "quiet", "quite", "radio",
    "raise", "range", "rapid", "ratio", "reach", "ready", "refer", "right",
    "river", "robin", "roger", "roman", "rough", "round", "route", "royal",
    "rural", "scale", "scene", "scope", "score", "sense", "serve", "seven",
    "shall", "shape", "share", "sharp", "sheet", "shelf", "shell", "shift",
    "shine", "shirt", "shock", "shoot", "short", "shown", "sight", "since",
    "sixth", "sixty", "sized", "skill", "slash", "sleep", "slide", "small",
    "smart", "smile", "smith", "smoke", "solid", "solve", "sorry", "sound",
    "south", "space", "spare", "speak", "speed", "spend", "spent", "split",
    "spoke", "sport", "staff", "stage", "stake", "stand", "start", "state",
    "steam", "steel", "stick", "still", "stock", "stone", "stood", "store",
    "storm", "story", "strip", "stuck", "study", "stuff", "style", "sugar",
    "suite", "super", "sweet", "table", "taken", "taste", "taxes", "teach",
    "terms", "texas", "thank", "theft", "their", "theme", "there", "these",
    "thick", "thing", "think", "third", "those", "three", "threw", "throw",
    "tight", "times", "title", "today", "topic", "total", "touch", "tough",
    "tower", "track", "trade", "trail", "train", "treat", "trend", "trial",
    "tribe", "trick", "tried", "tries", "troop", "truck", "truly", "trump",
    "trust", "truth", "trying", "tumor", "uncle", "under", "undue", "union",
    "unity", "until", "upper", "upset", "urban", "usage", "usual", "valid",
    "value", "video", "virus", "visit", "vital", "vocal", "voice", "waste",
    "watch", "water", "wheel", "where", "which", "while", "white", "whole",
    "whose", "woman", "women", "world", "worry", "worse", "worst", "worth",
    "would", "wound", "write", "wrong", "wrote", "yield", "young", "youth"
  ]

  @impl true
  def metadata do
    %{
      name: "wordle",
      version: "1.0.0",
      description: "Wordle - Guess the 5-letter word in 6 attempts",
      author: "droo.foo",
      commands: ["wordle"],
      category: :game
    }
  end

  @impl true
  def init(_terminal_state) do
    {:ok,
     %__MODULE__{
       target_word: Enum.random(@word_list),
       guesses: [],
       current_guess: "",
       game_over: false,
       won: false,
       max_guesses: @max_guesses
     }}
  end

  @impl true
  def handle_input("Enter", state, _terminal_state) do
    if game_blocked?(state) do
      {:continue, state, render(state, %{})}
    else
      if String.length(state.current_guess) == @word_length do
        # Check if it's a valid word
        if valid_word?(state.current_guess) do
          submit_guess(state)
        else
          # Invalid word, show error but don't submit
          {:continue, state, render_with_error(state, "Not a valid word")}
        end
      else
        {:continue, state, render(state, %{})}
      end
    end
  end

  def handle_input("Backspace", state, _terminal_state) do
    if game_blocked?(state) do
      {:continue, state, render(state, %{})}
    else
      new_guess = String.slice(state.current_guess, 0..-2//1)
      new_state = %{state | current_guess: new_guess}
      {:continue, new_state, render(new_state, %{})}
    end
  end

  def handle_input("r", _state, terminal_state) do
    handle_restart(__MODULE__, terminal_state)
  end

  def handle_input("q", _state, _terminal_state) do
    {:exit, ["Exiting Wordle"]}
  end

  def handle_input(key, state, _terminal_state) do
    if game_blocked?(state) do
      {:continue, state, render(state, %{})}
    else
      # Check if it's a letter
      if String.match?(key, ~r/^[a-zA-Z]$/) and String.length(state.current_guess) < @word_length do
        new_guess = state.current_guess <> String.downcase(key)
        new_state = %{state | current_guess: new_guess}
        {:continue, new_state, render(new_state, %{})}
      else
        {:continue, state, render(state, %{})}
      end
    end
  end

  @impl true
  def render(state, _terminal_state) do
    render_game(state, nil)
  end

  @impl true
  def cleanup(_state) do
    :ok
  end

  # Private helper functions

  defp valid_word?(word) do
    String.downcase(word) in @word_list
  end

  defp submit_guess(state) do
    new_guesses = state.guesses ++ [state.current_guess]
    won = state.current_guess == state.target_word
    game_over = won or length(new_guesses) >= state.max_guesses

    new_state = %{state |
      guesses: new_guesses,
      current_guess: "",
      won: won,
      game_over: game_over
    }

    {:continue, new_state, render(new_state, %{})}
  end

  defp render_with_error(state, error_message) do
    render_game(state, error_message)
  end

  defp render_game(state, error_message) do
    status = cond do
      state.won -> GameUI.format_status(:won)
      state.game_over -> "GAME OVER - Word was: #{String.upcase(state.target_word)}"
      true -> "Guess #{length(state.guesses) + 1}/#{state.max_guesses}"
    end

    guess_rows = render_guesses(state)
    current_row = render_current_guess(state)
    width = 61

    lines = [
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
      (if error_message do
        [GameUI.content_line("Error: #{error_message}", width)]
      else
        []
      end) ++
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

  defp render_guesses(state) do
    Enum.map(state.guesses, fn guess ->
      render_guess_row(guess, state.target_word)
    end)
  end

  defp render_guess_row(guess, target_word) do
    guess_chars = String.graphemes(guess)
    target_chars = String.graphemes(target_word)

    colored_chars = Enum.with_index(guess_chars, fn char, idx ->
      target_char = Enum.at(target_chars, idx)

      cond do
        char == target_char -> "█"  # Correct position
        char in target_chars -> "*"  # Wrong position
        true -> " "  # Not in word
      end
    end)

    guess_display = guess_chars
      |> Enum.zip(colored_chars)
      |> Enum.map(fn {letter, marker} ->
        "#{String.upcase(letter)}#{marker}"
      end)
      |> Enum.join(" ")

    "║    #{String.pad_trailing(guess_display, 52)} ║"
  end

  defp render_current_guess(state) do
    if game_blocked?(state) do
      "║                                                            ║"
    else
      guess_display = state.current_guess
        |> String.graphemes()
        |> Enum.map(&String.upcase/1)
        |> Enum.map(fn letter -> "#{letter}_" end)
        |> Enum.join(" ")

      # Add placeholders for remaining letters
      remaining = @word_length - String.length(state.current_guess)
      placeholders = List.duplicate("__", remaining) |> Enum.join(" ")

      full_display = if guess_display == "" do
        placeholders
      else
        guess_display <> " " <> placeholders
      end

      "║  > #{String.pad_trailing(full_display, 52)} ║"
    end
  end

  defp render_empty_rows(state) do
    used_rows = length(state.guesses) + if(state.game_over, do: 0, else: 1)
    empty_count = state.max_guesses - used_rows

    for _i <- 1..empty_count do
      "║                                                            ║"
    end
  end
end
