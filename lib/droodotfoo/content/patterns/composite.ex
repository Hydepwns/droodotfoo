defmodule Droodotfoo.Content.Patterns.Composite do
  @moduledoc """
  Composite pattern generator that layers multiple pattern styles.

  Combines two or more patterns to create rich, layered visual effects
  with controllable opacity and blending.
  """

  alias Droodotfoo.Content.{PatternAnimations, PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns
  alias Droodotfoo.Content.Patterns.Base

  @available_layers [:waves, :dots, :lines, :grid, :noise, :flow_field]

  @doc """
  Generates a composite layered pattern.

  ## Parameters

    * `width` - Canvas width in pixels
    * `height` - Canvas height in pixels
    * `rng` - Random generator state
    * `palette` - Color palette map with :colors list
    * `animate` - Whether to include animation classes

  ## Returns

  `{elements, new_rng}` where elements is a list of SVG element structs.
  """
  @spec generate(number, number, RandomGenerator.t(), map, boolean) ::
          {[SVGBuilder.element()], RandomGenerator.t()}
  def generate(width, height, rng, palette, animate \\ false) do
    config = PatternConfig.composite_config()

    # Determine number of layers
    {layer_count, rng} = RandomGenerator.uniform_range(rng, config.layer_count)
    layer_count = trunc(layer_count)

    # Select which patterns to layer
    {layers, rng} = select_layers(rng, layer_count)

    # Generate each layer with decreasing opacity
    {layer_elements, rng} =
      layers
      |> Enum.with_index()
      |> Enum.map_reduce(rng, fn {layer_style, index}, acc_rng ->
        # Calculate layer opacity (base layer full, subsequent layers reduced)
        base_opacity = if index == 0, do: 1.0, else: 0.3 + 0.2 * (1 / (index + 1))

        # Generate the layer pattern
        {elements, acc_rng} =
          generate_layer(
            layer_style,
            width,
            height,
            acc_rng,
            palette,
            animate,
            base_opacity
          )

        {elements, acc_rng}
      end)

    {List.flatten(layer_elements), rng}
  end

  defp select_layers(rng, count) do
    Enum.map_reduce(1..count, rng, fn _i, acc_rng ->
      RandomGenerator.choice(acc_rng, @available_layers)
    end)
  end

  defp generate_layer(style, width, height, rng, palette, animate, opacity_mult) do
    # Generate the base pattern
    {elements, rng} =
      case style do
        :waves -> Patterns.Waves.generate(width, height, rng, palette, animate)
        :dots -> Patterns.Dots.generate(width, height, rng, palette, animate)
        :lines -> Patterns.Lines.generate(width, height, rng, palette, animate)
        :grid -> Patterns.Grid.generate(width, height, rng, palette, animate)
        :noise -> Patterns.Noise.generate(width, height, rng, palette, animate)
        :flow_field -> Patterns.FlowField.generate(width, height, rng, palette, animate)
        _ -> Patterns.Waves.generate(width, height, rng, palette, animate)
      end

    # Adjust opacity of all elements in this layer
    elements = adjust_layer_opacity(elements, opacity_mult)

    {elements, rng}
  end

  defp adjust_layer_opacity(elements, opacity_mult) when is_list(elements) do
    Enum.map(elements, fn element ->
      current_opacity =
        case Map.get(element.attrs, :opacity) do
          nil -> 1.0
          val when is_binary(val) -> String.to_float(val)
          val when is_number(val) -> val
        end

      new_opacity = current_opacity * opacity_mult
      SVGBuilder.with_attrs(element, %{opacity: new_opacity})
    end)
  end

  @doc """
  Generates a composite pattern with specific layer styles.

  ## Parameters

    * `width` - Canvas width in pixels
    * `height` - Canvas height in pixels
    * `rng` - Random generator state
    * `palette` - Color palette map
    * `animate` - Whether to animate
    * `layer_styles` - List of pattern style atoms to layer

  ## Returns

  `{elements, new_rng}`
  """
  @spec generate_with_layers(number, number, RandomGenerator.t(), map, boolean, [atom]) ::
          {[SVGBuilder.element()], RandomGenerator.t()}
  def generate_with_layers(width, height, rng, palette, animate, layer_styles) do
    {layer_elements, rng} =
      layer_styles
      |> Enum.with_index()
      |> Enum.map_reduce(rng, fn {layer_style, index}, acc_rng ->
        base_opacity = if index == 0, do: 1.0, else: 0.4
        generate_layer(layer_style, width, height, acc_rng, palette, animate, base_opacity)
      end)

    {List.flatten(layer_elements), rng}
  end

  @doc """
  Convenience function to generate and render composite pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    rng = RandomGenerator.new(slug)
    {_name, palette} = Base.choose_palette(:composite, slug, tags)
    {elements, _rng} = generate(width, height, rng, palette, animate)

    animations =
      if animate do
        Enum.map_join(@available_layers, "\n", &PatternAnimations.get_animations/1)
      else
        ""
      end

    SVGBuilder.build_svg(elements,
      width: width,
      height: height,
      background: palette.bg,
      animations: animations
    )
  end

  @doc """
  Generate with explicit layer combination.
  """
  @spec generate_svg_with_layers(String.t(), number, number, boolean, [String.t()], [atom]) ::
          String.t()
  def generate_svg_with_layers(slug, width, height, animate, tags, layer_styles) do
    rng = RandomGenerator.new(slug)
    {_name, palette} = Base.choose_palette(:composite, slug, tags)
    {elements, _rng} = generate_with_layers(width, height, rng, palette, animate, layer_styles)

    animations =
      if animate do
        Enum.map_join(layer_styles, "\n", &PatternAnimations.get_animations/1)
      else
        ""
      end

    SVGBuilder.build_svg(elements,
      width: width,
      height: height,
      background: palette.bg,
      animations: animations
    )
  end
end
