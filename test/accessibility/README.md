# Accessibility Testing

Automated accessibility testing using axe-core and Playwright to ensure WCAG 2.1 Level AA compliance.

## Setup

```bash
cd test/accessibility
npm install
npx playwright install chromium
```

## Running Tests

### Local Development

Start your Phoenix server first:

```bash
# In the project root
mix phx.server
```

Then run accessibility tests:

```bash
# In test/accessibility directory
npm test
```

### Test Production

```bash
npm test -- --url=https://droo.foo
```

## What Gets Tested

The test suite checks all main pages:
- Home (/)
- About (/about)
- Now (/now)
- Projects (/projects)
- Writing (/posts)
- Sitemap (/sitemap)

## WCAG Standards

Tests against:
- WCAG 2.0 Level A
- WCAG 2.0 Level AA
- WCAG 2.1 Level A
- WCAG 2.1 Level AA

## Interpreting Results

Violations are categorized by severity:

- **Critical**: Must be fixed immediately
- **Serious**: Should be fixed soon
- **Moderate**: Should be addressed
- **Minor**: Nice to fix

Each violation includes:
- Description of the issue
- Help text explaining how to fix it
- Link to detailed documentation
- Affected HTML elements

## Common Issues to Check

- Missing alt text on images
- Insufficient color contrast
- Missing ARIA labels on interactive elements
- Improper heading hierarchy
- Missing form labels
- Keyboard navigation issues

## Adding New Pages

Edit `test-accessibility.js` and add to the `PAGES_TO_TEST` array:

```javascript
const PAGES_TO_TEST = [
  { path: '/your-new-page', name: 'New Page' },
  // ... existing pages
];
```

## CI Integration

The test can be run in CI with the `--ci` flag:

```bash
npm test -- --ci --url=https://your-preview-url.com
```

## Resources

- [axe-core rules](https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM WCAG 2 Checklist](https://webaim.org/standards/wcag/checklist)
