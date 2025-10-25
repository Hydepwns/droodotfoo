defmodule Droodotfoo.Raxol.Renderer.Games do
  @moduledoc """
  Games section UI rendering for the terminal.
  Displays available games with descriptions and launch instructions.
  """

  alias Droodotfoo.Raxol.BoxBuilder

  @doc """
  Draw the games menu showing all available games.
  """
  def draw_games_menu(_state) do
    games = [
      %{
        name: "Tetris",
        command: ":tetris or :t",
        description: "Stack falling blocks, clear lines for points",
        controls: "Arrows: Move/Rotate, Space: Drop, P: Pause"
      },
      %{
        name: "Snake",
        command: ":snake",
        description: "Classic snake game - eat food, grow longer",
        controls: "Arrow keys or WASD to move"
      },
      %{
        name: "2048",
        command: ":twenty48",
        description: "Combine tiles to reach 2048",
        controls: "Arrow keys to slide tiles"
      },
      %{
        name: "Wordle",
        command: ":wordle",
        description: "Guess the 5-letter word in 6 attempts",
        controls: "Type letters, Enter to submit"
      },
      %{
        name: "Conway's Life",
        command: ":conway or :life",
        description: "Watch cellular automaton simulation",
        controls: "Space: Step, P: Pause, R: Random"
      },
      %{
        name: "Typing Test",
        command: ":typing or :wpm",
        description: "Test your typing speed and accuracy",
        controls: "Type the displayed text"
      }
    ]

    content =
      [
        "",
        "Available Games",
        "=" <> String.duplicate("=", 48),
        ""
      ] ++
        Enum.flat_map(games, fn game ->
          [
            "[>] #{game.name}",
            "    Command: #{game.command}",
            "    #{game.description}",
            "    Controls: #{game.controls}",
            ""
          ]
        end) ++
        [
          "",
          "How to Play:",
          "  1. Press ':' to enter command mode",
          "  2. Type the game command (e.g., 'tetris')",
          "  3. Press Enter to launch",
          "  4. Press 'Q' in-game to quit",
          "",
          "Tip: Most games support both arrow keys and vim keys (h/j/k/l)"
        ]

    BoxBuilder.build("Games", content)
  end
end
