defmodule Droodotfoo.StlViewerState do
  @moduledoc """
  State management for the STL 3D model viewer.
  Tracks loaded models, viewer settings, and camera position.
  """

  defstruct [
    :current_model,
    :model_url,
    :model_name,
    :model_info,
    :render_mode,
    :auto_rotate,
    :rotation_axis,
    :camera_position,
    :zoom_level,
    :show_ascii_preview,
    :loading,
    :error
  ]

  @type t :: %__MODULE__{
          current_model: map() | nil,
          model_url: String.t() | nil,
          model_name: String.t() | nil,
          model_info: map() | nil,
          render_mode: :solid | :wireframe | :points,
          auto_rotate: boolean(),
          rotation_axis: :x | :y | :z | :all,
          camera_position: {float(), float(), float()},
          zoom_level: float(),
          show_ascii_preview: boolean(),
          loading: boolean(),
          error: String.t() | nil
        }

  @doc """
  Creates a new STL viewer state with default settings.
  """
  def new do
    %__MODULE__{
      current_model: nil,
      model_url: nil,
      model_name: nil,
      model_info: nil,
      render_mode: :solid,
      auto_rotate: false,
      rotation_axis: :y,
      camera_position: {0.0, 0.0, 5.0},
      zoom_level: 1.0,
      show_ascii_preview: false,
      loading: false,
      error: nil
    }
  end

  @doc """
  Loads a model from a URL.
  """
  def load_model(state, url, name \\ nil) do
    %{
      state
      | model_url: url,
        model_name: name || extract_name_from_url(url),
        loading: true,
        error: nil
    }
  end

  @doc """
  Sets model information after successful load.
  """
  def set_model_info(state, info) do
    %{state | model_info: info, loading: false}
  end

  @doc """
  Sets an error message.
  """
  def set_error(state, error) do
    %{state | error: error, loading: false}
  end

  @doc """
  Changes the render mode.
  """
  def set_render_mode(state, mode) when mode in [:solid, :wireframe, :points] do
    %{state | render_mode: mode}
  end

  @doc """
  Toggles auto-rotation.
  """
  def toggle_auto_rotate(state) do
    %{state | auto_rotate: !state.auto_rotate}
  end

  @doc """
  Sets rotation axis.
  """
  def set_rotation_axis(state, axis) when axis in [:x, :y, :z, :all] do
    %{state | rotation_axis: axis}
  end

  @doc """
  Toggles ASCII preview mode.
  """
  def toggle_ascii_preview(state) do
    %{state | show_ascii_preview: !state.show_ascii_preview}
  end

  @doc """
  Resets camera to default position.
  """
  def reset_camera(state) do
    %{state | camera_position: {0.0, 0.0, 5.0}, zoom_level: 1.0}
  end

  @doc """
  Updates zoom level.
  """
  def set_zoom(state, level) when is_float(level) and level > 0 do
    %{state | zoom_level: level}
  end

  # Private functions

  defp extract_name_from_url(url) do
    url
    |> String.split("/")
    |> List.last()
    |> String.replace(~r/\.(stl|STL)$/, "")
  end

  @doc """
  Gets a formatted status message.
  """
  def status_message(state) do
    cond do
      state.loading -> "Loading model..."
      state.error -> "Error: #{state.error}"
      state.model_name -> "Loaded: #{state.model_name}"
      true -> "No model loaded"
    end
  end

  @doc """
  Gets formatted model info for display.
  """
  def format_model_info(state) do
    if state.model_info do
      info = state.model_info

      [
        "Model: #{state.model_name || "Unknown"}",
        "Triangles: #{Map.get(info, :triangles, "N/A")}",
        "Vertices: #{Map.get(info, :vertices, "N/A")}",
        "Bounds: #{format_bounds(Map.get(info, :bounds))}",
        "Mode: #{format_mode(state.render_mode)}",
        "Auto-rotate: #{if state.auto_rotate, do: "ON (#{state.rotation_axis})", else: "OFF"}"
      ]
    else
      ["No model loaded", "", "Use: :stl load <url>"]
    end
  end

  defp format_mode(:solid), do: "Solid"
  defp format_mode(:wireframe), do: "Wireframe"
  defp format_mode(:points), do: "Points"

  defp format_bounds(nil), do: "N/A"

  defp format_bounds(bounds) do
    "#{Float.round(bounds.width, 2)} x #{Float.round(bounds.height, 2)} x #{Float.round(bounds.depth, 2)}"
  end
end
