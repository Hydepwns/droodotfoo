/**
 * Touch gesture support for terminal navigation
 */

export interface TouchPoint {
  x: number;
  y: number;
  timestamp: number;
}

export interface SwipeEvent {
  direction: 'up' | 'down' | 'left' | 'right';
  velocity: number;
  distance: number;
}

export interface TapEvent {
  x: number;
  y: number;
  isDoubleTap: boolean;
}

export interface PinchEvent {
  scale: number;
  center: { x: number; y: number };
}

export class TouchGestureManager {
  private element: HTMLElement;
  private touchStartPoint: TouchPoint | null = null;
  private lastTapTime: number = 0;
  private lastTapPoint: TouchPoint | null = null;
  private pinchStartDistance: number = 0;
  private isScrolling: boolean = false;

  // Gesture thresholds
  private readonly SWIPE_THRESHOLD = 50; // pixels
  private readonly SWIPE_VELOCITY_THRESHOLD = 0.3; // pixels/ms
  private readonly TAP_THRESHOLD = 10; // pixels
  private readonly DOUBLE_TAP_THRESHOLD = 300; // ms
  private readonly LONG_PRESS_DURATION = 500; // ms

  // Callbacks
  private onSwipe: ((event: SwipeEvent) => void) | null = null;
  private onTap: ((event: TapEvent) => void) | null = null;
  private onPinch: ((event: PinchEvent) => void) | null = null;
  private onLongPress: ((point: TouchPoint) => void) | null = null;

  private longPressTimer: NodeJS.Timeout | null = null;
  private preventNextClick: boolean = false;

  constructor(element: HTMLElement) {
    this.element = element;
    this.attachEventListeners();
  }

