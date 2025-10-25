/**
 * Code Copy Hook
 * Adds copy-to-clipboard buttons to code blocks
 */

export const CodeCopyHook = {
  mounted() {
    this.addCopyButtons();
  },

  updated() {
    this.addCopyButtons();
  },

  addCopyButtons() {
    const codeBlocks = this.el.querySelectorAll('pre.athl');

    codeBlocks.forEach((pre) => {
      // Skip if button already exists
      if (pre.querySelector('.copy-button')) return;

      const button = document.createElement('button');
      button.className = 'copy-button';
      button.setAttribute('aria-label', 'Copy code to clipboard');
      button.innerHTML = '<span class="copy-icon">[ copy ]</span>';

      button.addEventListener('click', async () => {
        const code = pre.querySelector('code');
        if (!code) return;

        try {
          await navigator.clipboard.writeText(code.textContent);
          button.innerHTML = '<span class="copy-icon">[ copied! ]</span>';
          button.classList.add('copied');

          setTimeout(() => {
            button.innerHTML = '<span class="copy-icon">[ copy ]</span>';
            button.classList.remove('copied');
          }, 2000);
        } catch (err) {
          console.error('Failed to copy code:', err);
          button.innerHTML = '<span class="copy-icon">[ error ]</span>';
          setTimeout(() => {
            button.innerHTML = '<span class="copy-icon">[ copy ]</span>';
          }, 2000);
        }
      });

      pre.appendChild(button);
    });
  }
};
