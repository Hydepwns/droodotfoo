defmodule Droodotfoo.Content.Patterns.CockpitHud do
  @moduledoc """
  Cockpit HUD pattern generator.

  Visual language: a mecha pilot's POV through the visor. The frame is a
  curved dark bezel at top and bottom (the helmet/cockpit rim); inside
  the opening, a wireframe scanning grid encloses a Gundam-head
  silhouette under a tight reticle. Left and right HUD panels carry
  status readouts, LED indicator cells, and numeric telemetry. A
  horizontal scan beam sweeps the silhouette continuously; corner
  brackets mark the chassis frame outside the visor.

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
    {buster_bars, rng} = build_buster_bars(width, config, stroke, rng, animate)
    {bottom_numbers, rng} = build_bottom_numbers(width, height, config, stroke, rng)
    grid = build_central_grid(width, height, config, stroke, animate)
    feathers = build_wing_feathers(width, height, config, stroke, animate)
    silhouette = build_silhouette(width, height, stroke, animate)
    reticle = build_lock_indicator(width, height, config, stroke, animate)
    {sparkline, rng} = build_sparkline(width, height, config, stroke, rng, animate)
    scan_beam = build_scan_beam(width, height, config, stroke, animate)
    visor_edges = build_visor_edges(width, height, config, stroke)
    corners = build_corners(width, height, config, stroke, animate)

    elements =
      scanlines ++
        visor_masks ++
        marquee ++
        status_block ++
        indicator_panel ++
        buster_bars ++
        bottom_numbers ++
        grid ++
        feathers ++
        silhouette ++
        reticle ++
        sparkline ++
        scan_beam ++
        visor_edges ++
        corners

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
      SVGBuilder.path(
        "M 0 #{bot_corner - 6} Q #{cx} #{bot_apex + 8} #{width} #{bot_corner - 6}"
      )
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
  # Corner brackets at the chassis frame (outermost layer).
  # ---------------------------------------------------------------------------
  defp build_corners(width, height, config, stroke, animate) do
    pad = config.frame_padding
    len = config.corner_length
    weight = config.corner_weight

    attrs =
      Map.merge(@stroke_effect, %{
        stroke: stroke,
        "stroke-width": weight,
        "stroke-linecap": "square"
      })

    for {x, y, dx, dy} <- [
          {pad, pad, 1, 1},
          {width - pad, pad, -1, 1},
          {pad, height - pad, 1, -1},
          {width - pad, height - pad, -1, -1}
        ],
        line <- [
          SVGBuilder.line(x, y, x + dx * len, y) |> SVGBuilder.with_attrs(attrs),
          SVGBuilder.line(x, y, x, y + dy * len) |> SVGBuilder.with_attrs(attrs)
        ] do
      Base.maybe_animate(line, animate, "cockpit-corner")
    end
  end

  # ---------------------------------------------------------------------------
  # ZERO SYSTEM marquee: bracketed header below the visor apex, with an
  # integrated ruler tape strip carrying tick marks.
  # ---------------------------------------------------------------------------
  defp build_zero_marquee(width, _height, config, stroke, animate) do
    pad = config.frame_padding
    y = config.visor_apex_y + config.marquee_offset
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
    tape_left = pad + 60
    tape_right = width - pad - 60
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
    x = width - config.indicator_right_inset - cw
    y0 = config.indicator_top_y

    Enum.map_reduce(0..(count - 1), rng, fn i, acc_rng ->
      y = y0 + i * (ch + gap)
      {state, acc_rng} = RandomGenerator.uniform_int_range(acc_rng, 0, 3)

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

      {cell_parts, acc_rng}
    end)
    |> then(fn {groups, final_rng} -> {List.flatten(groups), final_rng} end)
  end

  # ---------------------------------------------------------------------------
  # Twin Buster Rifle charge bars: two horizontal meters below the indicator
  # panel, with calibrated segment ticks, side label, and percentage readout.
  # Charge level varies per slug via the RNG.
  # ---------------------------------------------------------------------------
  defp build_buster_bars(width, config, stroke, rng, animate) do
    bar_w = config.buster_bar_width
    bar_h = config.buster_bar_height
    bar_x = width - config.indicator_right_inset - bar_w
    top_y = config.buster_bar_top_y
    gap = config.buster_bar_gap
    segments = config.buster_segments

    rows = [
      {"L BUSTER", top_y, 0},
      {"R BUSTER", top_y + gap, 1}
    ]

    Enum.flat_map_reduce(rows, rng, fn {label, y, idx}, acc_rng ->
      {charge, acc_rng} = RandomGenerator.uniform_range(acc_rng, %{min: 0.55, max: 0.97})

      outline =
        SVGBuilder.rect(bar_x, y, bar_w, bar_h)
        |> SVGBuilder.with_attrs(
          Map.merge(@stroke_effect, %{
            fill: "none",
            stroke: stroke,
            "stroke-width": 1,
            opacity: 0.85
          })
        )

      fill =
        SVGBuilder.rect(bar_x + 1, y + 1, (bar_w - 2) * charge, bar_h - 2)
        |> SVGBuilder.with_attrs(%{fill: stroke, opacity: 0.8})
        |> Base.maybe_animate(animate, "cockpit-charge", idx, 2)

      seg_spacing = bar_w / segments

      seg_ticks =
        for s <- 1..(segments - 1) do
          tx = bar_x + s * seg_spacing

          SVGBuilder.line(tx, y + 2, tx, y + bar_h - 2)
          |> SVGBuilder.with_attrs(
            Map.merge(@stroke_effect, %{stroke: stroke, "stroke-width": 1, opacity: 0.35})
          )
        end

      label_node =
        text_node(bar_x - 8, y + bar_h - 4, label, %{
          fill: stroke,
          opacity: 0.85,
          "font-size": 12,
          "letter-spacing": "0.14em",
          "text-anchor": "end"
        })

      pct = round(charge * 100)

      pct_node =
        text_node(bar_x + bar_w + 8, y + bar_h - 4, "#{pct}%", %{
          fill: stroke,
          opacity: 0.85,
          "font-size": 12,
          "letter-spacing": "0.08em"
        })

      {[outline, fill] ++ seg_ticks ++ [label_node, pct_node], acc_rng}
    end)
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
    if animate, do: [Base.maybe_animate(outer, true, "cockpit-grid-breath") | tl(grid)], else: grid
  end

  # ---------------------------------------------------------------------------
  # Wing-feather backplate: Wing Zero's deployed feathers fanning out from
  # the silhouette's shoulder region. Each feather is a thin diamond drawn
  # as an outlined polygon. Sits between the grid and the silhouette so
  # the head shape overlays the feather roots cleanly.
  # ---------------------------------------------------------------------------
  defp build_wing_feathers(width, height, config, stroke, animate) do
    cx = width / 2
    cy = height / 2

    angles = config.feather_angles
    lengths = config.feather_lengths
    widths = config.feather_half_widths
    opacity = config.feather_opacity

    shoulder_left = {cx - 48, cy + 8}
    shoulder_right = {cx + 48, cy + 8}

    specs = Enum.zip([angles, lengths, widths])

    right_wing =
      specs
      |> Enum.with_index()
      |> Enum.map(fn {{deg, len, w}, i} ->
        feather(shoulder_right, deg, len, w, :right, stroke, opacity, animate, i)
      end)

    left_wing =
      specs
      |> Enum.with_index()
      |> Enum.map(fn {{deg, len, w}, i} ->
        feather(shoulder_left, deg, len, w, :left, stroke, opacity, animate, i)
      end)

    right_wing ++ left_wing
  end

  defp feather({ax, ay}, deg, length, half_width, side, stroke, opacity, animate, idx) do
    rad = deg * :math.pi() / 180
    cosv = :math.cos(rad)
    sinv = :math.sin(rad)
    dx_dir = if side == :right, do: cosv, else: -cosv
    dy_dir = -sinv

    tx = ax + length * dx_dir
    ty = ay + length * dy_dir

    mx = ax + length / 2 * dx_dir
    my = ay + length / 2 * dy_dir

    # Perpendicular to feather direction (rotated 90°).
    perp_x = -dy_dir
    perp_y = dx_dir

    p1 = {mx + half_width * perp_x, my + half_width * perp_y}
    p2 = {mx - half_width * perp_x, my - half_width * perp_y}

    points =
      [{ax, ay}, p1, {tx, ty}, p2]
      |> Enum.map_join(" ", fn {px, py} ->
        "#{Base.round_coord(px)},#{Base.round_coord(py)}"
      end)

    SVGBuilder.polygon(points)
    |> SVGBuilder.with_attrs(
      Map.merge(@stroke_effect, %{
        fill: "none",
        stroke: stroke,
        "stroke-width": 1,
        opacity: opacity,
        "stroke-linejoin": "miter"
      })
    )
    |> Base.maybe_animate(animate, "cockpit-feather", idx, 5)
  end

  # ---------------------------------------------------------------------------
  # Gundam-head silhouette. Polygon outline + faint fill + eye slits + mouth
  # grille. Coordinates are centered at the canvas midpoint via offsets.
  # ---------------------------------------------------------------------------
  defp build_silhouette(width, height, stroke, animate) do
    cx = width / 2
    cy = height / 2

    # Outline points (clockwise from V-fin tip), local to silhouette center.
    local_points = [
      {0, -118},
      {7, -82},
      {16, -76},
      {52, -70},
      {66, -54},
      {70, -22},
      {68, 8},
      {62, 28},
      {52, 44},
      {38, 56},
      {18, 66},
      {0, 70},
      {-18, 66},
      {-38, 56},
      {-52, 44},
      {-62, 28},
      {-68, 8},
      {-70, -22},
      {-66, -54},
      {-52, -70},
      {-16, -76},
      {-7, -82}
    ]

    points_str =
      local_points
      |> Enum.map_join(" ", fn {dx, dy} ->
        "#{Base.round_coord(cx + dx)},#{Base.round_coord(cy + dy)}"
      end)

    outline =
      SVGBuilder.polygon(points_str)
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{
          fill: stroke,
          "fill-opacity": 0.08,
          stroke: stroke,
          "stroke-width": 2,
          "stroke-linejoin": "round",
          opacity: 0.95
        })
      )
      |> Base.maybe_animate(animate, "cockpit-pulse")

    # Inner detail: forehead crest line.
    crest =
      SVGBuilder.path(
        "M #{cx - 40} #{cy - 46} L #{cx - 28} #{cy - 56} " <>
          "L #{cx + 28} #{cy - 56} L #{cx + 40} #{cy - 46}"
      )
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{
          fill: "none",
          stroke: stroke,
          "stroke-width": 1.5,
          opacity: 0.7
        })
      )

    # Eye slits.
    eye_left =
      SVGBuilder.rect(cx - 36, cy - 22, 24, 8)
      |> SVGBuilder.with_attrs(%{fill: stroke, opacity: 0.95})
      |> Base.maybe_animate(animate, "cockpit-eye")

    eye_right =
      SVGBuilder.rect(cx + 12, cy - 22, 24, 8)
      |> SVGBuilder.with_attrs(%{fill: stroke, opacity: 0.95})
      |> Base.maybe_animate(animate, "cockpit-eye")

    # Cheek vents (faint horizontal slashes).
    vent_left =
      SVGBuilder.line(cx - 56, cy + 2, cx - 40, cy + 2)
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{stroke: stroke, "stroke-width": 1.5, opacity: 0.6})
      )

    vent_right =
      SVGBuilder.line(cx + 40, cy + 2, cx + 56, cy + 2)
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{stroke: stroke, "stroke-width": 1.5, opacity: 0.6})
      )

    # Mouth grille: four vertical bars centered under the eyes.
    mouth =
      for i <- 0..3 do
        bx = cx - 18 + i * 12

        SVGBuilder.line(bx, cy + 22, bx, cy + 38)
        |> SVGBuilder.with_attrs(
          Map.merge(@stroke_effect, %{stroke: stroke, "stroke-width": 1.5, opacity: 0.8})
        )
      end

    [outline, crest, eye_left, eye_right, vent_left, vent_right | mouth]
  end

  # ---------------------------------------------------------------------------
  # Lock-on indicator: small crosshair + concentric squares positioned below
  # the silhouette chin, where it reads as a separate "target locked" UI
  # element instead of fighting the eye-line. The grid itself does the
  # broader targeting-frame job.
  # ---------------------------------------------------------------------------
  defp build_lock_indicator(width, height, config, stroke, animate) do
    cx = width / 2
    cy = height / 2 + 96
    arm = config.reticle_arm
    gap = config.reticle_gap
    rings = config.reticle_rings
    ring_step = config.reticle_ring_step

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

    label =
      text_node(cx + arm + 12, cy + 4, "LOCK", %{
        fill: stroke,
        opacity: 0.85,
        "font-size": 12,
        "letter-spacing": "0.18em"
      })

    crosshair ++ concentric ++ [label]
  end

  # ---------------------------------------------------------------------------
  # Scan beam: a thin horizontal line across the grid width that sweeps top
  # to bottom via CSS transform. Drawn last so it sits over the silhouette.
  # ---------------------------------------------------------------------------
  defp build_scan_beam(width, height, config, stroke, animate) do
    gw = config.grid_width
    gx = (width - gw) / 2
    cy = height / 2

    beam =
      SVGBuilder.line(gx, cy, gx + gw, cy)
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{
          stroke: stroke,
          "stroke-width": 1.5,
          opacity: 0.85
        })
      )
      |> Base.maybe_animate(animate, "cockpit-scan")

    [beam]
  end

  # ---------------------------------------------------------------------------
  # Sparkline at bottom of viewport: stochastic telemetry trace that draws in.
  # ---------------------------------------------------------------------------
  defp build_sparkline(width, height, config, stroke, rng, animate) do
    pad = config.frame_padding
    band_height = config.sparkline_band_height
    point_count = config.sparkline_points

    band_y = height - config.visor_corner_y - band_height - 28
    inner_width = width - 2 * pad - config.sparkline_inset * 2
    step = inner_width / (point_count - 1)
    start_x = pad + config.sparkline_inset

    {points, rng} =
      Enum.map_reduce(0..(point_count - 1), rng, fn i, acc_rng ->
        {ratio, acc_rng} = RandomGenerator.uniform_range(acc_rng, %{min: 0.0, max: 1.0})
        x = start_x + i * step
        y = band_y + band_height * (1 - ratio)
        {{x, y}, acc_rng}
      end)

    path_d =
      points
      |> Enum.with_index()
      |> Enum.map_join(" ", fn
        {{x, y}, 0} -> "M #{Base.round_coord(x)} #{Base.round_coord(y)}"
        {{x, y}, _} -> "L #{Base.round_coord(x)} #{Base.round_coord(y)}"
      end)

    spark =
      SVGBuilder.path(path_d)
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{
          fill: "none",
          stroke: stroke,
          "stroke-width": 1.5,
          "stroke-linejoin": "round",
          opacity: 1.0
        })
      )
      |> Base.maybe_animate(animate, "cockpit-spark")

    baseline =
      SVGBuilder.line(start_x, band_y + band_height, start_x + inner_width, band_y + band_height)
      |> SVGBuilder.with_attrs(
        Map.merge(@stroke_effect, %{stroke: stroke, "stroke-width": 1, opacity: 0.45})
      )

    {[baseline, spark], rng}
  end

  # ---------------------------------------------------------------------------
  # Bottom corner number readouts: two digit strings at each lower corner.
  # ---------------------------------------------------------------------------
  defp build_bottom_numbers(width, height, config, stroke, rng) do
    font_size = config.number_font_size
    long_len = config.number_digits_long
    short_len = config.number_digits_short

    left_x = config.status_x
    right_x = width - config.indicator_right_inset
    line_y_top = height - 150
    line_y_bot = line_y_top + 22

    {d1, rng} = random_digits(rng, long_len)
    {d2, rng} = random_digits(rng, long_len)
    {d3, rng} = random_digits(rng, short_len)
    {d4, rng} = random_digits(rng, long_len)

    base_attrs = fn opacity ->
      %{
        fill: stroke,
        opacity: opacity,
        "font-size": font_size,
        "letter-spacing": "0.08em"
      }
    end

    right_attrs = fn opacity ->
      Map.put(base_attrs.(opacity), :"text-anchor", "end")
    end

    elements = [
      text_node(left_x, line_y_top, d1, base_attrs.(0.85)),
      text_node(left_x, line_y_bot, d2, base_attrs.(0.85)),
      text_node(right_x, line_y_top, d3, right_attrs.(0.85)),
      text_node(right_x, line_y_bot, d4, right_attrs.(0.7))
    ]

    {elements, rng}
  end

  defp random_digits(rng, length) do
    {digits, rng} =
      Enum.map_reduce(1..length, rng, fn _, r ->
        {d, r} = RandomGenerator.uniform_int_range(r, 0, 9)
        {Integer.to_string(d), r}
      end)

    {Enum.join(digits), rng}
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
