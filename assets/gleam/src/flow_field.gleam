/// Interactive flow field visualization
/// Particles follow vector fields derived from noise, influenced by mouse position

import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import noise.{type NoiseConfig}

/// A point in 2D space
pub type Point {
  Point(x: Float, y: Float)
}

/// A particle that flows through the field
pub type Particle {
  Particle(
    position: Point,
    velocity: Point,
    age: Int,
    max_age: Int,
    opacity: Float,
  )
}

/// Mouse state for interaction
pub type MouseState {
  MouseState(
    position: Option(Point),
    velocity: Point,
    influence_radius: Float,
    influence_strength: Float,
  )
}

/// Flow field configuration
pub type FlowFieldConfig {
  FlowFieldConfig(
    width: Float,
    height: Float,
    particle_count: Int,
    step_length: Float,
    noise_config: NoiseConfig,
    fade_speed: Float,
    stroke_width: Float,
    color: String,
  )
}

/// Flow field state
pub type FlowFieldState {
  FlowFieldState(
    config: FlowFieldConfig,
    particles: List(Particle),
    mouse: MouseState,
    time: Float,
  )
}

/// Create default configuration
pub fn default_config(width: Float, height: Float, seed: Float) -> FlowFieldConfig {
  FlowFieldConfig(
    width: width,
    height: height,
    particle_count: 1000,
    step_length: 2.0,
    noise_config: noise.default_config(seed),
    fade_speed: 0.03,
    stroke_width: 1.0,
    color: "#ffffff",
  )
}

/// Initialize flow field state
pub fn init(config: FlowFieldConfig) -> FlowFieldState {
  let particles = create_particles(config.particle_count, config.width, config.height)

  FlowFieldState(
    config: config,
    particles: particles,
    mouse: MouseState(
      position: None,
      velocity: Point(0.0, 0.0),
      influence_radius: 150.0,
      influence_strength: 0.5,
    ),
    time: 0.0,
  )
}

/// Create initial particles with random positions
fn create_particles(count: Int, width: Float, height: Float) -> List(Particle) {
  list.range(0, count - 1)
  |> list.map(fn(i) {
    // Deterministic pseudo-random based on index
    let seed = int.to_float(i) *. 0.618033988749
    let x = modulo(seed *. 1000.0, width)
    let y = modulo(seed *. 1618.0, height)

    let age = case int.modulo(i, 100) {
      Ok(v) -> v
      Error(_) -> 0
    }
    let max_age_offset = case int.modulo(i * 7, 40) {
      Ok(v) -> v
      Error(_) -> 0
    }

    Particle(
      position: Point(x, y),
      velocity: Point(0.0, 0.0),
      age: age,
      max_age: 80 + max_age_offset,
      opacity: 0.3 +. modulo(seed *. 0.7, 0.5),
    )
  })
}

/// Update mouse position
pub fn update_mouse(state: FlowFieldState, x: Float, y: Float) -> FlowFieldState {
  let old_pos = state.mouse.position
  let new_pos = Point(x, y)

  let velocity = case old_pos {
    Some(Point(ox, oy)) -> Point(x -. ox, y -. oy)
    None -> Point(0.0, 0.0)
  }

  FlowFieldState(
    ..state,
    mouse: MouseState(..state.mouse, position: Some(new_pos), velocity: velocity),
  )
}

/// Clear mouse position (mouse left canvas)
pub fn clear_mouse(state: FlowFieldState) -> FlowFieldState {
  FlowFieldState(
    ..state,
    mouse: MouseState(..state.mouse, position: None, velocity: Point(0.0, 0.0)),
  )
}

/// Update all particles for one frame
pub fn update(state: FlowFieldState, dt: Float) -> FlowFieldState {
  let new_time = state.time +. dt

  let new_particles =
    state.particles
    |> list.map(fn(particle) {
      update_particle(particle, state.config, state.mouse, new_time)
    })

  FlowFieldState(..state, particles: new_particles, time: new_time)
}

