/**
 * Module for measuring terminal cell dimensions
 */
import { CellDimensions } from '../types';

export class CellMeasurement {
  private static readonly DEFAULT_CONFIG = {
    fontFamily: 'Monaspace Argon, monospace',
    fontSize: '16px',
    lineHeight: '1.20rem',
    testCharacter: 'M'
  };

  /**
   * Measures exact character cell dimensions
   * @param config - Optional configuration for measurement
   * @returns Cell dimensions (width and height)
   */
  static measure(config: Partial<typeof CellMeasurement.DEFAULT_CONFIG> = {}): CellDimensions {
    const mergedConfig = { ...this.DEFAULT_CONFIG, ...config };

    const testElement = this.createTestElement(mergedConfig);
    let dimensions: CellDimensions;

    try {
      document.body.appendChild(testElement);
      const rect = testElement.getBoundingClientRect();

      dimensions = {
        width: rect.width,
        height: rect.height
      };

      if (dimensions.width <= 0 || dimensions.height <= 0) {
        throw new Error('Invalid cell dimensions measured');
      }

      console.log(`Cell dimensions measured: ${dimensions.width}x${dimensions.height}`);
    } catch (error) {
      console.error('Failed to measure cell dimensions:', error);
      // Fallback to reasonable defaults
      dimensions = { width: 9.6, height: 19.2 };
    } finally {
      // Always clean up the test element
      if (testElement.parentNode) {
        document.body.removeChild(testElement);
      }
    }

    return dimensions;
  }

  /**
   * Creates a test element for measurement
   * @private
   */
  private static createTestElement(config: typeof CellMeasurement.DEFAULT_CONFIG): HTMLSpanElement {
    const element = document.createElement('span');

    element.style.position = 'fixed';
    element.style.visibility = 'hidden';
    element.style.pointerEvents = 'none';
    element.style.fontFamily = config.fontFamily;
    element.style.fontSize = config.fontSize;
    element.style.lineHeight = config.lineHeight;
    element.style.whiteSpace = 'pre';
    element.textContent = config.testCharacter;

    return element;
  }
}