/**
 * Abbr Popover Hook
 *
 * Progressively enhances <abbr title="..."> elements inside posts.
 * Native tooltips work on desktop hover; this hook adds tap/keyboard
 * behaviour and a styled popover that survives mobile viewports.
 *
 * Markup expectations:
 *   <abbr title="Recursive Length Prefix">RLP</abbr>
 *
 * After enhancement:
 *   <abbr data-tooltip="..." role="button" tabindex="0" aria-describedby="...">RLP</abbr>
 *   <div role="tooltip" id="..." class="abbr-popover">...</div>  (appended to body)
 */

interface HookContext {
  el: HTMLElement;
  popover?: HTMLDivElement;
  activeAbbr?: HTMLElement | null;
  handlers?: {
    onClick: (e: Event) => void;
    onFocusIn: (e: FocusEvent) => void;
    onFocusOut: (e: FocusEvent) => void;
    onKeyDown: (e: KeyboardEvent) => void;
    onDocClick: (e: MouseEvent) => void;
    onScroll: () => void;
  };
}

let popoverIdSeq = 0;

export const AbbrPopoverHook = {
  mounted(this: HookContext) {
    const abbrs = Array.from(
      this.el.querySelectorAll<HTMLElement>('abbr[title]')
    );
    if (abbrs.length === 0) return;

    this.popover = document.createElement('div');
    this.popover.className = 'abbr-popover';
    this.popover.setAttribute('role', 'tooltip');
    this.popover.hidden = true;
    document.body.appendChild(this.popover);

    abbrs.forEach((abbr) => {
      const tooltip = abbr.getAttribute('title') ?? '';
      abbr.setAttribute('data-tooltip', tooltip);
      abbr.removeAttribute('title');
      abbr.setAttribute('role', 'button');
      abbr.setAttribute('tabindex', '0');
      abbr.setAttribute('aria-describedby', `abbr-popover-${++popoverIdSeq}`);
    });

    this.handlers = {
      onClick: (e: Event) => {
        const target = (e.target as HTMLElement).closest('abbr[data-tooltip]');
        if (!target) return;
        e.preventDefault();
        this.activeAbbr === target
          ? hidePopover(this)
          : showPopover(this, target as HTMLElement);
      },
      onFocusIn: (e: FocusEvent) => {
        const target = (e.target as HTMLElement).closest?.('abbr[data-tooltip]');
        if (target) showPopover(this, target as HTMLElement);
      },
      onFocusOut: (e: FocusEvent) => {
        const target = (e.target as HTMLElement).closest?.('abbr[data-tooltip]');
        if (target && target === this.activeAbbr) hidePopover(this);
      },
      onKeyDown: (e: KeyboardEvent) => {
        const target = (e.target as HTMLElement).closest?.('abbr[data-tooltip]');
        if (target && (e.key === 'Enter' || e.key === ' ')) {
          e.preventDefault();
          this.activeAbbr === target
            ? hidePopover(this)
            : showPopover(this, target as HTMLElement);
        }
        if (e.key === 'Escape' && this.activeAbbr) {
          const focused = this.activeAbbr;
          hidePopover(this);
          focused.focus();
        }
      },
      onDocClick: (e: MouseEvent) => {
        if (!this.activeAbbr) return;
        const t = e.target as Node;
        if (this.activeAbbr.contains(t)) return;
        if (this.popover?.contains(t)) return;
        hidePopover(this);
      },
      onScroll: () => {
        if (this.activeAbbr) position(this, this.activeAbbr);
      },
    };

    this.el.addEventListener('click', this.handlers.onClick);
    this.el.addEventListener('focusin', this.handlers.onFocusIn);
    this.el.addEventListener('focusout', this.handlers.onFocusOut);
    this.el.addEventListener('keydown', this.handlers.onKeyDown);
    document.addEventListener('click', this.handlers.onDocClick);
    window.addEventListener('scroll', this.handlers.onScroll, { passive: true });
    window.addEventListener('resize', this.handlers.onScroll, { passive: true });
  },

  destroyed(this: HookContext) {
    if (this.handlers) {
      this.el.removeEventListener('click', this.handlers.onClick);
      this.el.removeEventListener('focusin', this.handlers.onFocusIn);
      this.el.removeEventListener('focusout', this.handlers.onFocusOut);
      this.el.removeEventListener('keydown', this.handlers.onKeyDown);
      document.removeEventListener('click', this.handlers.onDocClick);
      window.removeEventListener('scroll', this.handlers.onScroll);
      window.removeEventListener('resize', this.handlers.onScroll);
    }
    this.popover?.remove();
  },
};

function showPopover(ctx: HookContext, abbr: HTMLElement) {
  if (!ctx.popover) return;
  ctx.popover.textContent = abbr.getAttribute('data-tooltip') ?? '';
  ctx.popover.id = abbr.getAttribute('aria-describedby') ?? '';
  ctx.popover.hidden = false;
  ctx.activeAbbr = abbr;
  position(ctx, abbr);
}

function hidePopover(ctx: HookContext) {
  if (!ctx.popover) return;
  ctx.popover.hidden = true;
  ctx.activeAbbr = null;
}

function position(ctx: HookContext, abbr: HTMLElement) {
  if (!ctx.popover) return;
  const rect = abbr.getBoundingClientRect();
  const pop = ctx.popover;
  // Render once to measure
  pop.style.left = '0';
  pop.style.top = '0';
  const popRect = pop.getBoundingClientRect();
  const margin = 8;
  const viewportW = window.innerWidth;
  const viewportH = window.innerHeight;

  let left = rect.left + window.scrollX;
  if (left + popRect.width > window.scrollX + viewportW - margin) {
    left = window.scrollX + viewportW - popRect.width - margin;
  }
  if (left < window.scrollX + margin) left = window.scrollX + margin;

  let top = rect.bottom + window.scrollY + 6;
  if (top + popRect.height > window.scrollY + viewportH - margin) {
    top = rect.top + window.scrollY - popRect.height - 6;
  }

  pop.style.left = `${left}px`;
  pop.style.top = `${top}px`;
}