  private attachEventListeners(): void {
    // Touch events
    this.element.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: false });
    this.element.addEventListener('touchmove', this.handleTouchMove.bind(this), { passive: false });
    this.element.addEventListener('touchend', this.handleTouchEnd.bind(this), { passive: false });
    this.element.addEventListener('touchcancel', this.handleTouchCancel.bind(this), { passive: false });

    // Prevent default click behavior after touch
    this.element.addEventListener('click', (e) => {
      if (this.preventNextClick) {
        e.preventDefault();
        e.stopPropagation();
        this.preventNextClick = false;
      }
    });

    // Prevent context menu on long press
    this.element.addEventListener('contextmenu', (e) => {
      e.preventDefault();
    });
  }

  private handleTouchStart(e: TouchEvent): void {
    // Handle pinch start
    if (e.touches.length === 2) {
      const touch1 = e.touches[0];
      const touch2 = e.touches[1];
      this.pinchStartDistance = this.getDistance(
        { x: touch1.clientX, y: touch1.clientY },
        { x: touch2.clientX, y: touch2.clientY }
      );
      return;
    }

    if (e.touches.length === 1) {
      const touch = e.touches[0];
      this.touchStartPoint = {
        x: touch.clientX,
        y: touch.clientY,
        timestamp: Date.now()
      };

      // Start long press timer
      this.longPressTimer = setTimeout(() => {
        if (this.touchStartPoint && this.onLongPress) {
          this.onLongPress(this.touchStartPoint);
          this.touchStartPoint = null; // Prevent other gestures
        }
      }, this.LONG_PRESS_DURATION);

      // Prevent default to avoid scrolling
      e.preventDefault();
    }
  }

  private handleTouchMove(e: TouchEvent): void {
    // Handle pinch gesture
    if (e.touches.length === 2 && this.pinchStartDistance > 0) {
      const touch1 = e.touches[0];
      const touch2 = e.touches[1];
      const currentDistance = this.getDistance(
        { x: touch1.clientX, y: touch1.clientY },
        { x: touch2.clientX, y: touch2.clientY }
      );

      const scale = currentDistance / this.pinchStartDistance;
      const centerX = (touch1.clientX + touch2.clientX) / 2;
      const centerY = (touch1.clientY + touch2.clientY) / 2;

      if (this.onPinch) {
        this.onPinch({
          scale,
          center: { x: centerX, y: centerY }
        });
      }

      e.preventDefault();
      return;
    }

    // Cancel long press if movement detected
    if (this.touchStartPoint && e.touches.length === 1) {
      const touch = e.touches[0];
      const moveDistance = this.getDistance(
        this.touchStartPoint,
        { x: touch.clientX, y: touch.clientY }
      );

      if (moveDistance > this.TAP_THRESHOLD) {
        this.cancelLongPress();
        this.isScrolling = true;
      }
    }

    // Prevent default scrolling
    if (!this.isScrolling) {
      e.preventDefault();
    }
  }

  private handleTouchEnd(e: TouchEvent): void {
    this.cancelLongPress();

    if (!this.touchStartPoint) {
      return;
    }

    const touchEnd = e.changedTouches[0];
    const endPoint: TouchPoint = {
      x: touchEnd.clientX,
      y: touchEnd.clientY,
      timestamp: Date.now()
    };

    const distance = this.getDistance(this.touchStartPoint, endPoint);
    const duration = endPoint.timestamp - this.touchStartPoint.timestamp;
    const velocity = distance / duration;

    // Detect tap
    if (distance < this.TAP_THRESHOLD && duration < 200) {
      this.handleTap(endPoint);
      this.preventNextClick = true;
    }
    // Detect swipe
    else if (distance > this.SWIPE_THRESHOLD && velocity > this.SWIPE_VELOCITY_THRESHOLD) {
      this.handleSwipe(this.touchStartPoint, endPoint, velocity, distance);
      this.preventNextClick = true;
    }

    this.touchStartPoint = null;
    this.pinchStartDistance = 0;
    this.isScrolling = false;

    e.preventDefault();
  }

  private handleTouchCancel(): void {
    this.cancelLongPress();
    this.touchStartPoint = null;
    this.pinchStartDistance = 0;
    this.isScrolling = false;
  }

  private handleTap(point: TouchPoint): void {
    const now = Date.now();
    const isDoubleTap =
      this.lastTapPoint !== null &&
      now - this.lastTapTime < this.DOUBLE_TAP_THRESHOLD &&
      this.getDistance(this.lastTapPoint, point) < this.TAP_THRESHOLD;

    if (this.onTap) {
      this.onTap({
        x: point.x,
        y: point.y,
        isDoubleTap
      });
    }

    this.lastTapTime = now;
    this.lastTapPoint = point;
  }

  private handleSwipe(start: TouchPoint, end: TouchPoint, velocity: number, distance: number): void {
    const deltaX = end.x - start.x;
    const deltaY = end.y - start.y;

    let direction: 'up' | 'down' | 'left' | 'right';

    if (Math.abs(deltaX) > Math.abs(deltaY)) {
      direction = deltaX > 0 ? 'right' : 'left';
    } else {
      direction = deltaY > 0 ? 'down' : 'up';
    }

    if (this.onSwipe) {
      this.onSwipe({
        direction,
        velocity,
        distance
      });
    }
  }

  private getDistance(point1: { x: number; y: number }, point2: { x: number; y: number }): number {
    const deltaX = point2.x - point1.x;
    const deltaY = point2.y - point1.y;
    return Math.sqrt(deltaX * deltaX + deltaY * deltaY);
  }

  private cancelLongPress(): void {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = null;
    }
  }

  // Public methods to set callbacks
  public setSwipeHandler(handler: (event: SwipeEvent) => void): void {
    this.onSwipe = handler;
  }

  public setTapHandler(handler: (event: TapEvent) => void): void {
    this.onTap = handler;
  }

  public setPinchHandler(handler: (event: PinchEvent) => void): void {
    this.onPinch = handler;
  }

  public setLongPressHandler(handler: (point: TouchPoint) => void): void {
    this.onLongPress = handler;
  }

  public destroy(): void {
    this.cancelLongPress();
    // Remove event listeners if needed
  }
}

// Helper function to determine if device is mobile
export function isMobileDevice(): boolean {
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ||
    (window.matchMedia && window.matchMedia('(max-width: 768px)').matches);
}

// Helper function to get terminal cell from coordinates
export function getCellFromCoordinates(x: number, y: number, container: HTMLElement): { row: number; col: number } | null {
  const rect = container.getBoundingClientRect();
  const relativeX = x - rect.left;
  const relativeY = y - rect.top;

  // Get computed styles
  const style = window.getComputedStyle(container);
  const fontSize = parseFloat(style.fontSize);
  const lineHeight = parseFloat(style.lineHeight) || fontSize * 1.5;

  // Calculate cell dimensions (1ch width)
  const cellWidth = fontSize * 0.6; // Approximate ch width
  const cellHeight = lineHeight;

  const col = Math.floor(relativeX / cellWidth);
  const row = Math.floor(relativeY / cellHeight);

  // Terminal is 80x24
  if (col >= 0 && col < 80 && row >= 0 && row < 24) {
    return { row, col };
  }

  return null;
}