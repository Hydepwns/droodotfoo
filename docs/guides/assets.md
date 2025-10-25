# Asset Optimization Guide

Comprehensive guide to images, fonts, and asset management for droo.foo.

## Fonts

### Monaspace Font Family

Using Monaspace by GitHub Next for monospace aesthetic with texture healing.

**Variants Used:**
- **Argon** (Primary) - Default monospace
- **Krypton** - Functional code
- **Neon** - Warm/personal
- **Radon** - Mechanical precision
- **Xenon** - Editorial authority

### Implementation

**1. Font Files**
Location: `priv/static/fonts/`

```
MonaspaceArgon-Regular.woff2    (Primary text)
MonaspaceArgon-Bold.woff2       (Headings)
MonaspaceKrypton-*.woff2        (Code blocks)
MonaspaceNeon-*.woff2           (Comments)
MonaspaceRadon-*.woff2          (Keywords)
MonaspaceXenon-*.woff2          (Documentation)
```

**2. CSS Configuration**
Location: `assets/css/monospace.css`

```css
@font-face {
  font-family: "Monaspace Argon";
  src: url("/fonts/MonaspaceArgon-Regular.woff2") format("woff2");
  font-weight: 400;
  font-display: swap;
}

/* CSS Variables */
:root {
  --font-family-base: "Monaspace Argon", monospace;
  --font-family-warm: "Monaspace Neon", monospace;
  --font-family-precise: "Monaspace Radon", monospace;
  /* ... etc */
}
```

**3. Character-Perfect Grid**
- All layouts use `1ch` units for width
- Fixed 110-column terminal width
- Perfect monospace alignment

### Font Loading Strategy

**Optimized for Performance:**
```css
/* font-display: swap - prevents FOIT (Flash of Invisible Text) */
@font-face {
  font-display: swap;  /* Show fallback immediately */
}
```

**Preload Critical Fonts:**
```html
<!-- In root.html.heex -->
<link rel="preload" href="/fonts/MonaspaceArgon-Regular.woff2"
      as="font" type="font/woff2" crossorigin>
```

### Best Practices

✅ **DO:**
- Use WOFF2 format (best compression)
- Subset fonts to Latin characters only
- Preload primary font variant
- Use `font-display: swap`

❌ **DON'T:**
- Load all variants upfront
- Use WOFF or TTF (larger)
- Block render waiting for fonts
- Include unused Unicode ranges

## Images

### Format Strategy

**Primary Format: WebP**
- 25-35% smaller than JPEG
- Supports transparency (better than PNG)
- Wide browser support (95%+)

**Fallbacks:**
- JPEG for older browsers
- PNG for transparency needs
- SVG for logos and icons

### Optimization Workflow

**1. Source Images**
```bash
# Original (unoptimized)
priv/static/images/source/

# Optimized output
priv/static/images/
```

**2. Conversion Commands**

```bash
# WebP conversion
cwebp -q 85 source.jpg -o output.webp

# JPEG optimization
jpegoptim --max=85 --strip-all source.jpg

# PNG optimization
optipng -o7 source.png
pngquant --quality=80-95 source.png
```

**3. Responsive Images**

```html
<picture>
  <source
    srcset="image-320w.webp 320w,
            image-640w.webp 640w,
            image-1280w.webp 1280w"
    sizes="(max-width: 640px) 100vw, 640px"
    type="image/webp">
  <img src="image-640w.jpg"
       alt="Description"
       loading="lazy"
       width="640"
       height="480">
</picture>
```

### Image Guidelines

**Blog Post Images:**
- Max width: 1200px
- Format: WebP with JPEG fallback
- Compression: 85% quality
- Lazy load: Below the fold

**Social Sharing Images (OG):**
- Size: 1200×630px (required)
- Format: PNG or JPEG (WebP not widely supported)
- File size: < 300KB
- Location: `/images/og-*.png`

