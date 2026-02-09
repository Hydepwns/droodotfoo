/// Main entry point for flow field visualization
/// Exports API for JavaScript LiveView hook integration
import flow_field.{type FlowFieldState}
import renderer.{type Context}

/// Application state wrapper
pub type App {
  App(state: FlowFieldState, ctx: Context, animation_id: Int, last_time: Float)
}

/// Create a new flow field application
pub fn create(canvas: Canvas, seed: Float) -> App {
  let width = get_canvas_width(canvas)
  let height = get_canvas_height(canvas)
  let ctx = get_context_2d(canvas)

  let config = flow_field.default_config(width, height, seed)
  let state = flow_field.init(config)

  // Initial clear
  let _ = renderer.clear(ctx, width, height)

  App(state: state, ctx: ctx, animation_id: 0, last_time: now())
}

/// Start the animation loop
pub fn start(app: App) -> App {
  let id = request_animation_frame(fn() { Nil })
  App(..app, animation_id: id)
}

/// Stop the animation loop
pub fn stop(app: App) -> Nil {
  cancel_animation_frame(app.animation_id)
}

/// Update and render one frame (called from JS animation loop)
pub fn tick(app: App) -> App {
  let current_time = now()
  let dt = { current_time -. app.last_time } /. 1000.0
  // Convert to seconds

  // Cap dt to prevent jumps
  let capped_dt = case dt >. 0.1 {
    True -> 0.016
    // ~60fps
    False -> dt
  }

  let new_state = flow_field.update(app.state, capped_dt)
  let _ = renderer.render(app.ctx, new_state)

  App(..app, state: new_state, last_time: current_time)
}

/// Handle mouse move event
pub fn on_mouse_move(app: App, x: Float, y: Float) -> App {
  let new_state = flow_field.update_mouse(app.state, x, y)
  App(..app, state: new_state)
}

/// Handle mouse leave event
pub fn on_mouse_leave(app: App) -> App {
  let new_state = flow_field.clear_mouse(app.state)
  App(..app, state: new_state)
}

/// Update configuration (e.g., particle count, colors)
pub fn set_particle_count(app: App, count: Int) -> App {
  let old_config = app.state.config
  let new_config =
    flow_field.FlowFieldConfig(..old_config, particle_count: count)
  let new_state = flow_field.init(new_config)
  App(..app, state: new_state)
}

pub fn set_color(app: App, color: String) -> App {
  let old_config = app.state.config
  let new_config = flow_field.FlowFieldConfig(..old_config, color: color)
  App(..app, state: flow_field.FlowFieldState(..app.state, config: new_config))
}

pub fn set_fade_speed(app: App, speed: Float) -> App {
  let old_config = app.state.config
  let new_config = flow_field.FlowFieldConfig(..old_config, fade_speed: speed)
  App(..app, state: flow_field.FlowFieldState(..app.state, config: new_config))
}

// Canvas type (opaque)
pub type Canvas

// FFI for canvas operations
@external(javascript, "../ffi.mjs", "getContext2d")
fn get_context_2d(canvas: Canvas) -> Context

@external(javascript, "../canvas_ffi.mjs", "getCanvasWidth")
fn get_canvas_width(canvas: Canvas) -> Float

@external(javascript, "../canvas_ffi.mjs", "getCanvasHeight")
fn get_canvas_height(canvas: Canvas) -> Float

@external(javascript, "../ffi.mjs", "now")
fn now() -> Float

@external(javascript, "../ffi.mjs", "requestAnimationFrame")
fn request_animation_frame(callback: fn() -> Nil) -> Int

@external(javascript, "../ffi.mjs", "cancelAnimationFrame")
fn cancel_animation_frame(id: Int) -> Nil
