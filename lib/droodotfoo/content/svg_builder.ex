defmodule Droodotfoo.Content.SVGBuilder do
  @moduledoc """
  Structured SVG element builder.

  Replaces string concatenation with proper data structures,
  making SVG generation more testable and composable.
  """

  @type attributes :: %{optional(atom | String.t()) => String.t() | number}
  @type element :: %{
          tag: atom,
          attrs: attributes,
          class: String.t() | nil,
          children: [element] | nil
        }

  @doc """
  Creates a circle element.

  ## Examples

      iex> SVGBuilder.circle(100, 200, 50)
      %{tag: :circle, attrs: %{cx: 100, cy: 200, r: 50}, class: nil, children: nil}
  """
  @spec circle(number, number, number, attributes) :: element
  def circle(cx, cy, r, attrs \\ %{}) do
    %{
      tag: :circle,
      attrs: Map.merge(%{cx: cx, cy: cy, r: r}, attrs),
      class: nil,
      children: nil
    }
  end

  @doc """
  Creates a rectangle element.

  ## Examples

      iex> SVGBuilder.rect(10, 20, 100, 50)
      %{tag: :rect, attrs: %{x: 10, y: 20, width: 100, height: 50}, class: nil, children: nil}
  """
  @spec rect(number, number, number, number, attributes) :: element
  def rect(x, y, width, height, attrs \\ %{}) do
    %{
      tag: :rect,
      attrs: Map.merge(%{x: x, y: y, width: width, height: height}, attrs),
      class: nil,
      children: nil
    }
  end

  @doc """
  Creates a line element.

  ## Examples

      iex> SVGBuilder.line(0, 0, 100, 100)
      %{tag: :line, attrs: %{x1: 0, y1: 0, x2: 100, y2: 100}, class: nil, children: nil}
  """
  @spec line(number, number, number, number, attributes) :: element
  def line(x1, y1, x2, y2, attrs \\ %{}) do
    %{
      tag: :line,
      attrs: Map.merge(%{x1: x1, y1: y1, x2: x2, y2: y2}, attrs),
      class: nil,
      children: nil
    }
  end

  @doc """
  Creates a path element.

  ## Examples

      iex> SVGBuilder.path("M 0 0 L 100 100")
      %{tag: :path, attrs: %{d: "M 0 0 L 100 100"}, class: nil, children: nil}
  """
  @spec path(String.t(), attributes) :: element
  def path(d, attrs \\ %{}) do
    %{
      tag: :path,
      attrs: Map.merge(%{d: d}, attrs),
      class: nil,
      children: nil
    }
  end

  @doc """
  Creates a polygon element.

  ## Examples

      iex> SVGBuilder.polygon("0,0 100,0 50,100")
      %{tag: :polygon, attrs: %{points: "0,0 100,0 50,100"}, class: nil, children: nil}
  """
  @spec polygon(String.t(), attributes) :: element
  def polygon(points, attrs \\ %{}) do
    %{
      tag: :polygon,
      attrs: Map.merge(%{points: points}, attrs),
      class: nil,
      children: nil
    }
  end

  @doc """
  Adds a CSS class to an element.

  ## Examples

      iex> circle = SVGBuilder.circle(100, 200, 50)
      iex> SVGBuilder.with_class(circle, "dot-pulse")
      %{tag: :circle, attrs: %{cx: 100, cy: 200, r: 50}, class: "dot-pulse", children: nil}
  """
  @spec with_class(element, String.t()) :: element
  def with_class(element, class_name) do
    %{element | class: class_name}
  end

  @doc """
  Adds additional attributes to an element.

  ## Examples

      iex> circle = SVGBuilder.circle(100, 200, 50)
      iex> SVGBuilder.with_attrs(circle, %{opacity: 0.5, fill: "#ffffff"})
      %{tag: :circle, attrs: %{cx: 100, cy: 200, r: 50, opacity: 0.5, fill: "#ffffff"}, class: nil, children: nil}
  """
  @spec with_attrs(element, attributes) :: element
  def with_attrs(element, attrs) do
    %{element | attrs: Map.merge(element.attrs, attrs)}
  end

  @doc """
  Renders a single element to an SVG string.

  ## Examples

      iex> circle = SVGBuilder.circle(100, 200, 50) |> SVGBuilder.with_class("dot")
      iex> SVGBuilder.render_element(circle)
      "<circle cx=\"100\" cy=\"200\" r=\"50\" class=\"dot\"/>"
  """
  @spec render_element(element) :: String.t()
  def render_element(%{tag: tag, attrs: attrs, class: class_name, children: children}) do
    # Build attributes string
    attrs_str = Enum.map_join(attrs, " ", fn {key, value} -> "#{key}=\"#{value}\"" end)

    # Add class if present
    class_str = if class_name, do: " class=\"#{class_name}\"", else: ""

    # Handle self-closing vs. container tags
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

  ## Examples

      iex> elements = [
      ...>   SVGBuilder.circle(100, 100, 50),
      ...>   SVGBuilder.rect(0, 0, 50, 50)
      ...> ]
      iex> SVGBuilder.render_elements(elements)
      "<circle cx=\"100\" cy=\"100\" r=\"50\"/>\\n<rect x=\"0\" y=\"0\" width=\"50\" height=\"50\"/>"
  """
  @spec render_elements([element]) :: String.t()
  def render_elements(elements) when is_list(elements) do
    Enum.map_join(elements, "\n", &render_element/1)
  end

  @doc """
  Creates a complete SVG document with elements.

  ## Options

    * `:width` - SVG width (default: 1200)
    * `:height` - SVG height (default: 630)
    * `:background` - Background color (default: "#000000")
    * `:animations` - CSS animation styles (default: "")

  ## Examples

      iex> elements = [SVGBuilder.circle(100, 100, 50)]
      iex> svg = SVGBuilder.build_svg(elements, width: 800, height: 600)
      iex> String.contains?(svg, "<svg")
      true
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

  @doc """
  Creates a blur filter definition.

  ## Examples

      iex> SVGBuilder.blur_filter("blur1", 2.5)
      "<filter id=\\"blur1\\">...</filter>"
  """
  @spec blur_filter(String.t(), number) :: String.t()
  def blur_filter(id, std_deviation) do
    """
    <filter id="#{id}">
      <feGaussianBlur in="SourceGraphic" stdDeviation="#{std_deviation}"/>
    </filter>
    """
  end

  @doc """
  Creates a glow filter definition.

  ## Examples

      iex> SVGBuilder.glow_filter("glow1", "#ffffff", 3)
      "<filter id=\\"glow1\\">...</filter>"
  """
  @spec glow_filter(String.t(), String.t(), number) :: String.t()
  def glow_filter(id, _color, intensity) do
    """
    <filter id="#{id}">
      <feGaussianBlur in="SourceGraphic" stdDeviation="#{intensity}"/>
      <feColorMatrix type="matrix" values="
        1 0 0 0 0
        0 1 0 0 0
        0 0 1 0 0
        0 0 0 #{intensity * 2} 0"/>
      <feBlend in="SourceGraphic" in2="blur" mode="normal"/>
    </filter>
    """
  end

  @doc """
  Creates a drop shadow filter definition.

  ## Examples

      iex> SVGBuilder.shadow_filter("shadow1", 2, 2, 3)
      "<filter id=\\"shadow1\\">...</filter>"
  """
  @spec shadow_filter(String.t(), number, number, number) :: String.t()
  def shadow_filter(id, dx, dy, blur) do
    """
    <filter id="#{id}">
      <feGaussianBlur in="SourceAlpha" stdDeviation="#{blur}"/>
      <feOffset dx="#{dx}" dy="#{dy}" result="offsetblur"/>
      <feComponentTransfer>
        <feFuncA type="linear" slope="0.5"/>
      </feComponentTransfer>
      <feMerge>
        <feMergeNode/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    """
  end

  @doc """
  Creates a turbulence/noise filter definition.

  ## Examples

      iex> SVGBuilder.noise_filter("noise1", 0.5)
      "<filter id=\\"noise1\\">...</filter>"
  """
  @spec noise_filter(String.t(), number) :: String.t()
  def noise_filter(id, base_frequency) do
    """
    <filter id="#{id}">
      <feTurbulence type="fractalNoise" baseFrequency="#{base_frequency}" numOctaves="4" result="noise"/>
      <feColorMatrix in="noise" type="saturate" values="0"/>
      <feBlend in="SourceGraphic" in2="noise" mode="multiply"/>
    </filter>
    """
  end

  @doc """
  Creates a displacement map filter for distortion effects.

  ## Examples

      iex> SVGBuilder.displacement_filter("displace1", 20)
      "<filter id=\\"displace1\\">...</filter>"
  """
  @spec displacement_filter(String.t(), number) :: String.t()
  def displacement_filter(id, scale) do
    """
    <filter id="#{id}">
      <feTurbulence type="turbulence" baseFrequency="0.05" numOctaves="2" result="turbulence"/>
      <feDisplacementMap in2="turbulence" in="SourceGraphic" scale="#{scale}" xChannelSelector="R" yChannelSelector="G"/>
    </filter>
    """
  end

  @doc """
  Creates a lighting filter for 3D emboss effects.

  ## Examples

      iex> SVGBuilder.lighting_filter("light1", "#ffffff")
      "<filter id=\\"light1\\">...</filter>"
  """
  @spec lighting_filter(String.t(), String.t()) :: String.t()
  def lighting_filter(id, light_color) do
    """
    <filter id="#{id}">
      <feGaussianBlur in="SourceAlpha" stdDeviation="3"/>
      <feSpecularLighting result="specOut" specularExponent="20" lighting-color="#{light_color}">
        <fePointLight x="50" y="50" z="200"/>
      </feSpecularLighting>
      <feComposite in="SourceGraphic" in2="specOut" operator="arithmetic" k1="0" k2="1" k3="1" k4="0"/>
    </filter>
    """
  end

  @doc """
  Creates a linear gradient definition.

  ## Options

    * `:x1`, `:y1` - Start point (default: 0%, 0%)
    * `:x2`, `:y2` - End point (default: 100%, 0%)
    * `:stops` - List of {offset, color, opacity} tuples

  ## Examples

      iex> SVGBuilder.linear_gradient("grad1", [{0, "#000", 1}, {100, "#fff", 1}])
      "<linearGradient id=\\"grad1\\">...</linearGradient>"
  """
  @spec linear_gradient(String.t(), [{number, String.t(), number}], keyword) :: String.t()
  def linear_gradient(id, stops, opts \\ []) do
    x1 = Keyword.get(opts, :x1, "0%")
    y1 = Keyword.get(opts, :y1, "0%")
    x2 = Keyword.get(opts, :x2, "100%")
    y2 = Keyword.get(opts, :y2, "0%")

    stops_str =
      Enum.map_join(stops, "\n", fn {offset, color, opacity} ->
        "<stop offset=\"#{offset}%\" stop-color=\"#{color}\" stop-opacity=\"#{opacity}\"/>"
      end)

    """
    <linearGradient id="#{id}" x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}">
      #{stops_str}
    </linearGradient>
    """
  end

  @doc """
  Creates a radial gradient definition.

  ## Options

    * `:cx`, `:cy` - Center point (default: 50%, 50%)
    * `:r` - Radius (default: 50%)
    * `:fx`, `:fy` - Focal point (default: cx, cy)
    * `:stops` - List of {offset, color, opacity} tuples

  ## Examples

      iex> SVGBuilder.radial_gradient("radial1", [{0, "#fff", 1}, {100, "#000", 0}])
      "<radialGradient id=\\"radial1\\">...</radialGradient>"
  """
  @spec radial_gradient(String.t(), [{number, String.t(), number}], keyword) :: String.t()
  def radial_gradient(id, stops, opts \\ []) do
    cx = Keyword.get(opts, :cx, "50%")
    cy = Keyword.get(opts, :cy, "50%")
    r = Keyword.get(opts, :r, "50%")
    fx = Keyword.get(opts, :fx, cx)
    fy = Keyword.get(opts, :fy, cy)

    stops_str =
      Enum.map_join(stops, "\n", fn {offset, color, opacity} ->
        "<stop offset=\"#{offset}%\" stop-color=\"#{color}\" stop-opacity=\"#{opacity}\"/>"
      end)

    """
    <radialGradient id="#{id}" cx="#{cx}" cy="#{cy}" r="#{r}" fx="#{fx}" fy="#{fy}">
      #{stops_str}
    </radialGradient>
    """
  end

  @doc """
  Creates filter definitions section for inclusion in SVG.

  Takes a list of filter definition strings and wraps them in a <defs> section.

  ## Examples

      iex> filters = [SVGBuilder.blur_filter("blur1", 2), SVGBuilder.glow_filter("glow1", "#fff", 3)]
      iex> SVGBuilder.filter_defs(filters)
      "<defs>...</defs>"
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

  ## Examples

      iex> gradients = [SVGBuilder.linear_gradient("g1", [{0, "#000", 1}, {100, "#fff", 1}])]
      iex> filters = [SVGBuilder.blur_filter("blur1", 2)]
      iex> SVGBuilder.defs(gradients, filters)
      "<defs>...</defs>"
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
  Helper to apply a filter to an element by adding filter attribute.

  ## Examples

      iex> circle = SVGBuilder.circle(100, 100, 50)
      iex> SVGBuilder.with_filter(circle, "blur1")
      %{...attrs: %{...filter: "url(#blur1)"}}
  """
  @spec with_filter(element, String.t()) :: element
  def with_filter(element, filter_id) do
    with_attrs(element, %{filter: "url(##{filter_id})"})
  end

  @doc """
  Builds SVG with optional filter and gradient definitions.

  Enhanced version of build_svg that supports both filters and gradients.

  ## Options

    * `:width` - SVG width (default: 1200)
    * `:height` - SVG height (default: 630)
    * `:background` - Background color (default: "#000000")
    * `:animations` - CSS animation styles (default: "")
    * `:filters` - List of filter definition strings (default: [])
    * `:gradients` - List of gradient definition strings (default: [])

  ## Examples

      iex> elements = [SVGBuilder.circle(100, 100, 50) |> SVGBuilder.with_filter("blur1")]
      iex> filters = [SVGBuilder.blur_filter("blur1", 2)]
      iex> gradients = [SVGBuilder.linear_gradient("grad1", [{0, "#000", 1}, {100, "#fff", 1}])]
      iex> svg = SVGBuilder.build_svg_with_filters(elements, filters: filters, gradients: gradients)
      iex> String.contains?(svg, "<filter")
      true
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
