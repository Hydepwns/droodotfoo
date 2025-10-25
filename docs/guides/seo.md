# SEO Optimization Guide

Comprehensive SEO implementation including JSON-LD structured data and performance optimization.

## JSON-LD Structured Data

Implemented following schema.org specifications for enhanced search engine visibility.

### Schemas Implemented

**1. Person Schema**
- Pages: Homepage, About
- Includes: Name, job title, social links, skills
- Links: GitHub, Twitter, LinkedIn

**2. WebSite Schema**
- Pages: Homepage
- Describes site structure and authorship

**3. Article Schema**
- Pages: Individual blog posts (`/posts/:slug`)
- Features: Title, dates, author, keywords, series support
- Series integration via `isPartOf` property

**4. SoftwareSourceCode Schema**
- Pages: Projects (`/projects`)
- Includes: Repository URL, language, GitHub stats (stars/forks)
- Dynamic InteractionCounter for engagement metrics

**5. BreadcrumbList Schema**
- Pages: All major pages
- Hierarchical navigation for search snippets

### Implementation

Location: `lib/droodotfoo_web/seo/json_ld.ex`

```elixir
# Usage in LiveView
def mount(_params, _session, socket) do
  json_ld = [
    JsonLD.person_schema(),
    JsonLD.breadcrumb_schema([
      {"Home", "/"},
      {"About", "/about"}
    ])
  ]

  {:ok, assign(socket, :json_ld, json_ld)}
end
```

### Testing

**1. Manual Verification**
- View page source
- Search for `<script type="application/ld+json">`
- Verify JSON structure

**2. Google Rich Results Test**
https://search.google.com/test/rich-results

**3. Schema.org Validator**
https://validator.schema.org/

### SEO Benefits

- **Rich Snippets**: Enhanced search results with metadata
- **Knowledge Panels**: Improved Google Knowledge Graph presence
- **Voice Search**: Better assistant understanding
- **Breadcrumbs**: Navigation in search results
- **Social Cards**: Enhanced link previews

## Performance Optimization

### Current Status

**Lighthouse Scores (as of Oct 2025):**
- Performance: 95+
- Accessibility: 98+
- Best Practices: 100
- SEO: 100

### Key Optimizations

**1. Asset Loading**
```javascript
// Lazy-loaded hooks (35KB saved on initial load)
const LazyHooks = {
  STLViewerHook: () => import('./hooks/stl_viewer'),
  Web3WalletHook: () => import('./hooks/web3_wallet'),
  // ... others
};
```

**2. Image Optimization**
- WebP format with fallbacks
- Responsive images with srcset
- Lazy loading below fold
- See [assets.md](assets.md) for details

**3. CSS Optimization**
- Tailwind purging (removes unused classes)
- Critical CSS inlined
- Font loading optimized (see [assets.md](assets.md))

**4. Caching Strategy**
- GitHub data cached (15min TTL)
- Blog posts cached in ETS
- Static assets with cache headers

### Performance Monitoring

```bash
# Local Lighthouse audit
npx lighthouse http://localhost:4000 --view

# Production audit
npx lighthouse https://droo.foo --view
```

### Performance Budget

Target metrics:
- First Contentful Paint: < 1.5s
- Largest Contentful Paint: < 2.5s
- Time to Interactive: < 3.5s
- Cumulative Layout Shift: < 0.1
- Total Blocking Time: < 300ms

## Meta Tags

### Open Graph
All pages include:
- `og:title`, `og:description`, `og:image`
- `og:type` (website/article)
- `og:url` with canonical links

### Twitter Cards
- `twitter:card`: summary_large_image
- `twitter:site`: @MF_DROO
- Author attribution

### Article-Specific
Blog posts include:
- `article:published_time`
- `article:modified_time`
- `article:section` (from primary tag)
- `article:tag` (all post tags)

## Sitemap & Discovery

**XML Sitemap**: `/sitemap.xml`
- Auto-generated from routes
- Includes blog posts with priorities
- Updated on content changes

**RSS Feed**: `/feed.xml`
- Latest posts with full content
- Proper RFC 822 date formatting
- Includes author and categories

**Robots.txt**: `/robots.txt`
- Allows all crawlers
- Links to sitemap

**Human Sitemap**: `/sitemap`
- ASCII tree navigation
- Accessible fallback

## Future Enhancements

- [ ] FAQ schema for common questions
- [ ] HowTo schema for tutorial posts
- [ ] VideoObject schema (if adding videos)
- [ ] Review schema (testimonials)
- [ ] Event schema (talks/appearances)
- [ ] Course schema (tutorial series)

## Maintenance

**Update Personal Info**
```elixir
# lib/droodotfoo_web/seo/json_ld.ex
def person_schema do
  %{
    "name" => "Andrew Hyde (DROO)",  # Update here
    "jobTitle" => "...",              # Update here
    "sameAs" => [...]                 # Update social links
  }
end
```

**Monitor Search Console**
- Track click-through rates
- Monitor structured data errors
- Check mobile usability
- Review Core Web Vitals
