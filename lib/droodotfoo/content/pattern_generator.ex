defmodule Droodotfoo.Content.PatternGenerator do
  @moduledoc """
  Generates deterministic black and white SVG patterns for blog posts.
  Each post gets a unique generative art pattern based on its slug,
  perfect for social sharing cards.
  """

  @doc """
  Generates an SVG pattern based on the post slug.

  ## Options

    * `:width` - Image width in pixels (default: 1200)
    * `:height` - Image height in pixels (default: 630)
    * `:style` - Pattern style (default: random based on slug)
      - `:waves` - Flowing sine waves
      - `:noise` - Static/TV noise effect
      - `:lines` - Parallel or radiating lines
      - `:dots` - Halftone dot matrix
      - `:circuit` - Circuit board traces
      - `:glitch` - Corrupted data/glitch art
      - `:geometric` - Classic geometric shapes
      - `:grid` - Cellular grid pattern

  ## Examples

      iex> PatternGenerator.generate_svg("my-post-slug")
      "<?xml version=\\"1.0\\"...>"

      iex> PatternGenerator.generate_svg("my-post", style: :waves)
      "<?xml version=\\"1.0\\"...>"
  """
  def generate_svg(slug, opts \\ []) do
    width = Keyword.get(opts, :width, 1200)
    height = Keyword.get(opts, :height, 630)
    animate = Keyword.get(opts, :animate, false)

    # Use slug hash as deterministic seed
    seed = :erlang.phash2(slug)
    :rand.seed(:exsplus, {seed, seed, seed})

    # Choose style based on slug if not specified
    style = Keyword.get(opts, :style) || choose_style(slug)

    # Generate pattern based on style
    pattern_elements =
      case style do
        :waves -> generate_waves(width, height, slug, animate)
        :noise -> generate_noise(width, height, animate)
        :lines -> generate_lines(width, height, animate)
        :dots -> generate_dots(width, height, animate)
        :circuit -> generate_circuit(width, height, animate)
        :glitch -> generate_glitch(width, height, animate)
        :geometric -> generate_geometric(width, height, animate)
        :grid -> generate_grid(width, height, animate)
        _ -> generate_waves(width, height, slug, animate)
      end

    # Add CSS animations if enabled
    animations = if animate, do: generate_css_animations(style), else: ""

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{width} #{height}" preserveAspectRatio="none" style="width: 100%; height: 100%; display: block;">
      #{animations}
      <rect width="#{width}" height="#{height}" fill="#000000"/>
      #{pattern_elements}
    </svg>
    """
  end

  # Choose a style deterministically based on slug
  defp choose_style(slug) do
    styles = [:waves, :noise, :lines, :dots, :circuit, :glitch, :geometric, :grid]
    hash = :erlang.phash2(slug)
    index = rem(hash, length(styles))
    Enum.at(styles, index)
  end

  # Generate flowing sine waves
  defp generate_waves(width, height, slug, animate) do
    num_waves = 20 + rem(:erlang.phash2(slug), 15)

    waves =
      for i <- 1..num_waves do
        amplitude = :rand.uniform(50) + 20
        frequency = :rand.uniform() * 0.01 + 0.002
        phase = :rand.uniform() * :math.pi() * 2
        y_offset = :rand.uniform(height)
        opacity = :rand.uniform() * 0.3 + 0.1

        # Generate smooth path for wave
        points =
          for x <- 0..width//10 do
            y = y_offset + amplitude * :math.sin(frequency * x + phase)
            "#{x},#{y}"
          end

        path_data = "M " <> Enum.join(points, " L ")

        # Add animation class if enabled
        anim_class = if animate, do: " class=\"wave-#{rem(i, 3)}\"", else: ""
        "<path#{anim_class} d=\"#{path_data}\" stroke=\"#ffffff\" stroke-width=\"2\" fill=\"none\" opacity=\"#{opacity}\"/>"
      end

    Enum.join(waves, "\n")
  end

  # Generate TV static / noise effect
  defp generate_noise(width, height, animate) do
    cell_size = 8
    cols = div(width, cell_size) + 1
    rows = div(height, cell_size) + 1

    cells =
      for row <- 0..(rows - 1), col <- 0..(cols - 1) do
        x = col * cell_size
        y = row * cell_size

        # Random brightness for each cell
        brightness = :rand.uniform()

        if brightness > 0.5 do
          opacity = (brightness - 0.5) * 2
          # Add animation class if enabled
          anim_class = if animate, do: " class=\"noise-cell\"", else: ""
          "<rect#{anim_class} x=\"#{x}\" y=\"#{y}\" width=\"#{cell_size}\" height=\"#{cell_size}\" fill=\"#ffffff\" opacity=\"#{opacity}\"/>"
        else
          ""
        end
      end

    Enum.join(cells, "\n")
  end

  # Generate parallel or radiating lines
  defp generate_lines(width, height, animate) do
    pattern_choice = rem(:rand.uniform(100), 2)

    case pattern_choice do
      0 -> generate_parallel_lines(width, height, animate)
      _ -> generate_radial_lines(width, height, animate)
    end
  end

  defp generate_parallel_lines(width, height, animate) do
    num_lines = 40

    lines =
      for i <- 0..(num_lines - 1) do
        spacing = width / num_lines
        offset = i * spacing
        thickness = :rand.uniform(3) + 1
        opacity = :rand.uniform() * 0.4 + 0.2

        # Vertical lines without rotation
        x1 = offset
        y1 = 0
        x2 = offset
        y2 = height

        # Add animation class if enabled
        anim_class = if animate, do: " class=\"line-pulse\"", else: ""
        "<line#{anim_class} x1=\"#{x1}\" y1=\"#{y1}\" x2=\"#{x2}\" y2=\"#{y2}\" stroke=\"#ffffff\" stroke-width=\"#{thickness}\" opacity=\"#{opacity}\"/>"
      end

    Enum.join(lines, "\n")
  end

  defp generate_radial_lines(width, height, animate) do
    center_x = width / 2
    center_y = height / 2
    num_lines = 60

    lines =
      for i <- 0..(num_lines - 1) do
        angle = i * (360 / num_lines)
        angle_rad = angle * :math.pi() / 180

        # Calculate end point
        length = max(width, height)
        x2 = center_x + length * :math.cos(angle_rad)
        y2 = center_y + length * :math.sin(angle_rad)

        thickness = :rand.uniform(2) + 0.5
        opacity = :rand.uniform() * 0.3 + 0.1

        # Add animation class if enabled
        anim_class = if animate, do: " class=\"line-pulse\"", else: ""
        "<line#{anim_class} x1=\"#{center_x}\" y1=\"#{center_y}\" x2=\"#{x2}\" y2=\"#{y2}\" stroke=\"#ffffff\" stroke-width=\"#{thickness}\" opacity=\"#{opacity}\"/>"
      end

    Enum.join(lines, "\n")
  end

  # Generate halftone dot matrix
  defp generate_dots(width, height, animate) do
    dot_spacing = 20
    cols = div(width, dot_spacing) + 1
    rows = div(height, dot_spacing) + 1

    dots =
      for row <- 0..(rows - 1), col <- 0..(cols - 1) do
        x = col * dot_spacing
        y = row * dot_spacing

        # Create gradient effect from top-left to bottom-right
        distance = :math.sqrt(:math.pow(x - width / 2, 2) + :math.pow(y - height / 2, 2))
        max_distance = :math.sqrt(:math.pow(width / 2, 2) + :math.pow(height / 2, 2))
        size_factor = 1 - distance / max_distance

        # Add some randomness
        size_factor = size_factor * (:rand.uniform() * 0.5 + 0.5)

        radius = max(1, size_factor * (dot_spacing / 2))

        if radius > 1 do
          # Add animation class if enabled
          anim_class = if animate, do: " class=\"dot-pulse\"", else: ""
          "<circle#{anim_class} cx=\"#{x}\" cy=\"#{y}\" r=\"#{radius}\" fill=\"#ffffff\" opacity=\"0.8\"/>"
        else
          ""
        end
      end

    Enum.join(dots, "\n")
  end

  # Generate circuit board traces
  defp generate_circuit(width, height, animate) do
    num_traces = 50

    traces =
      for _ <- 1..num_traces do
        # Start point
        x = :rand.uniform(width)
        y = :rand.uniform(height)

        # Generate path with right angles (like circuit traces)
        segments = 3 + :rand.uniform(5)

        path_points =
          Enum.reduce(1..segments, [{x, y}], fn _, acc ->
            [{last_x, last_y} | _] = acc

            # Move horizontally or vertically
            length = :rand.uniform(150) + 50

            {new_x, new_y} =
              if rem(:rand.uniform(100), 2) == 0 do
                # Horizontal
                if :rand.uniform() > 0.5,
                  do: {last_x + length, last_y},
                  else: {last_x - length, last_y}
              else
                # Vertical
                if :rand.uniform() > 0.5,
                  do: {last_x, last_y + length},
                  else: {last_x, last_y - length}
              end

            [{new_x, new_y} | acc]
          end)
          |> Enum.reverse()

        path_data =
          path_points
          |> Enum.map(fn {px, py} -> "#{px},#{py}" end)
          |> Enum.join(" L ")

        path_data = "M " <> path_data

        thickness = :rand.uniform(3) + 1
        opacity = :rand.uniform() * 0.3 + 0.2

        # Add animation class if enabled
        anim_class = if animate, do: " class=\"circuit-glow\"", else: ""
        "<path#{anim_class} d=\"#{path_data}\" stroke=\"#ffffff\" stroke-width=\"#{thickness}\" fill=\"none\" opacity=\"#{opacity}\" stroke-linecap=\"square\"/>"
      end

    Enum.join(traces, "\n")
  end

  # Generate glitch art effect
  defp generate_glitch(width, height, animate) do
    num_bars = 30

    bars =
      for _ <- 1..num_bars do
        x = :rand.uniform(width)
        y = :rand.uniform(height)
        w = :rand.uniform(300) + 50
        h = :rand.uniform(15) + 2
        opacity = :rand.uniform() * 0.4 + 0.1

        # Sometimes add offset for glitch effect
        offset_x = if :rand.uniform() > 0.7, do: :rand.uniform(20) - 10, else: 0

        # Add animation class if enabled
        anim_class = if animate, do: " class=\"glitch-bar\"", else: ""
        "<rect#{anim_class} x=\"#{x + offset_x}\" y=\"#{y}\" width=\"#{w}\" height=\"#{h}\" fill=\"#ffffff\" opacity=\"#{opacity}\"/>"
      end

    # Add some vertical scanlines
    scanlines =
      for i <- 0..10 do
        x = i * (width / 10)
        opacity = :rand.uniform() * 0.1 + 0.05
        anim_class = if animate, do: " class=\"scanline\"", else: ""
        "<line#{anim_class} x1=\"#{x}\" y1=\"0\" x2=\"#{x}\" y2=\"#{height}\" stroke=\"#ffffff\" stroke-width=\"1\" opacity=\"#{opacity}\"/>"
      end

    Enum.join(bars ++ scanlines, "\n")
  end

  # Generate geometric shapes
  defp generate_geometric(width, height, animate) do
    shapes =
      for _ <- 1..20 do
        x = :rand.uniform(width)
        y = :rand.uniform(height)
        size = :rand.uniform(150) + 30
        opacity = :rand.uniform() * 0.3 + 0.1

        shape_type = Enum.random([:circle, :rect, :triangle])

        anim_class = if animate, do: " class=\"shape-rotate\"", else: ""

        case shape_type do
          :circle ->
            radius = size / 2
            "<circle#{anim_class} cx=\"#{x}\" cy=\"#{y}\" r=\"#{radius}\" fill=\"none\" stroke=\"#ffffff\" stroke-width=\"2\" opacity=\"#{opacity}\"/>"

          :rect ->
            rotation = :rand.uniform(360)
            center_x = x + size / 2
            center_y = y + size / 2
            "<rect#{anim_class} x=\"#{x}\" y=\"#{y}\" width=\"#{size}\" height=\"#{size}\" fill=\"none\" stroke=\"#ffffff\" stroke-width=\"2\" opacity=\"#{opacity}\" transform=\"rotate(#{rotation} #{center_x} #{center_y})\"/>"

          :triangle ->
            x1 = x
            y1 = y
            x2 = x + size
            y2 = y
            x3 = x + size / 2
            y3 = y + size
            "<polygon#{anim_class} points=\"#{x1},#{y1} #{x2},#{y2} #{x3},#{y3}\" fill=\"none\" stroke=\"#ffffff\" stroke-width=\"2\" opacity=\"#{opacity}\"/>"
        end
      end

    Enum.join(shapes, "\n")
  end

  # Generate cellular grid
  defp generate_grid(width, height, animate) do
    cell_size = 40
    cols = div(width, cell_size) + 1
    rows = div(height, cell_size) + 1

    cells =
      for row <- 0..(rows - 1), col <- 0..(cols - 1) do
        x = col * cell_size
        y = row * cell_size

        # Create interesting pattern based on position
        fill_chance = :math.sin((col + row) / 3) * 0.5 + 0.5

        if :rand.uniform() < fill_chance do
          opacity = :rand.uniform() * 0.4 + 0.2
          # Add animation class if enabled
          anim_class = if animate, do: " class=\"grid-cell\"", else: ""
          "<rect#{anim_class} x=\"#{x}\" y=\"#{y}\" width=\"#{cell_size}\" height=\"#{cell_size}\" fill=\"#ffffff\" opacity=\"#{opacity}\"/>"
        else
          ""
        end
      end

    Enum.join(cells, "\n")
  end

  # Generate CSS animations based on style
  defp generate_css_animations(style) do
    case style do
      :waves ->
        """
        <style>
          @keyframes wave-morph-1 {
            0% { transform: translateX(0) translateY(0) scaleY(1); opacity: 0.7; filter: blur(0px); }
            15% { transform: translateX(10px) translateY(-5px) scaleY(1.05); opacity: 0.85; filter: blur(0.3px); }
            30% { transform: translateX(25px) translateY(-2px) scaleY(0.95); opacity: 1; filter: blur(0px); }
            45% { transform: translateX(35px) translateY(2px) scaleY(1.03); opacity: 0.9; filter: blur(0.2px); }
            60% { transform: translateX(25px) translateY(5px) scaleY(1); opacity: 0.8; filter: blur(0px); }
            75% { transform: translateX(10px) translateY(3px) scaleY(0.98); opacity: 0.85; filter: blur(0.1px); }
            100% { transform: translateX(0) translateY(0) scaleY(1); opacity: 0.7; filter: blur(0px); }
          }
          @keyframes wave-morph-2 {
            0% { transform: translateX(0) translateY(0) scaleY(1) rotate(0deg); opacity: 0.8; }
            20% { transform: translateX(-8px) translateY(3px) scaleY(1.04) rotate(-1deg); opacity: 0.95; }
            40% { transform: translateX(-18px) translateY(-2px) scaleY(0.96) rotate(0deg); opacity: 1; }
            60% { transform: translateX(-28px) translateY(2px) scaleY(1.02) rotate(1deg); opacity: 0.9; }
            80% { transform: translateX(-15px) translateY(-1px) scaleY(0.98) rotate(-0.5deg); opacity: 0.85; }
            100% { transform: translateX(0) translateY(0) scaleY(1) rotate(0deg); opacity: 0.8; }
          }
          @keyframes wave-morph-3 {
            0% { transform: translateX(0) scale(1) rotate(0deg); opacity: 0.6; filter: blur(0px); }
            25% { transform: translateX(12px) scale(1.05) rotate(0.5deg); opacity: 0.9; filter: blur(0.5px); }
            50% { transform: translateX(20px) scale(1.08) rotate(0deg); opacity: 1; filter: blur(0.8px); }
            75% { transform: translateX(12px) scale(1.03) rotate(-0.5deg); opacity: 0.85; filter: blur(0.4px); }
            100% { transform: translateX(0) scale(1) rotate(0deg); opacity: 0.6; filter: blur(0px); }
          }
          .wave-0 { animation: wave-morph-1 7s ease-in-out infinite; }
          .wave-1 { animation: wave-morph-2 9s ease-in-out infinite; }
          .wave-2 { animation: wave-morph-3 11s ease-in-out infinite; }
        </style>
        """

      :noise ->
        """
        <style>
          @keyframes noise-chaos {
            0% { opacity: 0.9; transform: translate(0, 0) scale(1); }
            8% { opacity: 0.2; transform: translate(1px, -1px) scale(1.05); }
            16% { opacity: 0.8; transform: translate(-1px, 1px) scale(0.95); }
            24% { opacity: 0.1; transform: translate(0, 0) scale(1); }
            32% { opacity: 1; transform: translate(1px, 0) scale(1.08); }
            40% { opacity: 0.3; transform: translate(0, 1px) scale(0.92); }
            48% { opacity: 0.95; transform: translate(-1px, 0) scale(1); }
            56% { opacity: 0.25; transform: translate(0, -1px) scale(1.05); }
            64% { opacity: 0.75; transform: translate(1px, 1px) scale(0.98); }
            72% { opacity: 0.4; transform: translate(-1px, -1px) scale(1.02); }
            80% { opacity: 0.85; transform: translate(0, 0) scale(1); }
            88% { opacity: 0.35; transform: translate(1px, -1px) scale(0.95); }
            96% { opacity: 0.6; transform: translate(0, 1px) scale(1.03); }
            100% { opacity: 0.9; transform: translate(0, 0) scale(1); }
          }
          .noise-cell {
            animation: noise-chaos 1.2s infinite;
            animation-delay: calc(var(--delay, 0) * 0.15s);
          }
        </style>
        """

      :lines ->
        """
        <style>
          @keyframes line-wave {
            0% {
              opacity: 0.2;
              transform: translateY(0) scaleX(1);
              stroke-width: 0.5;
              filter: blur(0px);
            }
            20% {
              opacity: 0.6;
              transform: translateY(-3px) scaleX(1.02);
              stroke-width: 1.5;
              filter: blur(0.2px);
            }
            40% {
              opacity: 1;
              transform: translateY(-5px) scaleX(1.05);
              stroke-width: 2.5;
              filter: blur(0px);
            }
            60% {
              opacity: 0.8;
              transform: translateY(-3px) scaleX(1.02);
              stroke-width: 2;
              filter: blur(0.3px);
            }
            80% {
              opacity: 0.4;
              transform: translateY(-1px) scaleX(1);
              stroke-width: 1;
              filter: blur(0.1px);
            }
            100% {
              opacity: 0.2;
              transform: translateY(0) scaleX(1);
              stroke-width: 0.5;
              filter: blur(0px);
            }
          }
          .line-pulse {
            animation: line-wave 5s ease-in-out infinite;
            animation-delay: calc(var(--index, 0) * 0.08s);
          }
        </style>
        """

      :dots ->
        """
        <style>
          @keyframes dot-morph {
            0% {
              transform: scale(0.8) rotate(0deg) translate(0, 0);
              opacity: 0.5;
              filter: blur(0px);
            }
            15% {
              transform: scale(1.05) rotate(15deg) translate(2px, -2px);
              opacity: 0.8;
              filter: blur(0.3px);
            }
            30% {
              transform: scale(1.25) rotate(0deg) translate(0, 0);
              opacity: 1;
              filter: blur(0.5px);
            }
            45% {
              transform: scale(1.15) rotate(-15deg) translate(-2px, 2px);
              opacity: 0.9;
              filter: blur(0.2px);
            }
            60% {
              transform: scale(0.95) rotate(-30deg) translate(0, 3px);
              opacity: 0.7;
              filter: blur(0px);
            }
            75% {
              transform: scale(1.1) rotate(10deg) translate(1px, -1px);
              opacity: 0.85;
              filter: blur(0.4px);
            }
            100% {
              transform: scale(0.8) rotate(0deg) translate(0, 0);
              opacity: 0.5;
              filter: blur(0px);
            }
          }
          .dot-pulse {
            animation: dot-morph 6s ease-in-out infinite;
            animation-delay: calc(var(--delay, 0) * 0.25s);
          }
        </style>
        """

      :circuit ->
        """
        <style>
          @keyframes circuit-energy {
            0%, 100% {
              opacity: 0.3;
              filter: drop-shadow(0 0 0px #ffffff);
              stroke-width: 0.8;
              transform: scale(1);
            }
            10% {
              opacity: 0.6;
              filter: drop-shadow(0 0 1px #ffffff);
              stroke-width: 1.2;
              transform: scale(1.01);
            }
            20% {
              opacity: 0.9;
              filter: drop-shadow(0 0 3px #ffffff) drop-shadow(0 0 6px #ffffff);
              stroke-width: 1.8;
              transform: scale(1.02);
            }
            30% {
              opacity: 1;
              filter: drop-shadow(0 0 6px #ffffff) drop-shadow(0 0 12px #ffffff) drop-shadow(0 0 18px #ffffff);
              stroke-width: 2.5;
              transform: scale(1.03);
            }
            45% {
              opacity: 0.85;
              filter: drop-shadow(0 0 4px #ffffff) drop-shadow(0 0 8px #ffffff);
              stroke-width: 2;
              transform: scale(1.01);
            }
            60% {
              opacity: 0.6;
              filter: drop-shadow(0 0 2px #ffffff);
              stroke-width: 1.5;
              transform: scale(1);
            }
            80% {
              opacity: 0.4;
              filter: drop-shadow(0 0 1px #ffffff);
              stroke-width: 1;
              transform: scale(0.99);
            }
          }
          .circuit-glow {
            animation: circuit-energy 4s ease-in-out infinite;
            animation-delay: calc(var(--index, 0) * 0.18s);
          }
        </style>
        """

      :glitch ->
        """
        <style>
          @keyframes glitch-distort {
            0%, 75%, 100% {
              transform: translateX(0) skew(0deg) scaleY(1);
              opacity: 1;
              filter: blur(0px);
            }
            76% {
              transform: translateX(-10px) skew(-8deg) scaleY(1.05);
              opacity: 0.7;
              filter: blur(0.5px);
            }
            78% {
              transform: translateX(12px) skew(10deg) scaleY(0.95);
              opacity: 0.85;
              filter: blur(0.8px);
            }
            80% {
              transform: translateX(-8px) skew(5deg) scaleY(1.08);
              opacity: 0.6;
              filter: blur(0.3px);
            }
            82% {
              transform: translateX(9px) skew(-7deg) scaleY(0.92);
              opacity: 0.9;
              filter: blur(0.6px);
            }
            84% {
              transform: translateX(-6px) skew(3deg) scaleY(1.03);
              opacity: 0.75;
              filter: blur(0.4px);
            }
            86% {
              transform: translateX(7px) skew(-4deg) scaleY(0.97);
              opacity: 0.95;
              filter: blur(0.2px);
            }
            88% {
              transform: translateX(-4px) skew(2deg) scaleY(1.02);
              opacity: 0.8;
              filter: blur(0.5px);
            }
            92% {
              transform: translateX(0) skew(0deg) scaleY(1);
              opacity: 0.9;
              filter: blur(0.1px);
            }
          }
          @keyframes scanline-flow {
            0% {
              opacity: 0.2;
              transform: translateY(-150%) scaleY(1);
              filter: blur(1px);
            }
            25% {
              opacity: 0.6;
              transform: translateY(-50%) scaleY(1.5);
              filter: blur(0.5px);
            }
            50% {
              opacity: 0.9;
              transform: translateY(0) scaleY(2);
              filter: blur(0px);
            }
            75% {
              opacity: 0.6;
              transform: translateY(50%) scaleY(1.5);
              filter: blur(0.5px);
            }
            100% {
              opacity: 0.2;
              transform: translateY(150%) scaleY(1);
              filter: blur(1px);
            }
          }
          .glitch-bar { animation: glitch-distort 5s ease-in-out infinite; }
          .scanline { animation: scanline-flow 3s linear infinite; }
        </style>
        """

      :geometric ->
        """
        <style>
          @keyframes shape-transform {
            0% {
              transform: rotate(0deg) scale(1) translate(0, 0);
              opacity: 0.6;
              filter: blur(0px);
            }
            12% {
              transform: rotate(45deg) scale(1.08) translate(2px, -2px);
              opacity: 0.8;
              filter: blur(0.2px);
            }
            25% {
              transform: rotate(90deg) scale(1.12) translate(0, 0);
              opacity: 0.95;
              filter: blur(0.4px);
            }
            37% {
              transform: rotate(135deg) scale(1.08) translate(-2px, 2px);
              opacity: 0.9;
              filter: blur(0.3px);
            }
            50% {
              transform: rotate(180deg) scale(1) translate(0, 0);
              opacity: 1;
              filter: blur(0px);
            }
            62% {
              transform: rotate(225deg) scale(1.08) translate(2px, 2px);
              opacity: 0.9;
              filter: blur(0.3px);
            }
            75% {
              transform: rotate(270deg) scale(1.12) translate(0, 0);
              opacity: 0.95;
              filter: blur(0.4px);
            }
            87% {
              transform: rotate(315deg) scale(1.08) translate(-2px, -2px);
              opacity: 0.8;
              filter: blur(0.2px);
            }
            100% {
              transform: rotate(360deg) scale(1) translate(0, 0);
              opacity: 0.6;
              filter: blur(0px);
            }
          }
          .shape-rotate {
            animation: shape-transform 18s ease-in-out infinite;
            transform-origin: center;
          }
        </style>
        """

      :grid ->
        """
        <style>
          @keyframes grid-breathe {
            0% {
              opacity: 0.3;
              transform: scale(0.95) rotate(0deg);
              filter: blur(0px);
            }
            15% {
              opacity: 0.6;
              transform: scale(0.98) rotate(0.5deg);
              filter: blur(0.1px);
            }
            30% {
              opacity: 0.85;
              transform: scale(1.02) rotate(0deg);
              filter: blur(0.2px);
            }
            50% {
              opacity: 1;
              transform: scale(1.06) rotate(-0.5deg);
              filter: blur(0.3px);
            }
            70% {
              opacity: 0.85;
              transform: scale(1.02) rotate(0deg);
              filter: blur(0.2px);
            }
            85% {
              opacity: 0.6;
              transform: scale(0.98) rotate(0.5deg);
              filter: blur(0.1px);
            }
            100% {
              opacity: 0.3;
              transform: scale(0.95) rotate(0deg);
              filter: blur(0px);
            }
          }
          .grid-cell {
            animation: grid-breathe 6s ease-in-out infinite;
            animation-delay: calc(var(--delay, 0) * 0.12s);
          }
        </style>
        """

      _ ->
        ""
    end
  end
end
