/**
 * Common type definitions for the terminal application
 */

export interface CellDimensions {
  width: number;
  height: number;
}

export interface GridConfig {
  container: HTMLElement;
  fontFamily?: string;
  fontSize?: string;
  lineHeight?: string;
  testCharacter?: string;
}

export interface GridProperties {
  cellWidth: number;
  cellHeight: number;
  columns: number;
  exactWidth: number;
}

export interface AlignmentResult {
  isAligned: boolean;
  rowOffset?: number;
  colOffset?: number;
}

export interface DebugResult {
  aligned: number;
  misaligned: number;
  cells: HTMLElement[];
}

export type EventCallback = () => void;

export interface GridEventListeners {
  resize?: EventCallback;
  fontLoad?: EventCallback;
}