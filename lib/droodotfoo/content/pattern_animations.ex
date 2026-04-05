defmodule Droodotfoo.Content.PatternAnimations do
  @moduledoc """
  CSS animation definitions for pattern styles.
  Each pattern's animations live in their own module under PatternAnimations.*.
  """

  alias __MODULE__.{
    Waves,
    Noise,
    Lines,
    Dots,
    Circuit,
    Glitch,
    Geometric,
    Grid,
    FlowField,
    Interference,
    Topology,
    Voronoi,
    Isometric,
    Constellation,
    Aurora,
    GlassCube
  }

  @spec get_animations(atom) :: String.t()
  def get_animations(:waves), do: Waves.css()
  def get_animations(:noise), do: Noise.css()
  def get_animations(:lines), do: Lines.css()
  def get_animations(:dots), do: Dots.css()
  def get_animations(:circuit), do: Circuit.css()
  def get_animations(:glitch), do: Glitch.css()
  def get_animations(:geometric), do: Geometric.css()
  def get_animations(:grid), do: Grid.css()
  def get_animations(:flow_field), do: FlowField.css()
  def get_animations(:interference), do: Interference.css()
  def get_animations(:topology), do: Topology.css()
  def get_animations(:voronoi), do: Voronoi.css()
  def get_animations(:isometric), do: Isometric.css()
  def get_animations(:constellation), do: Constellation.css()
  def get_animations(:aurora), do: Aurora.css()
  def get_animations(:composite), do: ""
  def get_animations(:glass_cube), do: GlassCube.css()
  def get_animations(_), do: ""
end
