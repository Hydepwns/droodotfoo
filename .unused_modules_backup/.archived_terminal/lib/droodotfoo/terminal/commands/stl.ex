defmodule Droodotfoo.Terminal.Commands.Stl do
  @moduledoc """
  STL 3D model viewer commands.
  Provides terminal interface for loading and controlling 3D models.
  """

  use Droodotfoo.Terminal.CommandBase

  alias Droodotfoo.StlViewerState

  @impl true
  def execute("stl", args, state), do: handle_stl_command(args, state)

  def execute(command, _args, state) do
    {:error, "Unknown STL command: #{command}", state}
  end

  @doc """
  Main STL command dispatcher.
  """
  def handle_stl_command([], _state) do
    help_text = """
    STL Viewer - 3D Model Viewer

    Usage:
      :stl load <url>       Load STL model from URL
      :stl info             Show current model information
      :stl mode <mode>      Set render mode (solid|wireframe|points)
      :stl rotate [axis]    Toggle auto-rotate (x|y|z|all)
      :stl reset            Reset camera view
      :stl ascii            Toggle ASCII wireframe preview
      :stl help             Show this help

    Examples:
      :stl load /models/teapot.stl
      :stl mode wireframe
      :stl rotate y

    Keyboard Controls (in viewer):
      j/k     Rotate model up/down
      h/l     Rotate model left/right
      +/-     Zoom in/out
      r       Reset view
      m       Cycle render modes
    """

    {:ok, help_text}
  end

  def handle_stl_command(["help" | _], state) do
    handle_stl_command([], state)
  end

  def handle_stl_command(["load", url | _], state) do
    viewer_state =
      (state.stl_viewer_state || StlViewerState.new())
      |> StlViewerState.load_model(url)

    new_state = %{state | stl_viewer_state: viewer_state, current_section: :stl_viewer}

    output = "Loading STL model from: #{url}..."
    {:ok, output, new_state}
  end

  def handle_stl_command(["load"], _state) do
    {:error, "stl load: missing URL argument\nUsage: :stl load <url>"}
  end

  def handle_stl_command(["info" | _], state) do
    viewer_state = state.stl_viewer_state || StlViewerState.new()
    info_lines = StlViewerState.format_model_info(viewer_state)
    output = Enum.join(info_lines, "\n")
    {:ok, output}
  end

  def handle_stl_command(["mode", mode_str | _], state) do
    mode = String.to_atom(mode_str)

    if mode in [:solid, :wireframe, :points] do
      viewer_state =
        (state.stl_viewer_state || StlViewerState.new())
        |> StlViewerState.set_render_mode(mode)

      new_state = %{state | stl_viewer_state: viewer_state}
      {:ok, "Render mode set to: #{mode_str}", new_state}
    else
      {:error, "Invalid mode: #{mode_str}\nValid modes: solid, wireframe, points"}
    end
  end

  def handle_stl_command(["mode"], _state) do
    {:error, "stl mode: missing mode argument\nUsage: :stl mode <solid|wireframe|points>"}
  end

  def handle_stl_command(["rotate"], state) do
    viewer_state =
      (state.stl_viewer_state || StlViewerState.new())
      |> StlViewerState.toggle_auto_rotate()

    new_state = %{state | stl_viewer_state: viewer_state}
    status = if viewer_state.auto_rotate, do: "enabled", else: "disabled"
    {:ok, "Auto-rotate #{status} (axis: #{viewer_state.rotation_axis})", new_state}
  end

  def handle_stl_command(["rotate", axis_str | _], state) do
    axis = String.to_atom(axis_str)

    if axis in [:x, :y, :z, :all] do
      viewer_state =
        (state.stl_viewer_state || StlViewerState.new())
        |> StlViewerState.set_rotation_axis(axis)
        |> StlViewerState.toggle_auto_rotate()

      new_state = %{state | stl_viewer_state: viewer_state}
      status = if viewer_state.auto_rotate, do: "enabled", else: "disabled"
      {:ok, "Auto-rotate #{status} on #{axis} axis", new_state}
    else
      {:error, "Invalid axis: #{axis_str}\nValid axes: x, y, z, all"}
    end
  end

  def handle_stl_command(["reset" | _], state) do
    viewer_state =
      (state.stl_viewer_state || StlViewerState.new())
      |> StlViewerState.reset_camera()

    new_state = %{state | stl_viewer_state: viewer_state}
    {:ok, "Camera view reset", new_state}
  end

  def handle_stl_command(["ascii" | _], state) do
    viewer_state =
      (state.stl_viewer_state || StlViewerState.new())
      |> StlViewerState.toggle_ascii_preview()

    new_state = %{state | stl_viewer_state: viewer_state}
    status = if viewer_state.show_ascii_preview, do: "enabled", else: "disabled"
    {:ok, "ASCII preview #{status}", new_state}
  end

  def handle_stl_command([unknown | _], _state) do
    {:error, "Unknown STL subcommand: #{unknown}\nType 'stl help' for usage"}
  end

  @doc """
  Provides command completions for STL commands.
  """
  def get_completions(partial) do
    commands = [
      "load",
      "info",
      "mode",
      "rotate",
      "reset",
      "ascii",
      "help"
    ]

    commands
    |> Enum.filter(&String.starts_with?(&1, partial))
    |> Enum.sort()
  end

  @doc """
  Get mode completions.
  """
  def get_mode_completions(partial) do
    modes = ["solid", "wireframe", "points"]

    modes
    |> Enum.filter(&String.starts_with?(&1, partial))
  end

  @doc """
  Get axis completions.
  """
  def get_axis_completions(partial) do
    axes = ["x", "y", "z", "all"]

    axes
    |> Enum.filter(&String.starts_with?(&1, partial))
  end
end
