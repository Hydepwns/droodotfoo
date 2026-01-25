defmodule Droodotfoo.Content.SVG.Styles do
  @moduledoc """
  SVG style attribute helpers.
  """

  @type attributes :: %{optional(atom | String.t()) => String.t() | number}

  @doc """
  Helper to create common stroke attributes.
  """
  @spec stroke(String.t(), number, number) :: attributes
  def stroke(color, width, opacity) do
    %{
      stroke: color,
      "stroke-width": width,
      opacity: opacity,
      fill: "none"
    }
  end

  @doc """
  Helper to create common fill attributes.
  """
  @spec fill(String.t(), number) :: attributes
  def fill(color, opacity) do
    %{
      fill: color,
      opacity: opacity
    }
  end
end
