/**
 * Contribution Graph Hook
 * Hover/focus tooltip for contribution grid cells via event delegation.
 * Supports mouse and keyboard (arrow keys) navigation.
 */

const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const DAYS = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

function formatDate(iso: string): string {
  const d = new Date(iso + 'T00:00:00');
  return `${DAYS[d.getDay()]}, ${MONTHS[d.getMonth()]} ${d.getDate()}`;
}

export const ContributionGraphHook = {
  mounted() {
    this.tooltip = this.el.querySelector('.contrib-tooltip');
    this.activeCell = null as HTMLElement | null;
    this.cells = [] as HTMLElement[];
    this._setup();
  },

  updated() {
    this.cells = Array.from(
      this.el.querySelectorAll('.contrib-cell[data-date]')
    ) as HTMLElement[];
    this.tooltip = this.el.querySelector('.contrib-tooltip');
    this._scrollToRecent();
  },

  _setup() {
    if (!this.tooltip) return;

    this.cells = Array.from(
      this.el.querySelectorAll('.contrib-cell[data-date]')
    ) as HTMLElement[];

    this.el.addEventListener('mouseover', (e: MouseEvent) => {
      const cell = (e.target as HTMLElement).closest('.contrib-cell[data-date]');
      if (cell instanceof HTMLElement) this._showTooltip(cell);
    });

    this.el.addEventListener('mouseout', (e: MouseEvent) => {
      if ((e.target as HTMLElement).closest('.contrib-cell')) this._hideTooltip();
    });

    this.el.addEventListener('focus', (e: FocusEvent) => {
      const cell = e.target as HTMLElement;
      if (cell.classList.contains('contrib-cell') && cell.dataset.date) {
        this._showTooltip(cell);
      }
    }, true);

    this.el.addEventListener('blur', (e: FocusEvent) => {
      if ((e.target as HTMLElement).classList.contains('contrib-cell')) {
        this._hideTooltip();
      }
    }, true);

    this.el.addEventListener('keydown', (e: KeyboardEvent) => {
      const cell = e.target as HTMLElement;
      if (!cell.classList.contains('contrib-cell')) return;

      const idx = this.cells.indexOf(cell);
      if (idx === -1) return;

      let next = -1;
      switch (e.key) {
        case 'ArrowRight': next = idx + 7; break;
        case 'ArrowLeft': next = idx - 7; break;
        case 'ArrowDown': next = idx + 1; break;
        case 'ArrowUp': next = idx - 1; break;
        default: return;
      }

      if (next >= 0 && next < this.cells.length) {
        e.preventDefault();
        cell.setAttribute('tabindex', '-1');
        this.cells[next].setAttribute('tabindex', '0');
        this.cells[next].focus();
      }
    });

    this._scrollToRecent();
  },

  _showTooltip(cell: HTMLElement) {
    const { date, count, repos, types } = cell.dataset;
    if (!date || !this.tooltip) return;

    // Clear active highlight from previous cell
    if (this.activeCell) this.activeCell.classList.remove('contrib-active');
    cell.classList.add('contrib-active');
    this.activeCell = cell;

    const n = parseInt(count || '0', 10);

    // Build structured tooltip HTML
    let html = `<strong>${formatDate(date)}</strong>`;
    html += `<span class="contrib-tooltip-count">${n} contribution${n === 1 ? '' : 's'}</span>`;
    if (types) html += `<span class="contrib-tooltip-types">${types}</span>`;
    if (repos) html += `<span class="contrib-tooltip-repos">${repos}</span>`;

    this.tooltip.innerHTML = html;
    this.tooltip.classList.add('visible');

    // Position relative to graph container with bounds clamping
    const graphRect = this.el.getBoundingClientRect();
    const cellRect = cell.getBoundingClientRect();
    const tooltipWidth = this.tooltip.offsetWidth;
    const tooltipHeight = this.tooltip.offsetHeight;

    // Center tooltip horizontally on cell
    let left = (cellRect.left - graphRect.left) + (cellRect.width / 2) - (tooltipWidth / 2);
    let top = cellRect.top - graphRect.top - tooltipHeight - 8;

    // Clamp horizontal
    const maxLeft = graphRect.width - tooltipWidth;
    if (left > maxLeft) left = maxLeft;
    if (left < 0) left = 0;

    // Flip below cell if clipped at top
    if (top < 0) {
      top = cellRect.bottom - graphRect.top + 8;
      this.tooltip.classList.add('below');
      this.tooltip.classList.remove('above');
    } else {
      this.tooltip.classList.add('above');
      this.tooltip.classList.remove('below');
    }

    this.tooltip.style.left = `${left}px`;
    this.tooltip.style.top = `${top}px`;
  },

  _hideTooltip() {
    if (this.activeCell) {
      this.activeCell.classList.remove('contrib-active');
      this.activeCell = null;
    }
    if (this.tooltip) this.tooltip.classList.remove('visible');
  },

  _scrollToRecent() {
    const graph = this.el.querySelector('.contrib-graph');
    if (graph && graph.scrollWidth > graph.clientWidth) {
      graph.scrollLeft = graph.scrollWidth;
    }
  }
};
