/// Deterministic noise generation for flow fields
/// Uses layered sine waves for smooth, continuous noise
import gleam/int
import gleam/list

/// Noise configuration
pub type NoiseConfig {
  NoiseConfig(scale: Float, octaves: Int, persistence: Float, seed: Float)
}

/// Default noise configuration
pub fn default_config(seed: Float) -> NoiseConfig {
  NoiseConfig(scale: 0.005, octaves: 3, persistence: 0.5, seed: seed)
}

/// Generate layered noise at a point
pub fn sample(x: Float, y: Float, config: NoiseConfig) -> Float {
  let scaled_x = x *. config.scale
  let scaled_y = y *. config.scale

  let total =
    list.range(0, config.octaves - 1)
    |> list.fold(0.0, fn(acc, octave) {
      let frequency = int_pow(2.0, octave)
      let amplitude = float_pow(config.persistence, int.to_float(octave))
      acc
      +. simple_noise(scaled_x *. frequency, scaled_y *. frequency, config.seed)
      *. amplitude
    })

  let total_amplitude =
    calculate_total_amplitude(config.octaves, config.persistence)
  total /. total_amplitude
}

/// Simple noise using sine wave combinations
fn simple_noise(x: Float, y: Float, seed: Float) -> Float {
  let n1 = sin(x *. 1.0 +. seed) *. cos(y *. 1.0 +. seed *. 0.7)
  let n2 = sin(x *. 2.3 +. y *. 1.7 +. seed *. 1.3) *. 0.5
  let n3 = cos(x *. 3.7 +. y *. 2.9 +. seed *. 0.9) *. 0.25
  let n4 = sin({ x +. y } *. 1.5 +. seed *. 2.1) *. 0.125

  // Normalize to 0-1 range
  { n1 +. n2 +. n3 +. n4 +. 1.0 } /. 2.0
}

/// Calculate total amplitude for normalization
fn calculate_total_amplitude(octaves: Int, persistence: Float) -> Float {
  list.range(0, octaves - 1)
  |> list.fold(0.0, fn(acc, octave) {
    acc +. float_pow(persistence, int.to_float(octave))
  })
}

/// Integer power of 2
fn int_pow(base: Float, exp: Int) -> Float {
  case exp {
    0 -> 1.0
    n if n > 0 -> base *. int_pow(base, n - 1)
    _ -> 1.0
  }
}

/// Float power (using repeated multiplication for small exponents)
fn float_pow(base: Float, exp: Float) -> Float {
  // Approximation using exp/log for fractional exponents
  case exp {
    0.0 -> 1.0
    _ -> do_float_pow(base, exp)
  }
}

@external(javascript, "../ffi.mjs", "pow")
fn do_float_pow(base: Float, exp: Float) -> Float

@external(javascript, "../ffi.mjs", "sin")
fn sin(x: Float) -> Float

@external(javascript, "../ffi.mjs", "cos")
fn cos(x: Float) -> Float
