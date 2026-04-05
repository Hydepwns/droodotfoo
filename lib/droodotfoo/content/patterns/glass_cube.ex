defmodule Droodotfoo.Content.Patterns.GlassCube do
  @moduledoc """
  Glass cube pattern generator for Xochi.

  A centered isometric cube rendered in 6 concentric layers with graduated
  opacity -- outermost barely visible, innermost bold. An Ethereum diamond
  sits at the core with a visible gap between upper and lower chevrons.
  Glass reflection highlights streak across cube faces, tapering vertex rays
  radiate outward, a soft glow halo rings the innermost layer, and mixed
  particle shapes (circles + diamonds) orbit at distance-graded opacities.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  @iso_angle :math.pi() / 6
  @cos30 :math.cos(@iso_angle)
  @sin30 :math.sin(@iso_angle)

  # Cube depth as proportion of size (0.85 = slightly squatter than perfect cube)
  @depth_ratio 0.85

  # 6 concentric layers: {scale, base_opacity, stroke_width}
  @layers [
    {1.00, 0.07, 0.4},
    {0.82, 0.14, 0.6},
    {0.66, 0.23, 0.8},
    {0.52, 0.36, 1.0},
    {0.40, 0.55, 1.3},
    {0.28, 0.85, 1.6}
  ]

  # Face shading: {top, left, right} multiplied against base_opacity
  @face_shading %{top: 1.0, left: 0.65, right: 0.42}

  @spec generate(number, number, RandomGenerator.t(), map, boolean) ::
          {[SVGBuilder.element()], RandomGenerator.t()}
  def generate(width, height, rng, _palette, animate \\ false) do
    config = PatternConfig.glass_cube_config()

    {cube_size, rng} = RandomGenerator.uniform_range(rng, config.cube_size)
    {particle_count, rng} = RandomGenerator.uniform_range(rng, config.particle_count)
    particle_count = trunc(particle_count)

    cx = width / 2
    cy = height / 2

    # Layer 1: data fragments (scattered short line segments)
    {fragment_elements, rng} =
      generate_data_fragments(width, height, cx, cy, cube_size, animate, rng)

    # Layer 2: mixed particles
    {particle_elements, rng} =
      generate_particles(width, height, cx, cy, cube_size, particle_count, animate, rng)

    # Layer 3: connecting lines between nearby particles
    connection_elements = generate_connections(particle_elements, cube_size)

    # Layer 4: orbital arcs around the cube
    {orbital_elements, rng} =
      generate_orbital_arcs(cx, cy, cube_size, animate, rng)

    # Layer 5: tapering vertex rays
    ray_elements = generate_vertex_rays(cx, cy, cube_size, animate)

    # Layer 6: 6 concentric isometric cubes + glass reflections
    cube_elements = generate_concentric_cubes(cx, cy, cube_size, animate)

    # Layer 7: glow halo around innermost cube
    halo_elements = generate_glow_halo(cx, cy, cube_size, animate)

    elements =
      List.flatten([
        fragment_elements,
        particle_elements,
        connection_elements,
        orbital_elements,
        ray_elements,
        cube_elements,
        halo_elements
      ])

    {elements, rng}
  end

  # -- Concentric cubes ----------------------------------------------------

  defp generate_concentric_cubes(cx, cy, max_size, animate) do
    @layers
    |> Enum.with_index()
    |> Enum.flat_map(fn {{scale, opacity, stroke_w}, i} ->
      size = max_size * scale
      cube = build_iso_cube(cx, cy, size, opacity, stroke_w, animate, i)
      # Glass reflections on the outer 3 layers' top faces
      reflections = if i <= 2, do: glass_reflection(cx, cy, size, opacity), else: []
      cube ++ reflections
    end)
  end

  defp build_iso_cube(cx, cy, size, base_op, stroke_w, animate, layer_index) do
    iso_x = size * @cos30
    iso_y = size * @sin30
    h = size * @depth_ratio

    top = {cx, cy - iso_y}
    right = {cx + iso_x, cy}
    far = {cx, cy + iso_y}
    left = {cx - iso_x, cy}
    top_d = {cx, cy - iso_y + h}
    right_d = {cx + iso_x, cy + h}
    left_d = {cx - iso_x, cy + h}

    fill_op = base_op * 0.04
    class = "gc-layer-#{layer_index}"

    faces = [
      build_face(
        [top, right, far, left],
        base_op * @face_shading.top,
        fill_op * 1.4,
        stroke_w,
        animate,
        class
      ),
      build_face(
        [top, left, left_d, top_d],
        base_op * @face_shading.left,
        fill_op,
        stroke_w,
        animate,
        class
      ),
      build_face(
        [top, right, right_d, top_d],
        base_op * @face_shading.right,
        fill_op * 0.7,
        stroke_w,
        animate,
        class
      )
    ]

    back_edges = [
      build_edge(left, left_d, base_op * 0.35, stroke_w * 0.5),
      build_edge(right, right_d, base_op * 0.35, stroke_w * 0.5),
      build_edge(top_d, left_d, base_op * 0.20, stroke_w * 0.4),
      build_edge(top_d, right_d, base_op * 0.20, stroke_w * 0.4)
    ]

    faces ++ back_edges
  end

  # Diagonal highlight streak across the top face -- like light catching glass.
  # Goes from ~25% along the top-left edge to ~75% along the top-right edge.
  defp glass_reflection(cx, cy, size, base_op) do
    iso_x = size * @cos30
    iso_y = size * @sin30

    # Interpolate along edges of the top face diamond
    # Start: 30% along top->left edge
    sx = cx + (-iso_x - 0) * 0.30
    sy = cy + (0 - -iso_y) * 0.30 + -iso_y
    # End: 70% along top->right edge
    ex = cx + (iso_x - 0) * 0.70
    ey = cy + (0 - -iso_y) * 0.70 + -iso_y

    # Second parallel streak, offset slightly
    sx2 = cx + (-iso_x - 0) * 0.45
    sy2 = cy + (0 - -iso_y) * 0.45 + -iso_y
    ex2 = cx + (iso_x - 0) * 0.85
    ey2 = cy + (0 - -iso_y) * 0.85 + -iso_y

    op = base_op * 0.6

    [
      SVGBuilder.line(r(sx), r(sy), r(ex), r(ey), %{})
      |> SVGBuilder.with_attrs(%{
        stroke: "#ffffff",
        "stroke-width": 0.6,
        opacity: r(op),
        "stroke-linecap": "round"
      }),
      SVGBuilder.line(r(sx2), r(sy2), r(ex2), r(ey2), %{})
      |> SVGBuilder.with_attrs(%{
        stroke: "#ffffff",
        "stroke-width": 0.3,
        opacity: r(op * 0.5),
        "stroke-linecap": "round"
      })
    ]
  end

  # -- Glow halo -----------------------------------------------------------
  # Soft concentric circles around the innermost cube, suggesting light
  # refracting through the 6 glass layers.

  defp generate_glow_halo(cx, cy, cube_size, animate) do
    inner_radius = cube_size * 0.28 * @cos30
    halo_radii = [inner_radius * 1.3, inner_radius * 1.7, inner_radius * 2.2]
    halo_opacities = [0.10, 0.06, 0.03]

    Enum.zip(halo_radii, halo_opacities)
    |> Enum.map(fn {radius, op} ->
      element =
        SVGBuilder.circle(cx, cy, r(radius), %{})
        |> SVGBuilder.with_attrs(%{
          fill: "none",
          stroke: "#ffffff",
          "stroke-width": 0.8,
          opacity: op
        })

      if animate, do: SVGBuilder.with_class(element, "gc-halo"), else: element
    end)
  end

  # -- Tapering vertex rays ------------------------------------------------
  # Each ray is 3 overlapping segments with decreasing opacity and width,
  # creating a natural fade-out from the cube vertex outward.

  defp generate_vertex_rays(cx, cy, size, animate) do
    iso_x = size * @cos30
    iso_y = size * @sin30
    extend = size * 0.75

    vertices = [
      {cx, cy - iso_y},
      {cx + iso_x, cy},
      {cx - iso_x, cy},
      {cx, cy - iso_y + size * @depth_ratio},
      {cx + iso_x, cy + size * @depth_ratio},
      {cx - iso_x, cy + size * @depth_ratio}
    ]

    vertices
    |> Enum.with_index()
    |> Enum.flat_map(fn {{vx, vy}, i} ->
      dx = vx - cx
      dy = vy - cy
      len = :math.sqrt(dx * dx + dy * dy)
      {nx, ny} = if len < 0.01, do: {0.0, -1.0}, else: {dx / len, dy / len}

      base_op = 0.14 - i * 0.012

      # 3 segments: near (bright), mid, far (faint)
      segments = [
        {0.0, 0.33, 1.0, 0.7},
        {0.33, 0.66, 0.55, 0.45},
        {0.66, 1.0, 0.25, 0.25}
      ]

      Enum.map(segments, fn {t_start, t_end, op_mult, w_mult} ->
        sx = vx + nx * extend * t_start
        sy = vy + ny * extend * t_start
        ex = vx + nx * extend * t_end
        ey = vy + ny * extend * t_end
        op = max(r(base_op * op_mult), 0.02)

        ray =
          SVGBuilder.line(r(sx), r(sy), r(ex), r(ey), %{})
          |> SVGBuilder.with_attrs(%{
            stroke: "#ffffff",
            "stroke-width": r(0.6 * w_mult),
            opacity: op,
            "stroke-linecap": "round"
          })

        if animate, do: SVGBuilder.with_class(ray, "gc-ray"), else: ray
      end)
    end)
  end

  # -- Mixed particles -----------------------------------------------------
  # Circles + small diamond shapes. Distance-graded opacity.

  defp generate_particles(width, height, cx, cy, cube_size, count, animate, rng) do
    {particles, rng} =
      Enum.map_reduce(1..count, rng, fn i, acc_rng ->
        {angle, acc_rng} = RandomGenerator.uniform_float(acc_rng, 0, 2 * :math.pi())

        {dist, acc_rng} =
          RandomGenerator.uniform_float(acc_rng, cube_size * 0.7, cube_size * 3.5)

        {radius, acc_rng} = RandomGenerator.uniform_float(acc_rng, 0.8, 2.5)

        px = cx + :math.cos(angle) * dist
        py = cy + :math.sin(angle) * dist
        px = max(5, min(width - 5, px))
        py = max(5, min(height - 5, py))

        # Opacity inversely proportional to distance
        max_dist = cube_size * 3.5
        dist_ratio = min(1.0, dist / max_dist)
        opacity = r(0.06 + (1.0 - dist_ratio) * 0.50)

        # Every 4th particle is a diamond shape, rest are circles
        particle =
          if rem(i, 4) == 0 do
            build_diamond_particle(px, py, radius * 1.2, opacity)
          else
            SVGBuilder.circle(px, py, radius, %{})
            |> SVGBuilder.with_attrs(%{fill: "#ffffff", opacity: opacity})
          end

        particle =
          if animate do
            particle
            |> SVGBuilder.with_class("gc-particle")
            |> SVGBuilder.with_attrs(%{style: "--i: #{i}"})
          else
            particle
          end

        {particle, acc_rng}
      end)

    {particles, rng}
  end

  # Tiny rotated square (diamond) particle suggesting encrypted data packets.
  defp build_diamond_particle(px, py, size, opacity) do
    s = size
    points = vtp([{px, py - s}, {px + s, py}, {px, py + s}, {px - s, py}])

    SVGBuilder.polygon(points, %{})
    |> SVGBuilder.with_attrs(%{
      fill: "#ffffff",
      "fill-opacity": opacity,
      stroke: "#ffffff",
      "stroke-width": 0.3,
      "stroke-opacity": opacity * 0.6
    })
  end

  # -- Data fragments ------------------------------------------------------
  # Short line segments at random angles scattered across the canvas,
  # like encrypted data packets in transit. Very faint.

  defp generate_data_fragments(width, height, cx, cy, cube_size, animate, rng) do
    count = 30

    {fragments, rng} =
      Enum.map_reduce(1..count, rng, fn i, acc_rng ->
        {px, acc_rng} = RandomGenerator.uniform_float(acc_rng, 20, width - 20)
        {py, acc_rng} = RandomGenerator.uniform_float(acc_rng, 20, height - 20)
        {angle, acc_rng} = RandomGenerator.uniform_float(acc_rng, 0, :math.pi())
        {len, acc_rng} = RandomGenerator.uniform_float(acc_rng, 8, 25)

        # Skip fragments too close to center (cube area)
        dist = :math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy))

        fragment =
          if dist > cube_size * 0.5 do
            ex = px + :math.cos(angle) * len
            ey = py + :math.sin(angle) * len
            opacity = r(0.04 + dist / (cube_size * 3) * 0.08)

            frag =
              SVGBuilder.line(r(px), r(py), r(ex), r(ey), %{})
              |> SVGBuilder.with_attrs(%{
                stroke: "#ffffff",
                "stroke-width": 0.4,
                opacity: min(opacity, 0.12),
                "stroke-linecap": "round"
              })

            if animate do
              SVGBuilder.with_class(frag, "gc-fragment")
              |> SVGBuilder.with_attrs(%{style: "--i: #{i}"})
            else
              frag
            end
          else
            nil
          end

        {fragment, acc_rng}
      end)

    {Enum.reject(fragments, &is_nil/1), rng}
  end

  # -- Connections ---------------------------------------------------------
  # Thin lines between nearby particles, constellation-style.

  defp generate_connections(particle_elements, cube_size) do
    max_dist = cube_size * 0.6

    # Extract positions from particle elements
    coords =
      particle_elements
      |> Enum.map(fn elem ->
        {Map.get(elem.attrs, :cx, 0), Map.get(elem.attrs, :cy, 0)}
      end)
      |> Enum.filter(fn {x, y} -> x > 0 and y > 0 end)

    # Find pairs within range (limit to avoid n^2 explosion)
    coords
    |> Enum.with_index()
    |> Enum.flat_map(fn {{x1, y1}, i} ->
      coords
      |> Enum.drop(i + 1)
      |> Enum.take(8)
      |> Enum.filter(fn {x2, y2} ->
        dist = :math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
        dist < max_dist and dist > 10
      end)
      |> Enum.map(fn {x2, y2} ->
        dist = :math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
        opacity = r(0.03 + (1.0 - dist / max_dist) * 0.06)

        SVGBuilder.line(r(x1), r(y1), r(x2), r(y2), %{})
        |> SVGBuilder.with_attrs(%{
          stroke: "#ffffff",
          "stroke-width": 0.3,
          opacity: opacity
        })
      end)
    end)
  end

  # -- Orbital arcs --------------------------------------------------------
  # Partial ellipses at different tilts orbiting the cube, suggesting
  # data flowing through the protocol.

  defp generate_orbital_arcs(cx, cy, cube_size, animate, rng) do
    orbit_count = 4

    {arcs, rng} =
      Enum.map_reduce(1..orbit_count, rng, fn i, acc_rng ->
        {radius_x, acc_rng} =
          RandomGenerator.uniform_float(acc_rng, cube_size * 0.6, cube_size * 1.2)

        {radius_y, acc_rng} =
          RandomGenerator.uniform_float(acc_rng, cube_size * 0.3, cube_size * 0.6)

        {rotation, acc_rng} = RandomGenerator.uniform_float(acc_rng, -40, 40)
        {start_angle, acc_rng} = RandomGenerator.uniform_float(acc_rng, 0, :math.pi())
        sweep = :math.pi() * 0.6 + :math.pi() * 0.3 * (i / orbit_count)

        # Build arc path
        steps = 20

        points =
          for s <- 0..steps do
            t = start_angle + sweep * (s / steps)
            x = cx + radius_x * :math.cos(t)
            y = cy + radius_y * :math.sin(t)
            # Apply rotation
            rot = rotation * :math.pi() / 180
            rx = cx + (x - cx) * :math.cos(rot) - (y - cy) * :math.sin(rot)
            ry = cy + (x - cx) * :math.sin(rot) + (y - cy) * :math.cos(rot)
            {r(rx), r(ry)}
          end

        d =
          points
          |> Enum.with_index()
          |> Enum.map_join(" ", fn {{x, y}, j} ->
            if j == 0, do: "M #{x},#{y}", else: "L #{x},#{y}"
          end)

        opacity = 0.06 + i * 0.02

        arc =
          SVGBuilder.path(d, %{})
          |> SVGBuilder.with_attrs(%{
            fill: "none",
            stroke: "#ffffff",
            "stroke-width": 0.5,
            opacity: r(opacity),
            "stroke-linecap": "round"
          })

        arc = if animate, do: SVGBuilder.with_class(arc, "gc-orbit"), else: arc

        {arc, acc_rng}
      end)

    {arcs, rng}
  end

  # -- Helpers -------------------------------------------------------------

  defp build_face(vertices, stroke_op, fill_op, stroke_w, animate, class) do
    element =
      SVGBuilder.polygon(vtp(vertices), %{})
      |> SVGBuilder.with_attrs(%{
        fill: "#ffffff",
        "fill-opacity": fill_op,
        stroke: "#ffffff",
        "stroke-width": stroke_w,
        "stroke-opacity": stroke_op,
        "stroke-linejoin": "round"
      })

    if animate, do: SVGBuilder.with_class(element, class), else: element
  end

  defp build_edge({x1, y1}, {x2, y2}, opacity, stroke_w) do
    SVGBuilder.line(x1, y1, x2, y2, %{})
    |> SVGBuilder.with_attrs(%{
      stroke: "#ffffff",
      "stroke-width": stroke_w,
      opacity: opacity
    })
  end

  defp vtp(vertices) do
    Enum.map_join(vertices, " ", fn {x, y} -> "#{r(x)},#{r(y)}" end)
  end

  defp r(val), do: Float.round(val * 1.0, 2)

  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :glass_cube, slug, width, height, animate, tags)
  end
end
