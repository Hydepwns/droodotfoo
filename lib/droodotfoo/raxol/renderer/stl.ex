defmodule Droodotfoo.Raxol.Renderer.STL do
  @moduledoc """
  STL 3D Viewer section UI rendering for the terminal.
  Displays ASCII art interface for the Three.js STL viewer.
  """

  alias Droodotfoo.Raxol.BoxBuilder

  @doc """
  Draw the STL viewer interface with ASCII art placeholder for 3D canvas.
  """
  def draw_viewer(_state) do
    content = [
      "",
      "3D Model Viewer",
      "=" <> String.duplicate("=", 48),
      "",
      "╭──────────────────────────────────────────────────────╮",
      "│                                                      │",
      "│                  [3D Viewport]                       │",
      "│                                                      │",
      "│              Three.js canvas will                    │",
      "│              render here when a                      │",
      "│              model is loaded                         │",
      "│                                                      │",
      "╰──────────────────────────────────────────────────────╯",
      "",
      "Controls:",
      "  Mouse Drag      - Rotate model",
      "  Mouse Wheel     - Zoom in/out",
      "  J/K            - Rotate up/down",
      "  H/L            - Rotate left/right",
      "  +/-            - Zoom in/out",
      "  R              - Reset camera",
      "  M              - Cycle render modes (solid/wireframe/points)",
      "",
      "Commands:",
      "  :stl load <url>    - Load STL model from URL",
      "  :stl mode <mode>   - Set render mode (solid|wireframe|points)",
      "  :stl reset         - Reset camera to default position",
      "",
      "Example Models:",
      "  :stl load /models/cube.stl",
      "",
      "The 3D viewer uses Three.js and will overlay on this terminal",
      "when a model is successfully loaded."
    ]

    BoxBuilder.build("STL Viewer", content)
  end
end
