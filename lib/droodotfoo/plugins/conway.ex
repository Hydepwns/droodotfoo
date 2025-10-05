defmodule Droodotfoo.Plugins.Conway do
  @moduledoc """
  Conway's Game of Life - A cellular automaton simulation.

  Rules:
  1. Any live cell with 2 or 3 live neighbors survives
  2. Any dead cell with exactly 3 live neighbors becomes alive
  3. All other cells die or stay dead

  Controls:
  - Space: Play/Pause
  - s: Step one generation
  - c: Clear grid
  - r: Random pattern
  - +/-: Increase/decrease speed
  - 1-5: Load preset patterns
  - q: Quit
  """

  use Droodotfoo.Plugins.GameBase
  alias Droodotfoo.Plugins.GameUI

  defstruct [
    :grid,
    :width,
    :height,
    :generation,
    :running,
    :speed,
    :last_update,
    :pattern_name
  ]

  @width 60
  @height 20

  @impl true
  def metadata do
    %{
      name: "conway",
      version: "1.0.0",
      description: "Conway's Game of Life - cellular automaton simulation",
      author: "droo.foo",
      commands: ["conway", "life", "game of life"],
      category: :game
    }
  end

  @impl true
  def init(_terminal_state) do
    {:ok,
     %__MODULE__{
       grid: create_empty_grid(@width, @height),
       width: @width,
       height: @height,
       generation: 0,
       running: false,
       speed: 500,
       last_update: System.monotonic_time(:millisecond),
       pattern_name: "empty"
     }}
  end

  @impl true
  def handle_input(" ", state, _terminal_state) do
    # Toggle play/pause
    new_state = %{state | running: !state.running}
    {:continue, new_state, render(new_state, %{})}
  end

  def handle_input("s", state, _terminal_state) do
    # Step one generation
    new_grid = next_generation(state.grid, state.width, state.height)
    new_state = %{state | grid: new_grid, generation: state.generation + 1}
    {:continue, new_state, render(new_state, %{})}
  end

  def handle_input("c", state, _terminal_state) do
    # Clear grid
    new_state = %{
      state
      | grid: create_empty_grid(state.width, state.height),
        generation: 0,
        running: false,
        pattern_name: "empty"
    }
    {:continue, new_state, render(new_state, %{})}
  end

  def handle_input("r", state, _terminal_state) do
    # Random pattern
    grid = create_random_grid(state.width, state.height, 0.3)
    new_state = %{state | grid: grid, generation: 0, pattern_name: "random"}
    {:continue, new_state, render(new_state, %{})}
  end

  def handle_input("+", state, _terminal_state) do
    # Increase speed (decrease delay)
    new_speed = max(50, state.speed - 100)
    new_state = %{state | speed: new_speed}
    {:continue, new_state, render(new_state, %{})}
  end

  def handle_input("-", state, _terminal_state) do
    # Decrease speed (increase delay)
    new_speed = min(2000, state.speed + 100)
    new_state = %{state | speed: new_speed}
    {:continue, new_state, render(new_state, %{})}
  end

  def handle_input("1", state, _terminal_state) do
    # Glider pattern
    grid = load_pattern(:glider, state.width, state.height)
    new_state = %{state | grid: grid, generation: 0, pattern_name: "glider"}
    {:continue, new_state, render(new_state, %{})}
  end

  def handle_input("2", state, _terminal_state) do
    # Blinker pattern
    grid = load_pattern(:blinker, state.width, state.height)
    new_state = %{state | grid: grid, generation: 0, pattern_name: "blinker"}
    {:continue, new_state, render(new_state, %{})}
  end

  def handle_input("3", state, _terminal_state) do
    # Toad pattern
    grid = load_pattern(:toad, state.width, state.height)
    new_state = %{state | grid: grid, generation: 0, pattern_name: "toad"}
    {:continue, new_state, render(new_state, %{})}
  end

  def handle_input("4", state, _terminal_state) do
    # Beacon pattern
    grid = load_pattern(:beacon, state.width, state.height)
    new_state = %{state | grid: grid, generation: 0, pattern_name: "beacon"}
    {:continue, new_state, render(new_state, %{})}
  end

  def handle_input("5", state, _terminal_state) do
    # Pulsar pattern
    grid = load_pattern(:pulsar, state.width, state.height)
    new_state = %{state | grid: grid, generation: 0, pattern_name: "pulsar"}
    {:continue, new_state, render(new_state, %{})}
  end

  def handle_input("q", _state, _terminal_state) do
    {:exit, ["Exiting Conway's Game of Life"]}
  end

  def handle_input(_key, state, _terminal_state) do
    {:continue, state, render(state, %{})}
  end

  @impl true
  def render(state, _terminal_state) do
    status = if state.running, do: "RUNNING", else: "PAUSED"
    width = 64

    lines = [
      GameUI.top_border(width),
      GameUI.title_line("CONWAY'S GAME OF LIFE", width),
      GameUI.divider(width),
      GameUI.empty_line(width),
      GameUI.content_line("Generation: #{String.pad_trailing("#{state.generation}", 10)} Pattern: #{String.pad_trailing(state.pattern_name, 15)}", width),
      GameUI.content_line("Status: #{String.pad_trailing(status, 10)} Speed: #{state.speed}ms", width),
      GameUI.empty_line(width),
      "║  ┌───────────────────────────────────────────────────────┐   ║"
    ] ++
      render_grid(state.grid, state.width, state.height) ++
      [
        "║  └───────────────────────────────────────────────────────┘   ║",
        GameUI.empty_line(width),
        GameUI.content_line("Controls:", width),
        GameUI.content_line("SPACE: Play/Pause  s: Step  c: Clear  r: Random", width),
        GameUI.content_line("+/-: Speed  1-5: Patterns  q: Quit", width),
        GameUI.empty_line(width),
        GameUI.content_line("Patterns: 1=Glider 2=Blinker 3=Toad 4=Beacon 5=Pulsar", width),
        GameUI.empty_line(width),
        GameUI.bottom_border(width)
      ]

    lines
  end

  @impl true
  def cleanup(_state) do
    :ok
  end

  # Private helper functions

  defp create_empty_grid(width, height) do
    create_grid(width, height, false)
  end

  defp create_random_grid(width, height, density) do
    for _y <- 1..height do
      for _x <- 1..width, do: :rand.uniform() < density
    end
  end

  defp get_cell(grid, x, y, width, height) do
    # Wrap around edges (toroidal topology)
    wrapped_x = rem(x + width, width)
    wrapped_y = rem(y + height, height)

    grid
    |> Enum.at(wrapped_y, [])
    |> Enum.at(wrapped_x, false)
  end

  defp count_neighbors(grid, x, y, width, height) do
    neighbors = [
      {x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1},
      {x - 1, y},                 {x + 1, y},
      {x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1}
    ]

    Enum.count(neighbors, fn {nx, ny} ->
      get_cell(grid, nx, ny, width, height)
    end)
  end

  defp next_generation(grid, width, height) do
    for y <- 0..(height - 1) do
      for x <- 0..(width - 1) do
        alive = get_cell(grid, x, y, width, height)
        neighbors = count_neighbors(grid, x, y, width, height)

        cond do
          # Live cell with 2 or 3 neighbors survives
          alive and neighbors in [2, 3] -> true
          # Dead cell with exactly 3 neighbors becomes alive
          not alive and neighbors == 3 -> true
          # All other cells die or stay dead
          true -> false
        end
      end
    end
  end

  defp render_grid(grid, width, height) do
    for y <- 0..(height - 1) do
      row = for x <- 0..(width - 1) do
        if get_cell(grid, x, y, width, height) do
          "█"
        else
          " "
        end
      end

      "║  │" <> Enum.join(row, "") <> "│   ║"
    end
  end

  defp load_pattern(:glider, width, height) do
    grid = create_empty_grid(width, height)

    # Glider pattern (travels diagonally)
    center_x = div(width, 2)
    center_y = div(height, 2)

    positions = [
      {center_x + 1, center_y},
      {center_x + 2, center_y + 1},
      {center_x, center_y + 2},
      {center_x + 1, center_y + 2},
      {center_x + 2, center_y + 2}
    ]

    set_cells(grid, positions, width, height)
  end

  defp load_pattern(:blinker, width, height) do
    grid = create_empty_grid(width, height)

    # Blinker pattern (oscillates)
    center_x = div(width, 2)
    center_y = div(height, 2)

    positions = [
      {center_x - 1, center_y},
      {center_x, center_y},
      {center_x + 1, center_y}
    ]

    set_cells(grid, positions, width, height)
  end

  defp load_pattern(:toad, width, height) do
    grid = create_empty_grid(width, height)

    # Toad pattern (oscillates)
    center_x = div(width, 2)
    center_y = div(height, 2)

    positions = [
      {center_x, center_y},
      {center_x + 1, center_y},
      {center_x + 2, center_y},
      {center_x - 1, center_y + 1},
      {center_x, center_y + 1},
      {center_x + 1, center_y + 1}
    ]

    set_cells(grid, positions, width, height)
  end

  defp load_pattern(:beacon, width, height) do
    grid = create_empty_grid(width, height)

    # Beacon pattern (oscillates)
    center_x = div(width, 2)
    center_y = div(height, 2)

    positions = [
      {center_x, center_y},
      {center_x + 1, center_y},
      {center_x, center_y + 1},
      {center_x + 3, center_y + 2},
      {center_x + 2, center_y + 3},
      {center_x + 3, center_y + 3}
    ]

    set_cells(grid, positions, width, height)
  end

  defp load_pattern(:pulsar, width, height) do
    grid = create_empty_grid(width, height)

    # Pulsar pattern (oscillates with period 3)
    center_x = div(width, 2)
    center_y = div(height, 2)

    # Build pulsar symmetrically
    offsets = [
      # Top group
      {-6, -4}, {-5, -4}, {-4, -4},
      {-6, -3}, {-4, -3},
      {-6, -2}, {-5, -2}, {-4, -2},
      # Bottom group (mirror)
      {-6, 2}, {-5, 2}, {-4, 2},
      {-6, 3}, {-4, 3},
      {-6, 4}, {-5, 4}, {-4, 4}
    ]

    # Generate all 4 quadrants
    positions = for {ox, oy} <- offsets,
                    {mx, my} <- [{1, 1}, {-1, 1}, {1, -1}, {-1, -1}] do
      {center_x + ox * mx, center_y + oy * my}
    end

    set_cells(grid, positions, width, height)
  end

  defp set_cells(grid, positions, width, height) do
    Enum.reduce(positions, grid, fn {x, y}, acc_grid ->
      if x >= 0 and x < width and y >= 0 and y < height do
        List.update_at(acc_grid, y, fn row ->
          List.update_at(row, x, fn _ -> true end)
        end)
      else
        acc_grid
      end
    end)
  end
end
