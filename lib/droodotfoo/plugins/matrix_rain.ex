defmodule Droodotfoo.Plugins.MatrixRain do
  @moduledoc """
  Matrix rain effect plugin - Digital rain animation inspired by The Matrix.

  Creates an animated cascade of green characters (Japanese katakana and alphanumerics)
  falling down the terminal screen. Each column moves at a different speed with
  varying character trail lengths.

  ## Visual Effects

  - **Bright green**: Leading character in each column
  - **Medium green**: Characters 1-2 positions behind lead
  - **Dim green**: Tail characters fading out

  ## Animation

  - 80x24 character grid
  - Variable column speeds (0.5-1.0 units per frame)
  - Random column heights (5-20 characters)
  - Continuous loop with column recycling

  ## Controls

  - **Any key**: Exit the animation

  ## Character Set

  Japanese katakana (ア-ン) + alphanumerics (0-9, A-Z)
  """

  @behaviour Droodotfoo.PluginSystem.Plugin

  alias Droodotfoo.Plugins.GameBase

  @type column :: %{
          y: float(),
          speed: float(),
          chars: [String.t()]
        }
  @type state :: %__MODULE__{
          width: integer(),
          height: integer(),
          columns: %{integer() => column()},
          frame: integer()
        }
  @type terminal_state :: map()
  @type render_output :: [String.t()]

  defstruct [
    :width,
    :height,
    :columns,
    :frame
  ]

  @chars "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
         |> String.graphemes()

  # Plugin Behaviour Callbacks

  @impl true
  @spec metadata() :: map()
  def metadata do
    GameBase.game_metadata(
      "matrix",
      "1.0.0",
      "Matrix rain effect - Press any key to exit",
      "droo.foo",
      ["matrix", "rain"],
      :fun
    )
  end

  @impl true
  @spec init(terminal_state()) :: {:ok, state()}
  def init(_terminal_state) do
    width = 80
    height = 24

    columns =
      for x <- 0..(width - 1), into: %{} do
        {x,
         %{
           y: :rand.uniform(height) - height,
           speed: 0.5 + :rand.uniform() * 0.5,
           chars: generate_column_chars()
         }}
      end

    state = %__MODULE__{
      width: width,
      height: height,
      columns: columns,
      frame: 0
    }

    {:ok, state}
  end

  @impl true
  @spec handle_input(String.t(), state(), terminal_state()) :: {:exit, [String.t()]}
  def handle_input(_input, _state, _terminal_state) do
    {:exit, ["Exiting Matrix rain..."]}
  end

  @impl true
  @spec handle_key(String.t(), state(), terminal_state()) :: {:ok, state()}
  def handle_key(_key, state, _terminal_state) do
    # Update animation frame
    new_columns = update_columns(state.columns, state.height)
    new_state = %{state | columns: new_columns, frame: state.frame + 1}
    {:ok, new_state}
  end

  @impl true
  @spec render(state(), terminal_state()) :: render_output()
  def render(state, _terminal_state) do
    # Create the display grid
    grid =
      for y <- 0..(state.height - 1) do
        for x <- 0..(state.width - 1) do
          render_cell(x, y, state.columns)
        end
        |> Enum.join()
      end

    header = [
      "MATRIX RAIN - Press any key to exit",
      String.duplicate("=", state.width)
    ]

    header ++ grid
  end

  @impl true
  @spec cleanup(state()) :: :ok
  def cleanup(_state) do
    :ok
  end

  # Private Functions

  defp generate_column_chars do
    length = 5 + :rand.uniform(15)
    for _ <- 1..length, do: Enum.random(@chars)
  end

  defp update_columns(columns, height) do
    Map.new(columns, fn {x, col} ->
      # Update column position
      new_y = col.y + col.speed

      # Reset column if it's gone off screen
      new_col =
        if new_y > height + length(col.chars) do
          %{
            y: -:rand.uniform(height),
            speed: 0.5 + :rand.uniform() * 0.5,
            chars: generate_column_chars()
          }
        else
          %{col | y: new_y}
        end

      {x, new_col}
    end)
  end

  defp render_cell(x, y, columns) do
    case Map.get(columns, x) do
      nil ->
        " "

      col ->
        pos = y - trunc(col.y)

        cond do
          pos < 0 or pos >= length(col.chars) ->
            " "

          pos == 0 ->
            # Bright green for the head
            "\e[1;32m#{Enum.at(col.chars, pos)}\e[0m"

          pos < 3 ->
            # Medium green for near head
            "\e[32m#{Enum.at(col.chars, pos)}\e[0m"

          true ->
            # Dim green for tail
            "\e[2;32m#{Enum.at(col.chars, pos)}\e[0m"
        end
    end
  end
end
