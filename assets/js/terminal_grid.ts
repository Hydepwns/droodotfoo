/**
 * Maintains strict monospace grid alignment.
 * Based on the-monospace-web's grid system.
 */
import { GridConfig, GridProperties, DebugResult } from './types';
import { CellMeasurement } from './modules/CellMeasurement';
import { GridAlignment } from './modules/GridAlignment';
import { EventManager } from './modules/EventManager';

export class MonospaceGrid {
  private readonly container: HTMLElement;
  private cellWidth: number = 0;
  private cellHeight: number = 0;
  private alignment: GridAlignment | null = null;
  private eventManager: EventManager;
  private resizeTimeout: NodeJS.Timeout | null = null;
  private readonly config: Required<GridConfig>;

  constructor(container: HTMLElement, config: Partial<GridConfig> = {}) {
    if (!container) {
      throw new Error('Container element is required');
    }

    this.container = container;
    this.config = {
      container,
      fontFamily: 'Monaspace Argon, monospace',
      fontSize: '16px',
      lineHeight: '1.20rem',
      testCharacter: 'M',
      ...config
    };

    this.eventManager = new EventManager();
    this.init();
  }

  /**
   * Initializes the grid system
   */
  private init(): void {
    try {
      // Calculate exact cell dimensions
      this.measureCell();

      // Apply grid enforcement
      this.enforceGrid();

      // Initialize alignment checker
      this.alignment = new GridAlignment(this.container, this.cellWidth, this.cellHeight);

      // Monitor for changes
      this.observeChanges();

      console.log('MonospaceGrid initialized successfully');
    } catch (error) {
      console.error('Failed to initialize MonospaceGrid:', error);
      throw error;
    }
  }

  /**
   * Measures cell dimensions using the CellMeasurement module
   */
  private measureCell(): void {
    const dimensions = CellMeasurement.measure({
      fontFamily: this.config.fontFamily,
      fontSize: this.config.fontSize,
      lineHeight: this.config.lineHeight,
      testCharacter: this.config.testCharacter
    });

    this.cellWidth = dimensions.width;
    this.cellHeight = dimensions.height;

    // Update alignment module if it exists
    if (this.alignment) {
      this.alignment = new GridAlignment(this.container, this.cellWidth, this.cellHeight);
    }
  }

  /**
   * Enforces grid alignment on the container
   * @returns Grid properties after enforcement
   */
  enforceGrid(): GridProperties {
    if (!this.cellWidth || !this.cellHeight) {
      throw new Error('Cell dimensions not measured');
    }

    const containerWidth = this.container.offsetWidth;
    const cols = Math.floor(containerWidth / this.cellWidth);
    const exactWidth = cols * this.cellWidth;

    // Apply exact width to maintain grid
    this.container.style.width = `${exactWidth}px`;

    // Apply CSS custom properties for use in styles
    this.container.style.setProperty('--cell-width', `${this.cellWidth}px`);
    this.container.style.setProperty('--cell-height', `${this.cellHeight}px`);
    this.container.style.setProperty('--grid-cols', cols.toString());

    const properties: GridProperties = {
      cellWidth: this.cellWidth,
      cellHeight: this.cellHeight,
      columns: cols,
      exactWidth
    };

    console.log('Grid enforced:', properties);
    return properties;
  }

  /**
   * Sets up observers for changes that might affect the grid
   */
  private observeChanges(): void {
    // Debounced resize handler
    const handleResize = () => {
      if (this.resizeTimeout) {
        clearTimeout(this.resizeTimeout);
      }

      this.resizeTimeout = setTimeout(() => {
        try {
          this.enforceGrid();
          this.eventManager.emit('gridResized');
        } catch (error) {
          console.error('Error during resize:', error);
        }
      }, 100);
    };

    this.eventManager.addWindowListener('resize', handleResize);

    // Re-enforce grid on font load
    this.eventManager.monitorFontLoad(() => {
      try {
        this.measureCell();
        this.enforceGrid();
        this.eventManager.emit('fontLoaded');
      } catch (error) {
        console.error('Error after font load:', error);
      }
    });
  }

  /**
   * Verifies that an element is grid-aligned
   * @param element - Element to check
   * @returns True if aligned, false otherwise
   */
  isAligned(element: HTMLElement): boolean {
    if (!this.alignment) {
      console.warn('Alignment module not initialized');
      return false;
    }

    const result = this.alignment.isAligned(element);
    return result.isAligned;
  }

  /**
   * Debug function to verify grid alignment
   * @param addVisualDebug - Whether to add visual debug indicators
   * @returns Debug result with statistics
   */
  debugGrid(addVisualDebug = false): DebugResult {
    if (!this.alignment) {
      throw new Error('Grid not initialized');
    }

    return this.alignment.debugGrid(addVisualDebug);
  }

  /**
   * Clears debug visual indicators
   */
  clearDebug(): void {
    if (this.alignment) {
      this.alignment.clearDebug();
    }
  }

  /**
   * Gets current grid properties
   * @returns Current grid properties
   */
  getProperties(): GridProperties {
    return {
      cellWidth: this.cellWidth,
      cellHeight: this.cellHeight,
      columns: parseInt(this.container.style.getPropertyValue('--grid-cols') || '0'),
      exactWidth: parseFloat(this.container.style.width || '0')
    };
  }

  /**
   * Cleans up resources and event listeners
   */
  destroy(): void {
    if (this.resizeTimeout) {
      clearTimeout(this.resizeTimeout);
      this.resizeTimeout = null;
    }

    this.eventManager.cleanup();
    this.clearDebug();

    // Remove CSS custom properties
    this.container.style.removeProperty('--cell-width');
    this.container.style.removeProperty('--cell-height');
    this.container.style.removeProperty('--grid-cols');

    console.log('MonospaceGrid destroyed');
  }

  /**
   * Subscribe to grid events
   * @param event - Event name ('gridResized', 'fontLoaded')
   * @param callback - Event callback
   */
  on(event: string, callback: () => void): void {
    this.eventManager.on(event, callback);
  }

  /**
   * Unsubscribe from grid events
   * @param event - Event name
   * @param callback - Event callback
   */
  off(event: string, callback: () => void): void {
    this.eventManager.off(event, callback);
  }
}

// Export for use in hooks
export default MonospaceGrid;