/// Update a single particle
fn update_particle(
  particle: Particle,
  config: FlowFieldConfig,
  mouse: MouseState,
  time: Float,
) -> Particle {
  let Point(x, y) = particle.position

  // Get base flow angle from noise
  let base_angle = get_flow_angle(x, y, config.noise_config, time)

  // Apply mouse influence if present
  let angle = case mouse.position {
    Some(mouse_pos) -> apply_mouse_influence(x, y, base_angle, mouse_pos, mouse)
    None -> base_angle
  }

  // Calculate velocity
  let vx = cos(angle) *. config.step_length
  let vy = sin(angle) *. config.step_length

  // Update position
  let new_x = x +. vx
  let new_y = y +. vy
  let new_age = particle.age + 1

  // Reset particle if out of bounds or too old
  case
    new_x <. 0.0
    || new_x >. config.width
    || new_y <. 0.0
    || new_y >. config.height
    || new_age > particle.max_age
  {
    True -> reset_particle(particle, config.width, config.height)
    False ->
      Particle(
        ..particle,
        position: Point(new_x, new_y),
        velocity: Point(vx, vy),
        age: new_age,
      )
  }
}

/// Reset particle to a new random position
fn reset_particle(particle: Particle, width: Float, height: Float) -> Particle {
  // Use current position as seed for new position
  let Point(x, y) = particle.position
  let seed = x *. 0.001 +. y *. 0.0001
  let new_x = modulo(seed *. 12345.0, width)
  let new_y = modulo({ seed +. 0.5 } *. 67890.0, height)

  Particle(
    ..particle,
    position: Point(new_x, new_y),
    velocity: Point(0.0, 0.0),
    age: 0,
  )
}

/// Get flow angle at a point from noise
fn get_flow_angle(x: Float, y: Float, noise_config: NoiseConfig, time: Float) -> Float {
  let noise_value = noise.sample(x, y +. time *. 10.0, noise_config)
  noise_value *. pi() *. 2.0
}

/// Apply mouse influence to angle
fn apply_mouse_influence(
  x: Float,
  y: Float,
  base_angle: Float,
  mouse_pos: Point,
  mouse: MouseState,
) -> Float {
  let Point(mx, my) = mouse_pos
  let dx = mx -. x
  let dy = my -. y
  let distance = sqrt(dx *. dx +. dy *. dy)

  case distance <. mouse.influence_radius {
    True -> {
      // Angle towards mouse
      let mouse_angle = atan2(dy, dx)
      // Blend based on distance (closer = more influence)
      let influence = { 1.0 -. distance /. mouse.influence_radius } *. mouse.influence_strength
      lerp_angle(base_angle, mouse_angle, influence)
    }
    False -> base_angle
  }
}

/// Linear interpolation between angles (handling wraparound)
fn lerp_angle(a: Float, b: Float, t: Float) -> Float {
  let diff = b -. a

  // Normalize difference to [-pi, pi]
  let normalized_diff = case diff >. pi() {
    True -> diff -. 2.0 *. pi()
    False ->
      case diff <. { 0.0 -. pi() } {
        True -> diff +. 2.0 *. pi()
        False -> diff
      }
  }

  a +. normalized_diff *. t
}

/// Get particles for rendering
pub fn get_particles(state: FlowFieldState) -> List(Particle) {
  state.particles
}

/// Get particle render data (position, previous position, opacity)
pub fn get_particle_render_data(particle: Particle) -> #(Float, Float, Float, Float, Float) {
  let Point(x, y) = particle.position
  let Point(vx, vy) = particle.velocity

  // Previous position for line drawing
  let prev_x = x -. vx
  let prev_y = y -. vy

  // Fade in/out based on age
  let age_ratio = int.to_float(particle.age) /. int.to_float(particle.max_age)
  let fade_opacity = case age_ratio <. 0.1 {
    True -> age_ratio *. 10.0  // Fade in
    False ->
      case age_ratio >. 0.9 {
        True -> { 1.0 -. age_ratio } *. 10.0  // Fade out
        False -> 1.0
      }
  }

  let final_opacity = particle.opacity *. fade_opacity

  #(prev_x, prev_y, x, y, final_opacity)
}

// Math helpers with FFI
@external(javascript, "../ffi.mjs", "sin")
fn sin(x: Float) -> Float

@external(javascript, "../ffi.mjs", "cos")
fn cos(x: Float) -> Float

@external(javascript, "../ffi.mjs", "sqrt")
fn sqrt(x: Float) -> Float

@external(javascript, "../ffi.mjs", "atan2")
fn atan2(y: Float, x: Float) -> Float

@external(javascript, "../ffi.mjs", "pi")
fn pi() -> Float

// Helper for modulo on floats
fn modulo(a: Float, b: Float) -> Float {
  a -. float.floor(a /. b) *. b
}

