// JavaScript FFI for Gleam flow field module

export const sin = Math.sin;
export const cos = Math.cos;
export const pow = Math.pow;
export const sqrt = Math.sqrt;
export const atan2 = Math.atan2;
export const floor = Math.floor;
export const random = Math.random;
export const pi = Math.PI;

// Canvas context operations
export function getContext2d(canvas) {
  return canvas.getContext("2d");
}

export function clearRect(ctx, x, y, width, height) {
  ctx.clearRect(x, y, width, height);
  return ctx;
}

export function fillRect(ctx, x, y, width, height) {
  ctx.fillRect(x, y, width, height);
  return ctx;
}

export function setFillStyle(ctx, style) {
  ctx.fillStyle = style;
  return ctx;
}

export function setStrokeStyle(ctx, style) {
  ctx.strokeStyle = style;
  return ctx;
}

export function setLineWidth(ctx, width) {
  ctx.lineWidth = width;
  return ctx;
}

export function setLineCap(ctx, cap) {
  ctx.lineCap = cap;
  return ctx;
}

export function setGlobalAlpha(ctx, alpha) {
  ctx.globalAlpha = alpha;
  return ctx;
}

export function beginPath(ctx) {
  ctx.beginPath();
  return ctx;
}

export function moveTo(ctx, x, y) {
  ctx.moveTo(x, y);
  return ctx;
}

export function lineTo(ctx, x, y) {
  ctx.lineTo(x, y);
  return ctx;
}

export function quadraticCurveTo(ctx, cpx, cpy, x, y) {
  ctx.quadraticCurveTo(cpx, cpy, x, y);
  return ctx;
}

export function stroke(ctx) {
  ctx.stroke();
  return ctx;
}

// Animation frame
export function requestAnimationFrame(callback) {
  return window.requestAnimationFrame(() => callback());
}

export function cancelAnimationFrame(id) {
  window.cancelAnimationFrame(id);
}

// Mouse position tracking
export function getMousePosition(event, canvas) {
  const rect = canvas.getBoundingClientRect();
  return {
    x: event.clientX - rect.left,
    y: event.clientY - rect.top,
  };
}

// Performance timing
export function now() {
  return performance.now();
}

// String conversion
export function floatToString(f) {
  return f.toString();
}
