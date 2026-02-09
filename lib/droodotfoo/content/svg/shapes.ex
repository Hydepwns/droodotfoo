defmodule Droodotfoo.Content.SVG.Shapes do
  @moduledoc """
  Basic SVG shape primitives.
  """

  @type attributes :: %{optional(atom | String.t()) => String.t() | number}
  @type element :: %{
          tag: atom,
          attrs: attributes,
          class: String.t() | nil,
          children: [element] | nil,
          smil: String.t() | nil
        }

  @doc """
  Creates a circle element.
  """
  @spec circle(number, number, number, attributes) :: element
  def circle(cx, cy, r, attrs \\ %{}) do
    %{
      tag: :circle,
      attrs: Map.merge(%{cx: cx, cy: cy, r: r}, attrs),
      class: nil,
      children: nil,
      smil: nil
    }
  end

  @doc """
  Creates a rectangle element.
  """
  @spec rect(number, number, number, number, attributes) :: element
  def rect(x, y, width, height, attrs \\ %{}) do
    %{
      tag: :rect,
      attrs: Map.merge(%{x: x, y: y, width: width, height: height}, attrs),
      class: nil,
      children: nil,
      smil: nil
    }
  end

  @doc """
  Creates a line element.
  """
  @spec line(number, number, number, number, attributes) :: element
  def line(x1, y1, x2, y2, attrs \\ %{}) do
    %{
      tag: :line,
      attrs: Map.merge(%{x1: x1, y1: y1, x2: x2, y2: y2}, attrs),
      class: nil,
      children: nil,
      smil: nil
    }
  end

  @doc """
  Creates a path element.
  """
  @spec path(String.t(), attributes) :: element
  def path(d, attrs \\ %{}) do
    %{
      tag: :path,
      attrs: Map.merge(%{d: d}, attrs),
      class: nil,
      children: nil,
      smil: nil
    }
  end

  @doc """
  Creates a polygon element.
  """
  @spec polygon(String.t(), attributes) :: element
  def polygon(points, attrs \\ %{}) do
    %{
      tag: :polygon,
      attrs: Map.merge(%{points: points}, attrs),
      class: nil,
      children: nil,
      smil: nil
    }
  end
end
