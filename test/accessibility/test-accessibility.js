/**
 * Automated Accessibility Testing with axe-core
 *
 * Tests all main pages of droo.foo for WCAG 2.1 Level AA compliance.
 * Uses Playwright + axe-core to detect accessibility violations.
 *
 * Usage:
 *   npm test                  # Test against http://localhost:4000
 *   npm test -- --url https://droo.foo  # Test production
 */

const { chromium } = require('playwright');
const AxeBuilder = require('@axe-core/playwright').default;

// Pages to test
const PAGES_TO_TEST = [
  { path: '/', name: 'Home' },
  { path: '/about', name: 'About' },
  { path: '/now', name: 'Now' },
  { path: '/projects', name: 'Projects' },
  { path: '/posts', name: 'Writing' },
  { path: '/sitemap', name: 'Sitemap' }
];

// Violation severity levels
const SEVERITY_COLORS = {
  critical: '\x1b[41m\x1b[37m', // Red background
  serious: '\x1b[31m',          // Red text
  moderate: '\x1b[33m',         // Yellow text
  minor: '\x1b[36m'             // Cyan text
};

const RESET = '\x1b[0m';

// Parse command line arguments
const args = process.argv.slice(2);
const baseURL = args.find(arg => arg.startsWith('--url='))?.split('=')[1] || 'http://localhost:4000';
const isCi = args.includes('--ci');

async function testPage(page, url, pageName) {
  console.log(`\n Testing: ${pageName} (${url})`);

  try {
    await page.goto(url, { waitUntil: 'networkidle', timeout: 10000 });

    // Run axe accessibility scan
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
      .analyze();

    const violations = results.violations;

    if (violations.length === 0) {
      console.log(`  ✓ No accessibility violations found`);
      return { passed: true, violations: [] };
    }

    console.log(`  ✗ Found ${violations.length} accessibility issue(s):\n`);

    violations.forEach((violation, index) => {
      const color = SEVERITY_COLORS[violation.impact] || '';

      console.log(`  ${index + 1}. ${color}[${violation.impact.toUpperCase()}]${RESET} ${violation.help}`);
      console.log(`     Rule: ${violation.id}`);
      console.log(`     Description: ${violation.description}`);
      console.log(`     Help: ${violation.helpUrl}`);
      console.log(`     Affected elements: ${violation.nodes.length}`);

      violation.nodes.forEach((node, nodeIndex) => {
        if (nodeIndex < 3) { // Show first 3 affected elements
          console.log(`       - ${node.html.substring(0, 100)}${node.html.length > 100 ? '...' : ''}`);
        }
      });

      if (violation.nodes.length > 3) {
        console.log(`       ... and ${violation.nodes.length - 3} more element(s)`);
      }

      console.log('');
    });

    return { passed: false, violations };

  } catch (error) {
    console.error(`  ✗ Error testing ${pageName}:`, error.message);
    return { passed: false, error: error.message };
  }
}

async function runTests() {
  console.log(`\n┌─────────────────────────────────────────────┐`);
  console.log(`│  Accessibility Testing with axe-core        │`);
  console.log(`│  Testing: ${baseURL.padEnd(31)}│`);
  console.log(`└─────────────────────────────────────────────┘`);

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 }
  });
  const page = await context.newPage();

  const results = [];

  for (const pageConfig of PAGES_TO_TEST) {
    const url = `${baseURL}${pageConfig.path}`;
    const result = await testPage(page, url, pageConfig.name);
    results.push({ ...pageConfig, ...result });
  }

  await browser.close();

  // Summary
  console.log(`\n┌─────────────────────────────────────────────┐`);
  console.log(`│  Test Summary                               │`);
  console.log(`└─────────────────────────────────────────────┘\n`);

  const passed = results.filter(r => r.passed).length;
  const failed = results.filter(r => !r.passed).length;
  const totalViolations = results.reduce((sum, r) => sum + (r.violations?.length || 0), 0);

  console.log(`  Pages tested: ${results.length}`);
  console.log(`  Passed: ${passed}`);
  console.log(`  Failed: ${failed}`);
  console.log(`  Total violations: ${totalViolations}\n`);

  results.forEach(result => {
    const icon = result.passed ? '✓' : '✗';
    const status = result.passed ? 'PASS' : `FAIL (${result.violations?.length || 0} issues)`;
    console.log(`  ${icon} ${result.name.padEnd(15)} ${status}`);
  });

  console.log('');

  // Exit with error code if any violations found
  if (failed > 0) {
    process.exit(1);
  }
}

// Run tests
runTests().catch(error => {
  console.error('Test execution failed:', error);
  process.exit(1);
});