**Generated Patterns:**
- Format: SVG (inline or external)
- Deterministic generation per post
- Compression: Minified SVG
- Animation: CSS-based (optional)

### Lazy Loading

**Implementation:**
```html
<!-- Native lazy loading (modern browsers) -->
<img src="image.jpg" loading="lazy" alt="Description">

<!-- IntersectionObserver fallback for older browsers -->
<img data-src="image.jpg" class="lazy" alt="Description">
```

**JavaScript (if needed):**
```javascript
const images = document.querySelectorAll('img.lazy');
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const img = entry.target;
      img.src = img.dataset.src;
      img.classList.remove('lazy');
      observer.unobserve(img);
    }
  });
});
images.forEach(img => observer.observe(img));
```

### CDN Configuration

**Cloudflare Pages (Optional):**
```elixir
# config/runtime.exs
cdn_host = System.get_env("CDN_HOST")
static_url = if cdn_host,
  do: [host: cdn_host, scheme: "https"],
  else: [host: phx_host, scheme: "https"]
```

**Benefits:**
- Edge caching (faster delivery)
- Automatic WebP conversion
- Image resizing on-the-fly
- DDoS protection

## SVG Patterns

### Pattern Generation

**Deterministic Patterns:**
```elixir
# Pattern generated from post slug
Droodotfoo.Content.PatternGenerator.generate(
  slug,
  style: :geometric,
  animate: true
)
```

**8 Pattern Styles:**
1. `waves` - Flowing sine waves
2. `noise` - Digital static
3. `lines` - Parallel/radiating
4. `dots` - Halftone matrix
5. `circuit` - Circuit board
6. `glitch` - Data corruption
7. `geometric` - Classic shapes
8. `grid` - Cellular pattern

### Optimization

**SVG Minification:**
```bash
# Using SVGO
svgo input.svg -o output.svg

# Options
--multipass              # Multiple optimization passes
--pretty                 # Pretty output (dev only)
--precision 2            # Decimal places
```

**Inline vs External:**
- **Inline**: < 2KB, critical path
- **External**: > 2KB, cached separately

## Asset Pipeline

### Build Process

```bash
# Development
mix assets.build

# Production
mix assets.deploy
```

**Steps:**
1. Tailwind CSS compilation (with purging)
2. esbuild JavaScript bundling
3. Asset fingerprinting (cache busting)
4. Compression (gzip/brotli)

### Cache Strategy

**Static Assets:**
```elixir
# Far-future expires (1 year)
plug Plug.Static,
  at: "/",
  from: :droodotfoo,
  gzip: true,
  only: ~w(assets fonts images),
  cache_control_for_etags: "public, max-age=31536000"
```

**Fingerprinting:**
- File hash in filename: `app-ABC123.css`
- Automatic cache invalidation
- No manual cache busting needed

## Performance Budget

### Target Metrics

**Images:**
- Total image weight: < 500KB per page
- Largest image: < 200KB
- Format: 80%+ WebP adoption

**Fonts:**
- Total font weight: < 200KB
- WOFF2 only (no fallback formats)
- Subset to Latin characters

**Total Assets:**
- Initial bundle: < 100KB (gzipped)
- Full page weight: < 1MB
- Time to interactive: < 3s

## Tools & Resources

**Image Optimization:**
- [Squoosh](https://squoosh.app/) - Web-based optimizer
- [ImageOptim](https://imageoptim.com/) - Mac app
- [Sharp](https://sharp.pixelplumbing.com/) - Node.js library

**Font Tools:**
- [glyphhanger](https://github.com/zachleat/glyphhanger) - Font subsetting
- [Font Squirrel](https://www.fontsquirrel.com/tools/webfont-generator) - Web font generator
- [Monaspace](https://monaspace.githubnext.com/) - Official site

**Testing:**
- [WebPageTest](https://www.webpagetest.org/)
- [PageSpeed Insights](https://pagespeed.web.dev/)
- [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci)
