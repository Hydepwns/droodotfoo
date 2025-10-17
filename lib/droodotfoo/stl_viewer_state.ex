defmodule Droodotfoo.StlViewerState do
  @moduledoc """
  State management for STL 3D model viewer.
  Handles model loading, rendering options, and viewer controls.
  """

  defstruct [
    :model_url,
    :model_name,
    :model_data,
    :render_mode,
    :auto_rotate,
    :rotation_axis,
    :show_ascii_preview,
    :camera_position,
    :camera_target,
    :zoom_level
  ]

  @doc """
  Creates a new STL viewer state with default values.
  """
  def new do
    %__MODULE__{
      model_url: nil,
      model_name: nil,
      model_data: nil,
      render_mode: :solid,
      auto_rotate: false,
      rotation_axis: :y,
      show_ascii_preview: false,
      camera_position: {0, 0, 5},
      camera_target: {0, 0, 0},
      zoom_level: 1.0
    }
  end

  @doc """
  Loads a model from the given URL.
  """
  def load_model(state, url) do
    model_name = extract_model_name(url)

    %{
      state
      | model_url: url,
        model_name: model_name,
        # In a real implementation, this would load the STL data
        model_data: nil
    }
  end

  @doc """
  Sets the render mode for the model.
  """
  def set_render_mode(state, mode) when mode in [:solid, :wireframe, :points] do
    %{state | render_mode: mode}
  end

  @doc """
  Toggles auto-rotation on/off.
  """
  def toggle_auto_rotate(state) do
    %{state | auto_rotate: !state.auto_rotate}
  end

  @doc """
  Sets the rotation axis for auto-rotation.
  """
  def set_rotation_axis(state, axis) when axis in [:x, :y, :z, :all] do
    %{state | rotation_axis: axis}
  end

  @doc """
  Resets the camera to default position.
  """
  def reset_camera(state) do
    %{state | camera_position: {0, 0, 5}, camera_target: {0, 0, 0}, zoom_level: 1.0}
  end

  @doc """
  Toggles ASCII wireframe preview on/off.
  """
  def toggle_ascii_preview(state) do
    %{state | show_ascii_preview: !state.show_ascii_preview}
  end

  @doc """
  Formats model information for display.
  """
  def format_model_info(state) do
    info_lines = [
      "STL Model Information:",
      "=====================",
      "Model: #{state.model_name || "None loaded"}",
      "URL: #{state.model_url || "N/A"}",
      "Render Mode: #{state.render_mode}",
      "Auto-rotate: #{if state.auto_rotate, do: "enabled", else: "disabled"}",
      "Rotation Axis: #{state.rotation_axis}",
      "ASCII Preview: #{if state.show_ascii_preview, do: "enabled", else: "disabled"}",
      "Camera Position: #{format_position(state.camera_position)}",
      "Zoom Level: #{state.zoom_level}"
    ]

    if state.model_data do
      info_lines ++
        [
          "",
          "Model Statistics:",
          "Vertices: #{count_vertices(state.model_data)}",
          "Faces: #{count_faces(state.model_data)}"
        ]
    else
      info_lines
    end
  end

  # Private helper functions

  defp extract_model_name(url) do
    url
    |> String.split("/")
    |> List.last()
    |> String.split(".")
    |> List.first()
    |> case do
      nil -> "unknown"
      name -> name
    end
  end

  defp format_position({x, y, z}) do
    "(#{x}, #{y}, #{z})"
  end

  defp count_vertices(_model_data) do
    # In a real implementation, this would parse the STL data
    "N/A"
  end

  defp count_faces(_model_data) do
    # In a real implementation, this would parse the STL data
    "N/A"
  end
end
