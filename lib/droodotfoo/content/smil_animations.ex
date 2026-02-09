defmodule Droodotfoo.Content.SMILAnimations do
  @moduledoc """
  SMIL animation generators for SVG patterns.

  SMIL (Synchronized Multimedia Integration Language) animations are
  embedded directly in SVG elements and work without CSS, making them
  ideal for social cards and static image contexts like OG images.

  Unlike CSS animations, SMIL animations are:
  - Self-contained within the SVG
  - Supported in most image viewers
  - Don't require external stylesheets
  """

  @doc """
  Creates a SMIL opacity animation element.

  ## Options

    * `:from` - Starting opacity (default: 0.3)
    * `:to` - Ending opacity (default: 0.8)
    * `:dur` - Duration in seconds (default: 2)
    * `:begin` - Delay before start (default: "0s")
    * `:values` - Custom keyframe values (overrides from/to)
  """
  @spec opacity(keyword) :: String.t()
  def opacity(opts \\ []) do
    from = Keyword.get(opts, :from, 0.3)
    to = Keyword.get(opts, :to, 0.8)
    dur = Keyword.get(opts, :dur, 2)
    begin_time = Keyword.get(opts, :begin, "0s")
    values = Keyword.get(opts, :values)

    values_attr =
      if values do
        ~s(values="#{Enum.join(values, ";")}")
      else
        ~s(values="#{from};#{to};#{from}")
      end

    """
    <animate attributeName="opacity" #{values_attr} dur="#{dur}s" begin="#{begin_time}" repeatCount="indefinite"/>
    """
  end

  @doc """
  Creates a SMIL transform animation element.

  ## Options

    * `:type` - Transform type (translate, scale, rotate)
    * `:from` - Starting value
    * `:to` - Ending value
    * `:dur` - Duration in seconds
    * `:begin` - Delay before start
  """
  @spec transform(keyword) :: String.t()
  def transform(opts \\ []) do
    type = Keyword.get(opts, :type, "scale")
    from = Keyword.get(opts, :from, "1")
    to = Keyword.get(opts, :to, "1.1")
    dur = Keyword.get(opts, :dur, 3)
    begin_time = Keyword.get(opts, :begin, "0s")
    values = Keyword.get(opts, :values)

    values_attr =
      if values do
        ~s(values="#{Enum.join(values, ";")}")
      else
        ~s(values="#{from};#{to};#{from}")
      end

    """
    <animateTransform attributeName="transform" type="#{type}" #{values_attr} dur="#{dur}s" begin="#{begin_time}" repeatCount="indefinite"/>
    """
  end

  @doc """
  Creates a SMIL stroke-dashoffset animation for line drawing effects.

  ## Options

    * `:from` - Starting offset
    * `:to` - Ending offset
    * `:dur` - Duration in seconds
    * `:begin` - Delay before start
  """
  @spec stroke_dash(keyword) :: String.t()
  def stroke_dash(opts \\ []) do
    from = Keyword.get(opts, :from, 1000)
    to = Keyword.get(opts, :to, 0)
    dur = Keyword.get(opts, :dur, 5)
    begin_time = Keyword.get(opts, :begin, "0s")

    """
    <animate attributeName="stroke-dashoffset" from="#{from}" to="#{to}" dur="#{dur}s" begin="#{begin_time}" repeatCount="indefinite"/>
    """
  end

  @doc """
  Creates a SMIL color animation.

  ## Options

    * `:attribute` - Attribute to animate (fill, stroke)
    * `:values` - List of color values to cycle through
    * `:dur` - Duration in seconds
  """
  @spec color(keyword) :: String.t()
  def color(opts \\ []) do
    attribute = Keyword.get(opts, :attribute, "stroke")
    values = Keyword.get(opts, :values, ["#ffffff", "#cccccc", "#ffffff"])
    dur = Keyword.get(opts, :dur, 4)

    """
    <animate attributeName="#{attribute}" values="#{Enum.join(values, ";")}" dur="#{dur}s" repeatCount="indefinite"/>
    """
  end

  @doc """
  Creates a pulse animation combining scale and opacity.
  Returns both animate elements as a single string.
  """
  @spec pulse(keyword) :: String.t()
  def pulse(opts \\ []) do
    dur = Keyword.get(opts, :dur, 3)
    begin_time = Keyword.get(opts, :begin, "0s")
    scale_range = Keyword.get(opts, :scale_range, {0.95, 1.05})
    opacity_range = Keyword.get(opts, :opacity_range, {0.4, 0.8})

    {scale_min, scale_max} = scale_range
    {opacity_min, opacity_max} = opacity_range

    """
    <animateTransform attributeName="transform" type="scale" values="#{scale_min};#{scale_max};#{scale_min}" dur="#{dur}s" begin="#{begin_time}" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="#{opacity_min};#{opacity_max};#{opacity_min}" dur="#{dur}s" begin="#{begin_time}" repeatCount="indefinite"/>
    """
  end

  @doc """
  Creates a floating animation with vertical movement.
  """
  @spec float(keyword) :: String.t()
  def float(opts \\ []) do
    dur = Keyword.get(opts, :dur, 4)
    begin_time = Keyword.get(opts, :begin, "0s")
    amplitude = Keyword.get(opts, :amplitude, 5)

    """
    <animateTransform attributeName="transform" type="translate" values="0,0;0,#{-amplitude};0,0;0,#{amplitude};0,0" dur="#{dur}s" begin="#{begin_time}" repeatCount="indefinite"/>
    """
  end

  @doc """
  Creates a rotation animation.
  """
  @spec rotate(keyword) :: String.t()
  def rotate(opts \\ []) do
    dur = Keyword.get(opts, :dur, 10)
    begin_time = Keyword.get(opts, :begin, "0s")
    from = Keyword.get(opts, :from, 0)
    to = Keyword.get(opts, :to, 360)
    cx = Keyword.get(opts, :cx, 0)
    cy = Keyword.get(opts, :cy, 0)

    """
    <animateTransform attributeName="transform" type="rotate" from="#{from} #{cx} #{cy}" to="#{to} #{cx} #{cy}" dur="#{dur}s" begin="#{begin_time}" repeatCount="indefinite"/>
    """
  end

  @doc """
  Creates a wave morphing animation for path elements.
  Uses path d attribute animation.
  """
  @spec morph(String.t(), String.t(), keyword) :: String.t()
  def morph(path1, path2, opts \\ []) do
    dur = Keyword.get(opts, :dur, 5)
    begin_time = Keyword.get(opts, :begin, "0s")

    """
    <animate attributeName="d" values="#{path1};#{path2};#{path1}" dur="#{dur}s" begin="#{begin_time}" repeatCount="indefinite"/>
    """
  end

  @doc """
  Wraps SVG content in a group with SMIL animations applied.
  """
  @spec animated_group(String.t(), [String.t()]) :: String.t()
  def animated_group(content, animations) do
    animations_str = Enum.join(animations, "\n")

    """
    <g>
      #{animations_str}
      #{content}
    </g>
    """
  end

  @doc """
  Generates staggered delay value for indexed elements.
  """
  @spec stagger_delay(integer, number) :: String.t()
  def stagger_delay(index, interval \\ 0.2) do
    delay = index * interval
    "#{delay}s"
  end
end
