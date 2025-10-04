defmodule Droodotfoo.Plugins.TypingTest do
  @moduledoc """
  Typing Speed Test - Measure WPM and accuracy.

  Type the displayed text as accurately and quickly as possible.
  Your Words Per Minute (WPM) and accuracy percentage are calculated in real-time.

  Controls:
  - Type characters to match the target text
  - Backspace: Delete last character
  - Escape: Restart test
  - q: Quit (when not typing)
  """

  @behaviour Droodotfoo.PluginSystem.Plugin

  defstruct [
    :text,
    :typed,
    :started,
    :start_time,
    :end_time,
    :errors,
    :finished,
    :current_sample
  ]

  @sample_texts [
    "The quick brown fox jumps over the lazy dog. This pangram contains every letter of the alphabet.",
    "To be or not to be, that is the question. Whether tis nobler in the mind to suffer the slings and arrows of outrageous fortune.",
    "In the beginning was the Word, and the Word was with God, and the Word was God. The same was in the beginning with God.",
    "It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness.",
    "All happy families are alike; each unhappy family is unhappy in its own way. Everything was in confusion in the Oblonskys house."
  ]

  @impl true
  def metadata do
    %{
      name: "typing_test",
      version: "1.0.0",
      description: "Typing speed test with WPM and accuracy tracking",
      author: "droo.foo",
      commands: ["typing", "type", "wpm", "typing test"],
      category: :game
    }
  end

  @impl true
  def init(_terminal_state) do
    sample = Enum.random(@sample_texts)

    {:ok,
     %__MODULE__{
       text: sample,
       typed: "",
       started: false,
       start_time: nil,
       end_time: nil,
       errors: 0,
       finished: false,
       current_sample: sample
     }}
  end

  @impl true
  def handle_input(key, state, _terminal_state) when key == "Escape" do
    # Restart test with new sample
    sample = Enum.random(@sample_texts)

    new_state = %{
      state
      | text: sample,
        typed: "",
        started: false,
        start_time: nil,
        end_time: nil,
        errors: 0,
        finished: false,
        current_sample: sample
    }

    {:continue, new_state, render(new_state, %{})}
  end

  def handle_input("q", state, _terminal_state) when not state.started do
    {:exit, ["Exiting Typing Test"]}
  end

  def handle_input(key, state, _terminal_state) when key == "Backspace" do
    if state.finished do
      {:continue, state, render(state, %{})}
    else
      new_typed = String.slice(state.typed, 0..-2//1)
      new_state = %{state | typed: new_typed}
      {:continue, new_state, render(new_state, %{})}
    end
  end

  def handle_input(key, state, _terminal_state) when byte_size(key) == 1 do
    if state.finished do
      {:continue, state, render(state, %{})}
    else
      # Start timer on first keypress
      {started, start_time} =
        if state.started do
          {true, state.start_time}
        else
          {true, System.monotonic_time(:millisecond)}
        end

      new_typed = state.typed <> key
      typed_length = String.length(new_typed)

      # Check if character matches
      expected_char = String.at(state.text, typed_length - 1)
      errors = if key != expected_char, do: state.errors + 1, else: state.errors

      # Check if finished
      finished = new_typed == state.text
      end_time = if finished, do: System.monotonic_time(:millisecond), else: nil

      new_state = %{
        state
        | typed: new_typed,
          started: started,
          start_time: start_time,
          end_time: end_time,
          errors: errors,
          finished: finished
      }

      {:continue, new_state, render(new_state, %{})}
    end
  end

  def handle_input(_key, state, _terminal_state) do
    {:continue, state, render(state, %{})}
  end

  @impl true
  def render(state, _terminal_state) do
    {wpm, accuracy, elapsed} = calculate_stats(state)

    status_line =
      if state.finished do
        "COMPLETED!"
      else
        if state.started, do: "TYPING...", else: "Press any key to start"
      end

    lines = [
      "╔═══════════════════════════════════════════════════════════════╗",
      "║ TYPING SPEED TEST                                             ║",
      "╠═══════════════════════════════════════════════════════════════╣",
      "║                                                               ║",
      "║  #{String.pad_trailing(status_line, 61)}║",
      "║                                                               ║",
      "║  WPM: #{String.pad_trailing(format_number(wpm), 10)} Accuracy: #{String.pad_trailing("#{accuracy}%", 10)} Time: #{format_time(elapsed)}   ║",
      "║  Errors: #{String.pad_trailing("#{state.errors}", 52)}║",
      "║                                                               ║",
      "╠═══════════════════════════════════════════════════════════════╣"
    ] ++
      render_text_comparison(state) ++
      [
        "╠═══════════════════════════════════════════════════════════════╣",
        "║                                                               ║",
        "║  Controls:                                                    ║",
        "║  Type to match text  Backspace: Delete  Esc: Restart          ║",
        "║  q: Quit (when idle)                                          ║",
        "║                                                               ║",
        "╚═══════════════════════════════════════════════════════════════╝"
      ]

    lines
  end

  @impl true
  def cleanup(_state) do
    :ok
  end

  # Private helper functions

  defp calculate_stats(state) do
    wpm =
      if state.started and state.start_time do
        elapsed = get_elapsed_time(state)
        # WPM = (characters / 5) / (time in minutes)
        # Standard: 1 word = 5 characters
        if elapsed > 0 do
          characters = String.length(state.typed)
          words = characters / 5
          minutes = elapsed / 60_000
          (words / minutes) |> Float.round(1)
        else
          0.0
        end
      else
        0.0
      end

    accuracy =
      if String.length(state.typed) > 0 do
        correct = String.length(state.typed) - state.errors
        ((correct / String.length(state.typed)) * 100) |> Float.round(1)
      else
        100.0
      end

    elapsed = if state.started, do: get_elapsed_time(state), else: 0

    {wpm, accuracy, elapsed}
  end

  defp get_elapsed_time(state) do
    if state.finished and state.end_time do
      state.end_time - state.start_time
    else
      if state.start_time do
        System.monotonic_time(:millisecond) - state.start_time
      else
        0
      end
    end
  end

  defp format_number(num) when is_float(num) do
    :erlang.float_to_binary(num, decimals: 1)
  end

  defp format_number(num), do: "#{num}"

  defp format_time(ms) do
    seconds = div(ms, 1000)
    "#{seconds}s"
  end

  defp render_text_comparison(state) do
    # Split text into lines of 59 chars max
    max_line_width = 59

    # Render target text
    target_lines = wrap_text(state.text, max_line_width)

    # Render typed text with highlighting
    typed_lines = render_typed_with_highlights(state, max_line_width)

    # Create display
    result = []

    result =
      result ++
        [
          "║  Target Text:                                                 ║",
          "║  ┌─────────────────────────────────────────────────────────┐ ║"
        ]

    # Add target text lines
    result =
      result ++
        Enum.map(target_lines, fn line ->
          padded = String.pad_trailing(line, max_line_width)
          "║  │ #{padded} │ ║"
        end)

    result =
      result ++
        [
          "║  └─────────────────────────────────────────────────────────┘ ║",
          "║                                                               ║",
          "║  Your Typing:                                                 ║",
          "║  ┌─────────────────────────────────────────────────────────┐ ║"
        ]

    # Add typed text lines
    result =
      result ++
        Enum.map(typed_lines, fn line ->
          padded = String.pad_trailing(line, max_line_width)
          "║  │ #{padded} │ ║"
        end)

    # Fill remaining lines to match target
    remaining_lines = length(target_lines) - length(typed_lines)

    result =
      if remaining_lines > 0 do
        result ++
          Enum.map(1..remaining_lines, fn _ ->
            "║  │ #{String.duplicate(" ", max_line_width)} │ ║"
          end)
      else
        result
      end

    result ++
      [
        "║  └─────────────────────────────────────────────────────────┘ ║",
        "║                                                               ║"
      ]
  end

  defp wrap_text(text, max_width) do
    text
    |> String.graphemes()
    |> Enum.chunk_every(max_width)
    |> Enum.map(&Enum.join/1)
  end

  defp render_typed_with_highlights(state, max_width) do
    if String.length(state.typed) == 0 do
      [""]
    else
      # Compare character by character and highlight errors
      typed_chars = String.graphemes(state.typed)
      target_chars = String.graphemes(state.text)

      highlighted =
        typed_chars
        |> Enum.with_index()
        |> Enum.map(fn {char, idx} ->
          target_char = Enum.at(target_chars, idx)

          if char == target_char do
            char
          else
            # Mark incorrect characters with brackets
            "[#{char}]"
          end
        end)
        |> Enum.join("")
        |> String.graphemes()
        |> Enum.chunk_every(max_width)
        |> Enum.map(&Enum.join/1)

      highlighted
    end
  end
end
