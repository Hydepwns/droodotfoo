// Canvas-specific FFI for Gleam flow field

export function getCanvasWidth(canvas) {
  return canvas.width;
}

export function getCanvasHeight(canvas) {
  return canvas.height;
}

export function setCanvasSize(canvas, width, height) {
  canvas.width = width;
  canvas.height = height;
  return canvas;
}
