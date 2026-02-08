defmodule Droodotfoo.Content.SVGBuilder do
  @moduledoc """
  Structured SVG element builder.

  Replaces string concatenation with proper data structures,
  making SVG generation more testable and composable.
  """

  alias Droodotfoo.Content.SVG.{Filters, Gradients, Shapes, Styles}

  @type attributes :: %{optional(atom | String.t()) => String.t() | number}
  @type element :: %{
          tag: atom,
          attrs: attributes,
          class: String.t() | nil,
          children: [element] | nil
        }

  # Shape primitives - delegate to Shapes module
  defdelegate circle(cx, cy, r, attrs \\ %{}), to: Shapes
  defdelegate rect(x, y, width, height, attrs \\ %{}), to: Shapes
  defdelegate line(x1, y1, x2, y2, attrs \\ %{}), to: Shapes
  defdelegate path(d, attrs \\ %{}), to: Shapes
  defdelegate polygon(points, attrs \\ %{}), to: Shapes

  # Style helpers - delegate to Styles module
  defdelegate stroke(color, width, opacity), to: Styles
  defdelegate fill(color, opacity), to: Styles

  # Filter definitions - delegate with name mapping
  def blur_filter(id, std_deviation), do: Filters.blur(id, std_deviation)
  def glow_filter(id, color, intensity), do: Filters.glow(id, color, intensity)
  def shadow_filter(id, dx, dy, blur), do: Filters.shadow(id, dx, dy, blur)
  def noise_filter(id, base_frequency), do: Filters.noise(id, base_frequency)
  def displacement_filter(id, scale), do: Filters.displacement(id, scale)
  def lighting_filter(id, light_color), do: Filters.lighting(id, light_color)

  # Gradient definitions - delegate with name mapping
  def linear_gradient(id, stops, opts \\ []), do: Gradients.linear(id, stops, opts)
  def radial_gradient(id, stops, opts \\ []), do: Gradients.radial(id, stops, opts)

  @doc """
  Adds a CSS class to an element.
  """
  @spec with_class(element, String.t()) :: element
  def with_class(element, class_name) do
    %{element | class: class_name}
  end

  @doc """
  Adds additional attributes to an element.
  """
  @spec with_attrs(element, attributes) :: element
  def with_attrs(element, attrs) do
    %{element | attrs: Map.merge(element.attrs, attrs)}
  end

  @doc """
  Helper to apply a filter to an element.
  """
  @spec with_filter(element, String.t()) :: element
  def with_filter(element, filter_id) do
    with_attrs(element, %{filter: "url(##{filter_id})"})
  end

  @doc """
  Renders a single element to an SVG string.
  """
  @spec render_element(element) :: String.t()
  def render_element(%{tag: tag, attrs: attrs, class: class_name, children: children}) do
    attrs_str = Enum.map_join(attrs, " ", fn {key, value} -> "#{key}=\"#{value}\"" end)
    class_str = if class_name, do: " class=\"#{class_name}\"", else: ""

    case children do
      nil ->
        "<#{tag} #{attrs_str}#{class_str}/>"

      [] ->
        "<#{tag} #{attrs_str}#{class_str}></#{tag}>"

      children_list ->
        children_str = Enum.map_join(children_list, "\n", &render_element/1)
        "<#{tag} #{attrs_str}#{class_str}>\n#{children_str}\n</#{tag}>"
    end
  end

  @doc """
  Renders a list of elements to SVG strings.
  """
  @spec render_elements([element]) :: String.t()
  def render_elements(elements) when is_list(elements) do
    Enum.map_join(elements, "\n", &render_element/1)
  end

  @doc """
  Creates a complete SVG document with elements.
  """
  @spec build_svg([element], keyword) :: String.t()
  def build_svg(elements, opts \\ []) do
    width = Keyword.get(opts, :width, 1200)
    height = Keyword.get(opts, :height, 630)
    background = Keyword.get(opts, :background, "#000000")
    animations = Keyword.get(opts, :animations, "")

    elements_str = render_elements(elements)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{width} #{height}" preserveAspectRatio="none" style="width: 100%; height: 100%; display: block;">
      #{animations}
      <rect width="#{width}" height="#{height}" fill="#{background}"/>
      #{elements_str}
    </svg>
    """
  end

  @doc """
  Creates filter definitions section for inclusion in SVG.
  """
  @spec filter_defs([String.t()]) :: String.t()
  def filter_defs(filter_list) when is_list(filter_list) do
    """
    <defs>
      #{Enum.join(filter_list, "\n")}
    </defs>
    """
  end

  @doc """
  Creates combined defs section with both gradients and filters.
  """
  @spec defs([String.t()], [String.t()]) :: String.t()
  def defs(gradients, filters) do
    all_defs = gradients ++ filters

    if all_defs == [] do
      ""
    else
      """
      <defs>
        #{Enum.join(all_defs, "\n")}
      </defs>
      """
    end
  end

  @doc """
  Builds SVG with optional filter and gradient definitions.
  """
  @spec build_svg_with_filters([element], keyword) :: String.t()
  def build_svg_with_filters(elements, opts \\ []) do
    width = Keyword.get(opts, :width, 1200)
    height = Keyword.get(opts, :height, 630)
    background = Keyword.get(opts, :background, "#000000")
    animations = Keyword.get(opts, :animations, "")
    filters = Keyword.get(opts, :filters, [])
    gradients = Keyword.get(opts, :gradients, [])

    elements_str = render_elements(elements)
    defs_str = defs(gradients, filters)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{width} #{height}" preserveAspectRatio="none" style="width: 100%; height: 100%; display: block;">
      #{animations}
      #{defs_str}
      <rect width="#{width}" height="#{height}" fill="#{background}"/>
      #{elements_str}
    </svg>
    """
  end
end
