/// Canvas rendering for flow field visualization
import flow_field.{type FlowFieldState, type Particle}
import gleam/list

/// Opaque canvas context type
pub type Context

/// Render the flow field to canvas
pub fn render(ctx: Context, state: FlowFieldState) -> Context {
  // Apply fade effect for trails
  ctx
  |> set_fill_style(
    "rgba(0, 0, 0, " <> float_to_string(state.config.fade_speed) <> ")",
  )
  |> fill_rect(0.0, 0.0, state.config.width, state.config.height)

  // Render all particles
  ctx
  |> set_stroke_style(state.config.color)
  |> set_line_width(state.config.stroke_width)
  |> set_line_cap("round")
  |> render_particles(flow_field.get_particles(state))
}

/// Render all particles as lines
fn render_particles(ctx: Context, particles: List(Particle)) -> Context {
  particles
  |> list.fold(ctx, fn(ctx, particle) { render_particle(ctx, particle) })
}

/// Render a single particle as a line segment
fn render_particle(ctx: Context, particle: Particle) -> Context {
  let #(prev_x, prev_y, x, y, opacity) =
    flow_field.get_particle_render_data(particle)

  case opacity >. 0.01 {
    True ->
      ctx
      |> set_global_alpha(opacity)
      |> begin_path()
      |> move_to(prev_x, prev_y)
      |> line_to(x, y)
      |> stroke()
    False -> ctx
  }
}

/// Clear the canvas completely
pub fn clear(ctx: Context, width: Float, height: Float) -> Context {
  ctx
  |> set_fill_style("#000000")
  |> fill_rect(0.0, 0.0, width, height)
}

// Canvas FFI bindings
@external(javascript, "../ffi.mjs", "setFillStyle")
fn set_fill_style(ctx: Context, style: String) -> Context

@external(javascript, "../ffi.mjs", "setStrokeStyle")
fn set_stroke_style(ctx: Context, style: String) -> Context

@external(javascript, "../ffi.mjs", "setLineWidth")
fn set_line_width(ctx: Context, width: Float) -> Context

@external(javascript, "../ffi.mjs", "setLineCap")
fn set_line_cap(ctx: Context, cap: String) -> Context

@external(javascript, "../ffi.mjs", "setGlobalAlpha")
fn set_global_alpha(ctx: Context, alpha: Float) -> Context

@external(javascript, "../ffi.mjs", "fillRect")
fn fill_rect(
  ctx: Context,
  x: Float,
  y: Float,
  width: Float,
  height: Float,
) -> Context

@external(javascript, "../ffi.mjs", "beginPath")
fn begin_path(ctx: Context) -> Context

@external(javascript, "../ffi.mjs", "moveTo")
fn move_to(ctx: Context, x: Float, y: Float) -> Context

@external(javascript, "../ffi.mjs", "lineTo")
fn line_to(ctx: Context, x: Float, y: Float) -> Context

@external(javascript, "../ffi.mjs", "stroke")
fn stroke(ctx: Context) -> Context

// Helper to convert float to string
fn float_to_string(f: Float) -> String {
  do_float_to_string(f)
}

@external(javascript, "../ffi.mjs", "floatToString")
fn do_float_to_string(f: Float) -> String
