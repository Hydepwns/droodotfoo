/**
 * Module for verifying and debugging grid alignment
 */
import { AlignmentResult, DebugResult } from '../types';

export class GridAlignment {
  private readonly container: HTMLElement;
  private readonly cellWidth: number;
  private readonly cellHeight: number;
  private readonly tolerance: number;

  constructor(container: HTMLElement, cellWidth: number, cellHeight: number, tolerance = 0.5) {
    this.container = container;
    this.cellWidth = cellWidth;
    this.cellHeight = cellHeight;
    this.tolerance = tolerance;
  }

  /**
   * Verifies if an element is grid-aligned
   * @param element - Element to check
   * @returns Alignment result with details
   */
  isAligned(element: HTMLElement): AlignmentResult {
    try {
      const rect = element.getBoundingClientRect();
      const containerRect = this.container.getBoundingClientRect();

      const relativeTop = rect.top - containerRect.top;
      const relativeLeft = rect.left - containerRect.left;

      const rowOffset = relativeTop % this.cellHeight;
      const colOffset = relativeLeft % this.cellWidth;

      const isAligned = Math.abs(rowOffset) < this.tolerance && Math.abs(colOffset) < this.tolerance;

      return {
        isAligned,
        rowOffset: isAligned ? undefined : rowOffset,
        colOffset: isAligned ? undefined : colOffset
      };
    } catch (error) {
      console.error('Failed to check alignment:', error);
      return { isAligned: false };
    }
  }

  /**
   * Debug function to verify grid alignment of all cells
   * @param addVisualDebug - Whether to add visual debugging classes
   * @returns Debug result with statistics
   */
  debugGrid(addVisualDebug = false): DebugResult {
    const cells = Array.from(this.container.querySelectorAll('.cell')) as HTMLElement[];
    let misaligned = 0;
    const misalignedCells: HTMLElement[] = [];

    if (addVisualDebug) {
      this.container.classList.add('debug-grid');
    }

    cells.forEach((cell) => {
      const result = this.isAligned(cell);

      if (!result.isAligned) {
        misaligned++;
        misalignedCells.push(cell);

        if (addVisualDebug) {
          cell.classList.add('misaligned');
          cell.setAttribute('data-row-offset', String(result.rowOffset || 0));
          cell.setAttribute('data-col-offset', String(result.colOffset || 0));
        }
      } else if (addVisualDebug) {
        cell.classList.remove('misaligned');
        cell.removeAttribute('data-row-offset');
        cell.removeAttribute('data-col-offset');
      }
    });

    if (misaligned > 0) {
      console.warn(`${misaligned} of ${cells.length} cells are misaligned!`);
    } else {
      console.log(`All ${cells.length} cells are properly aligned`);
    }

    return {
      aligned: cells.length - misaligned,
      misaligned,
      cells: misalignedCells
    };
  }

  /**
   * Removes debug visual indicators
   */
  clearDebug(): void {
    this.container.classList.remove('debug-grid');

    const cells = this.container.querySelectorAll('.cell.misaligned');
    cells.forEach(cell => {
      cell.classList.remove('misaligned');
      cell.removeAttribute('data-row-offset');
      cell.removeAttribute('data-col-offset');
    });
  }
}