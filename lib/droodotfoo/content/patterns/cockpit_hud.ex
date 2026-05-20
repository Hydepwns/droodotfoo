defmodule Droodotfoo.Content.Patterns.CockpitHud do
  @moduledoc """
  Cockpit HUD pattern generator.

  Visual language: a mecha pilot's POV through the visor. The frame is a
  curved dark bezel at top and bottom (the helmet/cockpit rim); inside
  the opening, a wireframe scanning grid sits under a tight reticle.
  Left status readouts and right LED indicator cells flank the grid. A
  horizontal scan beam sweeps through it continuously.

  Always renders pure monochrome (white on black) regardless of post
  tags -- cockpit HUDs are not where accent colors belong.
  """

  alias Droodotfoo.Content.{PatternAnimations, PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  @forced_palette :pure_mono
  @stroke_effect %{"vector-effect": "non-scaling-stroke"}
  @mono_font "'Monaspace Argon', 'JetBrains Mono', ui-monospace, monospace"
  @bg "#000000"

  @status_lines [
    "FRAME XXXG-00W0",
    "PILOT 01-HEERO",
    "MASS BALANCE 1.02",
    "NEURO-LINK ENGAGED",
    "GENERATOR 98/100%",
    "OP METEOR // GO"
  ]

  @indicator_labels ["PWR", "GEN", "NAV", "COM", "SYS"]

  @spec generate(number, number, RandomGenerator.t(), map, boolean) ::
          {[SVGBuilder.element()], RandomGenerator.t()}
  def generate(width, height, rng, palette, animate \\ false) do
    config = PatternConfig.cockpit_hud_config()
    stroke = primary_stroke(palette)

    {scanlines, rng} = build_scanlines(width, height, config, stroke, rng)
    visor_masks = build_visor_masks(width, height, config)
    marquee = build_zero_marquee(width, height, config, stroke, animate)
    {status_block, rng} = build_status_block(config, stroke, rng, animate)
    {indicator_panel, rng} = build_indicator_panel(width, config, stroke, rng, animate)
    grid = build_central_grid(width, height, config, stroke, animate)
    {grid_overlay, rng} = build_grid_overlay(width, height, config, stroke, rng)
    {telemetry, rng} = build_telemetry_strip(width, height, config, stroke, rng, animate)
    reticle = build_lock_indicator(width, height, config, stroke, animate)
    visor_edges = build_visor_edges(width, height, config, stroke)

    elements =
      scanlines ++
        visor_masks ++
        marquee ++
        status_block ++
        indicator_panel ++
        grid ++
        grid_overlay ++
        telemetry ++
        reticle ++
        visor_edges

    {elements, rng}
  end

  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, _tags) do
    {:ok, palette} = PatternConfig.get_palette(@forced_palette)
    rng = RandomGenerator.new(slug)
    {elements, _rng} = generate(width, height, rng, palette, animate)
    animations = if animate, do: PatternAnimations.get_animations(:cockpit_hud), else: ""

    SVGBuilder.build_svg(elements,
      width: width,
      height: height,
      background: palette.bg,
      animations: animations
    )
  end

  defp primary_stroke(palette), do: List.first(palette.colors) || "#ffffff"

  # ---------------------------------------------------------------------------
  # Scanlines: ambient texture under everything.
  # ---------------------------------------------------------------------------
  defp build_scanlines(width, height, config, stroke, rng) do
    spacing = config.scanline_spacing
    opacity = config.scanline_opacity
    count = div(trunc(height), spacing)

    lines =
      for i <- 1..count do
        y = i * spacing

        SVGBuilder.line(0, y, width, y)
        |> SVGBuilder.with_attrs(
          Map.merge(@stroke_effect, %{
            stroke: stroke,
            "stroke-width": 1,
            opacity: opacity
          })
        )
      end

    {lines, rng}
  end

  # ---------------------------------------------------------------------------
  # Visor masks: filled bg shapes that punch out scanlines outside the visor.
  # The quadratic curve at center sweeps down to apex_y, framing the opening.
  # ---------------------------------------------------------------------------
  defp build_visor_masks(width, height, config) do
    corner = config.visor_corner_y
    apex = config.visor_apex_y
    cx = width / 2

    top =
      SVGBuilder.path(
        "M 0 0 L #{width} 0 L #{width} #{corner} " <>
          "Q #{cx} #{apex} 0 #{corner} Z"
      )
      |> SVGBuilder.with_attrs(%{fill: @bg, stroke: "none"})

    bot_corner = height - corner
    bot_apex = height - apex

    bottom =
      SVGBuilder.path(
        "M 0 #{height} L #{width} #{height} L #{width} #{bot_corner} " <>
          "Q #{cx} #{bot_apex} 0 #{bot_corner} Z"
      )
      |> SVGBuilder.with_attrs(%{fill: @bg, stroke: "none"})

    [top, bottom]
  end

  # Visor inner edges: the stroked rim of the helmet opening.
  defp build_visor_edges(width, height, config, stroke) do
    corner = config.visor_corner_y
    apex = config.visor_apex_y
    cx = width / 2

    top_rim =
      SVGBuilder.path("M 0 #{corner} Q #{cx} #{apex} #{width} #{corner}")
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{
          fill: "none",
          stroke: stroke,
          "stroke-width": 1.5,
          opacity: 0.55
        })
      )

    bot_corner = height - corner
    bot_apex = height - apex

    bottom_rim =
      SVGBuilder.path("M 0 #{bot_corner} Q #{cx} #{bot_apex} #{width} #{bot_corner}")
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{
          fill: "none",
          stroke: stroke,
          "stroke-width": 1.5,
          opacity: 0.55
        })
      )

    # Inner highlight: faint companion curves 6px inside the rim for thickness.
    top_inner =
      SVGBuilder.path("M 0 #{corner + 6} Q #{cx} #{apex - 8} #{width} #{corner + 6}")
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{
          fill: "none",
          stroke: stroke,
          "stroke-width": 1,
          opacity: 0.22
        })
      )

    bottom_inner =
      SVGBuilder.path("M 0 #{bot_corner - 6} Q #{cx} #{bot_apex + 8} #{width} #{bot_corner - 6}")
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{
          fill: "none",
          stroke: stroke,
          "stroke-width": 1,
          opacity: 0.22
        })
      )

    [top_rim, top_inner, bottom_rim, bottom_inner]
  end

  # ---------------------------------------------------------------------------
  # ZERO SYSTEM marquee: bracketed header sitting in the top of the grid as
  # a title bar, with an integrated ruler tape strip carrying tick marks
  # below it. Positioned relative to the grid (not the visor) so it reads
  # as part of the screen, not floating in the helmet rim.
  # ---------------------------------------------------------------------------
  defp build_zero_marquee(width, height, config, stroke, animate) do
    gh = config.grid_height
    gy = (height - gh) / 2
    y = gy + config.marquee_offset
    cx = width / 2
    font_size = config.marquee_font_size

    marquee_text =
      text_node(cx, y, "ZERO SYSTEM // ENGAGED", %{
        fill: stroke,
        opacity: 0.95,
        "font-size": font_size,
        "font-weight": "700",
        "letter-spacing": "0.22em",
        "text-anchor": "middle"
      })
      |> Base.maybe_animate(animate, "cockpit-marquee")

    bracket_inset = config.marquee_bracket_inset
    bracket_arm = config.marquee_bracket_arm
    bracket_top = y - font_size + 4
    bracket_bot = y + 6

    bracket_attrs =
      Map.merge(@stroke_effect, %{
        fill: "none",
        stroke: stroke,
        "stroke-width": 2,
        opacity: 0.9
      })

    left_bracket =
      SVGBuilder.path(
        "M #{cx - bracket_inset + bracket_arm} #{bracket_top} " <>
          "L #{cx - bracket_inset} #{bracket_top} " <>
          "L #{cx - bracket_inset} #{bracket_bot} " <>
          "L #{cx - bracket_inset + bracket_arm} #{bracket_bot}"
      )
      |> SVGBuilder.with_attrs(bracket_attrs)
      |> Base.maybe_animate(animate, "cockpit-marquee")

    right_bracket =
      SVGBuilder.path(
        "M #{cx + bracket_inset - bracket_arm} #{bracket_top} " <>
          "L #{cx + bracket_inset} #{bracket_top} " <>
          "L #{cx + bracket_inset} #{bracket_bot} " <>
          "L #{cx + bracket_inset - bracket_arm} #{bracket_bot}"
      )
      |> SVGBuilder.with_attrs(bracket_attrs)
      |> Base.maybe_animate(animate, "cockpit-marquee")

    tape_y = y + 20
    tape_left = cx - bracket_inset
    tape_right = cx + bracket_inset
    tick_count = config.marquee_ticks
    tick_spacing = (tape_right - tape_left) / tick_count

    tape_line =
      SVGBuilder.line(tape_left, tape_y, tape_right, tape_y)
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{stroke: stroke, "stroke-width": 1, opacity: 0.55})
      )

    ticks =
      for i <- 0..tick_count do
        tx = tape_left + i * tick_spacing
        th = if rem(i, 5) == 0, do: 8, else: 3

        SVGBuilder.line(tx, tape_y, tx, tape_y + th)
        |> SVGBuilder.with_attrs(
          Map.merge(@stroke_effect, %{stroke: stroke, "stroke-width": 1, opacity: 0.55})
        )
        |> Base.maybe_animate(animate, "cockpit-tick")
      end

    [left_bracket, right_bracket, marquee_text, tape_line | ticks]
  end

  # ---------------------------------------------------------------------------
  # Left status readouts: all-caps monospace lines with one emphasized line
  # that flickers (deterministic per slug).
  # ---------------------------------------------------------------------------
  defp build_status_block(config, stroke, rng, animate) do
    x = config.status_x
    y0 = config.status_y_start
    spacing = config.status_line_spacing

    {emphasis_one, rng} = RandomGenerator.uniform_int_range(rng, 0, length(@status_lines) - 1)
    {emphasis_two, rng} = RandomGenerator.uniform_int_range(rng, 0, length(@status_lines) - 1)

    elements =
      @status_lines
      |> Enum.with_index()
      |> Enum.map(fn {label, i} ->
        opacity =
          cond do
            i == emphasis_one -> 1.0
            i == emphasis_two -> 0.9
            true -> 0.62
          end

        node = status_text(x, y0 + i * spacing, label, stroke, opacity)

        if i == emphasis_one do
          Base.maybe_animate(node, animate, "cockpit-flicker")
        else
          node
        end
      end)

    {elements, rng}
  end

  defp status_text(x, y, label, stroke, opacity) do
    text_node(x, y, label, %{
      fill: stroke,
      opacity: opacity,
      "font-size": 15,
      "letter-spacing": "0.08em"
    })
  end

  # ---------------------------------------------------------------------------
  # Right indicator panel: stacked LED-style cells. Fill state and timing
  # offsets are seeded by the RNG so each post gets a different pattern.
  # ---------------------------------------------------------------------------
  defp build_indicator_panel(width, config, stroke, rng, animate) do
    count = config.indicator_count
    cw = config.indicator_width
    ch = config.indicator_height
    gap = config.indicator_gap
    label_gap = config.indicator_label_gap
    x = width - config.indicator_right_inset - cw
    y0 = config.indicator_top_y

    Enum.map_reduce(0..(count - 1), rng, fn i, acc_rng ->
      y = y0 + i * (ch + gap)
      {state, acc_rng} = RandomGenerator.uniform_int_range(acc_rng, 0, 3)

      label =
        text_node(x - label_gap, y + ch - 3, Enum.at(@indicator_labels, i, ""), %{
          fill: stroke,
          opacity: 0.7,
          "font-size": 11,
          "letter-spacing": "0.16em",
          "text-anchor": "end"
        })

      outline =
        SVGBuilder.rect(x, y, cw, ch)
        |> SVGBuilder.with_attrs(
          Map.merge(@stroke_effect, %{
            fill: "none",
            stroke: stroke,
            "stroke-width": 1,
            opacity: 0.65
          })
        )

      cell_parts =
        case state do
          # Filled.
          0 ->
            fill =
              SVGBuilder.rect(x + 2, y + 2, cw - 4, ch - 4)
              |> SVGBuilder.with_attrs(%{fill: stroke, opacity: 0.85})
              |> Base.maybe_animate(animate, "cockpit-blip", i, 4)

            [outline, fill]

          # Half (left bar).
          1 ->
            fill =
              SVGBuilder.rect(x + 2, y + 2, (cw - 4) * 0.5, ch - 4)
              |> SVGBuilder.with_attrs(%{fill: stroke, opacity: 0.7})
              |> Base.maybe_animate(animate, "cockpit-blip", i, 4)

            [outline, fill]

          # Outline only.
          2 ->
            [outline |> Base.maybe_animate(animate, "cockpit-blip", i, 4)]

          # Bracket-only (corner ticks).
          _ ->
            tick = ch / 3

            ticks =
              for {bx, by, dx, dy} <- [
                    {x, y, 1, 1},
                    {x + cw, y, -1, 1},
                    {x, y + ch, 1, -1},
                    {x + cw, y + ch, -1, -1}
                  ],
                  seg <- [
                    SVGBuilder.line(bx, by, bx + dx * tick, by),
                    SVGBuilder.line(bx, by, bx, by + dy * tick)
                  ] do
                seg
                |> SVGBuilder.with_attrs(
                  Map.merge(@stroke_effect, %{
                    stroke: stroke,
                    "stroke-width": 1,
                    opacity: 0.75
                  })
                )
              end

            ticks
        end

      {[label | cell_parts], acc_rng}
    end)
    |> then(fn {groups, final_rng} -> {List.flatten(groups), final_rng} end)
  end

  # ---------------------------------------------------------------------------
  # Central wireframe scanner grid.
  # ---------------------------------------------------------------------------
  defp build_central_grid(width, height, config, stroke, animate) do
    cols = config.grid_cols
    rows = config.grid_rows
    gw = config.grid_width
    gh = config.grid_height
    gx = (width - gw) / 2
    gy = (height - gh) / 2

    cell_w = gw / cols
    cell_h = gh / rows

    outer =
      SVGBuilder.rect(gx, gy, gw, gh)
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{
          fill: "none",
          stroke: stroke,
          "stroke-width": 1.5,
          opacity: 0.85
        })
      )

    inner_attrs =
      Map.merge(@stroke_effect, %{
        stroke: stroke,
        "stroke-width": 1,
        opacity: 0.3
      })

    vlines =
      for i <- 1..(cols - 1) do
        x = gx + i * cell_w

        SVGBuilder.line(x, gy, x, gy + gh)
        |> SVGBuilder.with_attrs(inner_attrs)
      end

    hlines =
      for i <- 1..(rows - 1) do
        y = gy + i * cell_h

        SVGBuilder.line(gx, y, gx + gw, y)
        |> SVGBuilder.with_attrs(inner_attrs)
      end

    # Tick marks on each grid edge midpoint -- gives the scanner a sense
    # of axis calibration even without numeric labels.
    edge_ticks =
      [
        {gx + gw / 2, gy - 8, gx + gw / 2, gy},
        {gx + gw / 2, gy + gh, gx + gw / 2, gy + gh + 8},
        {gx - 8, gy + gh / 2, gx, gy + gh / 2},
        {gx + gw, gy + gh / 2, gx + gw + 8, gy + gh / 2}
      ]
      |> Enum.map(fn {x1, y1, x2, y2} ->
        SVGBuilder.line(x1, y1, x2, y2)
        |> SVGBuilder.with_attrs(
          Map.merge(@stroke_effect, %{stroke: stroke, "stroke-width": 1.5, opacity: 0.75})
        )
      end)

    grid = [outer | vlines ++ hlines] ++ edge_ticks

    if animate,
      do: [Base.maybe_animate(outer, true, "cockpit-grid-breath") | tl(grid)],
      else: grid
  end

  # ---------------------------------------------------------------------------
  # Lock-on reticle at grid center: crosshair + concentric squares wrapped in
  # four L-shaped corner brackets that form a target-tracking box. Sits on
  # top of the waveform so it reads as a sensor focused on a point.
  # ---------------------------------------------------------------------------
  defp build_lock_indicator(width, height, config, stroke, animate) do
    cx = width / 2
    cy = height / 2
    arm = config.reticle_arm
    gap = config.reticle_gap
    rings = config.reticle_rings
    ring_step = config.reticle_ring_step
    box_half = config.target_box_half
    bracket_arm = config.target_bracket_arm

    crosshair_attrs =
      Map.merge(@stroke_effect, %{stroke: stroke, "stroke-width": 1.5, opacity: 1.0})

    crosshair = [
      SVGBuilder.line(cx - arm, cy, cx - gap, cy) |> SVGBuilder.with_attrs(crosshair_attrs),
      SVGBuilder.line(cx + gap, cy, cx + arm, cy) |> SVGBuilder.with_attrs(crosshair_attrs),
      SVGBuilder.line(cx, cy - arm, cx, cy - gap) |> SVGBuilder.with_attrs(crosshair_attrs),
      SVGBuilder.line(cx, cy + gap, cx, cy + arm) |> SVGBuilder.with_attrs(crosshair_attrs)
    ]

    concentric =
      for i <- 1..rings do
        size = gap * 2 + i * ring_step * 2

        SVGBuilder.rect(cx - size / 2, cy - size / 2, size, size)
        |> SVGBuilder.with_attrs(
          Map.merge(@stroke_effect, %{
            fill: "none",
            stroke: stroke,
            "stroke-width": 1,
            opacity: 0.55 + 0.2 * (rings - i + 1) / rings
          })
        )
        |> Base.maybe_animate(animate, "cockpit-ring", i, 3)
      end

    bracket_attrs =
      Map.merge(@stroke_effect, %{
        fill: "none",
        stroke: stroke,
        "stroke-width": 1.5,
        opacity: 0.9
      })

    brackets =
      for {sx, sy} <- [{-1, -1}, {1, -1}, {-1, 1}, {1, 1}] do
        x0 = cx + sx * box_half
        y0 = cy + sy * box_half

        SVGBuilder.path(
          "M #{x0 - sx * bracket_arm} #{y0} " <>
            "L #{x0} #{y0} " <>
            "L #{x0} #{y0 - sy * bracket_arm}"
        )
        |> SVGBuilder.with_attrs(bracket_attrs)
        |> Base.maybe_animate(animate, "cockpit-track")
      end

    label =
      text_node(cx + box_half + 8, cy + box_half - 2, "LOCK", %{
        fill: stroke,
        opacity: 0.8,
        "font-size": 11,
        "letter-spacing": "0.2em"
      })

    brackets ++ crosshair ++ concentric ++ [label]
  end

  # ---------------------------------------------------------------------------
  # Grid overlay: axis labels and tactical readouts at the four grid corners,
  # giving the scanner a working coordinate system instead of a blank frame.
  # Numerical values are seeded by the slug so each post gets unique numbers.
  # ---------------------------------------------------------------------------
  defp build_grid_overlay(width, height, config, stroke, rng) do
    gw = config.grid_width
    gh = config.grid_height
    gx = (width - gw) / 2
    gy = (height - gh) / 2

    {azimuth, rng} = RandomGenerator.uniform_float(rng, 0.0, 359.9)
    {elevation, rng} = RandomGenerator.uniform_float(rng, -45.0, 45.0)
    {range_km, rng} = RandomGenerator.uniform_float(rng, 1.4, 12.8)
    {velocity, rng} = RandomGenerator.uniform_int_range(rng, 180, 420)

    # AZ/RNG sit just below the title-bar row (first inner grid line at
    # gy + cell_h), EL/V at the bottom of the grid.
    cell_h = gh / config.grid_rows
    pad_x = 8
    top_y = gy + cell_h + 16
    bot_y = gy + gh - 8

    base = %{
      fill: stroke,
      opacity: 0.7,
      "font-size": 12,
      "letter-spacing": "0.12em"
    }

    top_left =
      text_node(gx + pad_x, top_y, "AZ #{format_decimal(azimuth, 1)}", base)

    top_right =
      text_node(
        gx + gw - pad_x,
        top_y,
        "RNG #{format_decimal(range_km, 1)} KM",
        Map.put(base, "text-anchor", "end")
      )

    bottom_left =
      text_node(gx + pad_x, bot_y, "EL #{format_decimal(elevation, 1)}", base)

    bottom_right =
      text_node(
        gx + gw - pad_x,
        bot_y,
        "V #{velocity} M/S",
        Map.put(base, "text-anchor", "end")
      )

    {[top_left, top_right, bottom_left, bottom_right], rng}
  end

  # ---------------------------------------------------------------------------
  # Bottom telemetry strip: sits under the grid in the bottom visor mask
  # area. A thin sparkline above a structured text row with frame counter,
  # range bar, and target count. Fills what used to be empty visor floor.
  # ---------------------------------------------------------------------------
  defp build_telemetry_strip(width, height, config, stroke, rng, animate) do
    gw = config.grid_width
    gh = config.grid_height
    gx = (width - gw) / 2
    gy = (height - gh) / 2
    strip_top = gy + gh + config.telemetry_y_offset
    strip_height = config.telemetry_height

    {frame_num, rng} = RandomGenerator.uniform_int_range(rng, 1024, 9999)
    {range_pct, rng} = RandomGenerator.uniform_int_range(rng, 4, 11)
    {tgt_count, rng} = RandomGenerator.uniform_int_range(rng, 1, 12)

    spark_y = strip_top + 6
    spark_amp = 10

    {f1, rng} = RandomGenerator.uniform_float(rng, 3.0, 5.0)
    {f2, rng} = RandomGenerator.uniform_float(rng, 6.0, 11.0)
    {p1, rng} = RandomGenerator.uniform_float(rng, 0.0, :math.pi() * 2)

    samples = 90

    spark_d =
      for i <- 0..samples do
        t = i / samples
        x = gx + t * gw

        y =
          spark_y +
            spark_amp *
              (0.5 * :math.sin(t * f1 * 2 * :math.pi() + p1) +
                 0.5 * :math.sin(t * f2 * 2 * :math.pi()))

        if i == 0,
          do: "M #{Base.round_coord(x)} #{Base.round_coord(y)}",
          else: "L #{Base.round_coord(x)} #{Base.round_coord(y)}"
      end
      |> Enum.join(" ")

    sparkline =
      SVGBuilder.path(spark_d)
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{
          fill: "none",
          stroke: stroke,
          "stroke-width": 1,
          opacity: 0.65
        })
      )

    spark_baseline =
      SVGBuilder.line(gx, spark_y + spark_amp + 6, gx + gw, spark_y + spark_amp + 6)
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{stroke: stroke, "stroke-width": 1, opacity: 0.35})
      )

    text_y = strip_top + strip_height - 6

    text_base = %{
      fill: stroke,
      opacity: 0.85,
      "font-size": 13,
      "letter-spacing": "0.14em"
    }

    frame_text =
      text_node(gx + 4, text_y, "FRAME #{frame_num}", text_base)

    # Range bar: 12 cells, filled left-to-right.
    bar_cells = 12
    bar_x = gx + gw / 2 - bar_cells * 5
    bar_cell_w = 8
    bar_cell_h = 8
    bar_gap = 2

    bar_label =
      text_node(bar_x - 10, text_y, "RNG", Map.put(text_base, "text-anchor", "end"))

    bar_cells_elems =
      for i <- 0..(bar_cells - 1) do
        bx = bar_x + i * (bar_cell_w + bar_gap)
        by = text_y - bar_cell_h

        if i < range_pct do
          SVGBuilder.rect(bx, by, bar_cell_w, bar_cell_h)
          |> SVGBuilder.with_attrs(%{fill: stroke, opacity: 0.85})
          |> Base.maybe_animate(animate, "cockpit-blip", i, 4)
        else
          SVGBuilder.rect(bx, by, bar_cell_w, bar_cell_h)
          |> SVGBuilder.with_attrs(
            Map.merge(@stroke_effect, %{
              fill: "none",
              stroke: stroke,
              "stroke-width": 1,
              opacity: 0.45
            })
          )
        end
      end

    tgt_text =
      text_node(
        gx + gw - 4,
        text_y,
        "TGT #{String.pad_leading(Integer.to_string(tgt_count), 2, "0")}",
        Map.put(text_base, "text-anchor", "end")
      )

    elements =
      [sparkline, spark_baseline, frame_text, bar_label, tgt_text] ++ bar_cells_elems

    {elements, rng}
  end

  defp format_decimal(value, places) do
    :erlang.float_to_binary(value * 1.0, decimals: places)
  end

  # ---------------------------------------------------------------------------
  # Text node helper. SVGBuilder doesn't expose <text> directly; we construct
  # the element struct with `smil` carrying the inner text content (the
  # renderer interpolates it as raw inner-tag content).
  # ---------------------------------------------------------------------------
  defp text_node(x, y, content, attrs) do
    %{
      tag: :text,
      attrs:
        Map.merge(
          %{
            x: x,
            y: y,
            "font-family": @mono_font,
            "font-size": 14,
            "text-rendering": "geometricPrecision",
            fill: "currentColor"
          },
          attrs
        ),
      class: nil,
      children: nil,
      smil: content
    }
  end
end
