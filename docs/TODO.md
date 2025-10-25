# TODO - droo.foo

> Personal portfolio and blog with Phoenix LiveView

## Current Status

**Last Updated**: Oct 25, 2025
**Version**: v1.0.0
**Test Coverage**: 41.2% (1,170 tests, 1,149 passing)
**Focus**: Blog system with generative art patterns

---

## Quick Commands

```bash
mix phx.server              # Start development server
./bin/dev                   # Start with 1Password secrets
mix test                    # Run test suite
mix test --exclude flaky    # Stable tests only
mix docs                    # Generate documentation
mix precommit               # Format, compile, test
```

---

## Active Priorities

### Blog & Content

**High Priority:**
- [ ] Add more blog posts (current: 1 post)
- [ ] Create multi-part tutorial series using series navigation
- [ ] Write about Elixir/Phoenix development process

**Medium Priority:**
- [ ] Implement image optimization pipeline (see `IMAGE_OPTIMIZATION.md`)
- [ ] Add code snippet component with copy button
- [ ] Table of contents for long posts
- [ ] Estimated reading time more visible

**Low Priority:**
- [ ] Tag filtering on posts page
- [ ] Search functionality across posts
- [ ] Related posts recommendations
- [ ] Post excerpt on listing page

### Projects Page

**High Priority:**
- [ ] Add more project descriptions
- [ ] Link to live demos where available
- [ ] Add project images/screenshots

**Low Priority:**
- [ ] Filter projects by technology
- [ ] Contribution timeline visualization
- [ ] Project detail pages

### Performance & Polish

**High Priority:**
- [ ] Monitor Lighthouse scores (target: 90+ across all metrics)
- [ ] Optimize SVG pattern file sizes
- [ ] Review and optimize CSS bundle size

**Medium Priority:**
- [ ] Implement service worker for offline reading
- [ ] Add PWA manifest for installability
- [ ] Progressive image loading

**Low Priority:**
- [ ] Dark mode improvements
- [ ] Font loading optimization
- [ ] Reduce JavaScript bundle size

### DevOps & Infrastructure

**High Priority:**
- [ ] Set up GitHub Actions CI/CD
  - [ ] Run tests on PR
  - [ ] Deploy to Fly.io on merge to main
  - [ ] Coverage reporting

**Medium Priority:**
- [ ] Monitoring and error tracking (Sentry/Honeybadger)
- [ ] Uptime monitoring
- [ ] Performance monitoring

**Low Priority:**
- [ ] Backup strategy for posts
- [ ] Blue/green deployments
- [ ] Staging environment

### Code Quality

**Medium Priority:**
- [ ] Add Credo for code quality checks
- [ ] Security audit with Sobelow
- [ ] Dependency version updates
- [ ] Remove unused modules/functions

**Low Priority:**
- [ ] Increase test coverage to 60%
- [ ] Document all public functions
- [ ] Refactor complex functions

---

## Recently Completed (Oct 2025)

### Blog Enhancements (Oct 25)
- ✅ Reading progress bar with scroll tracking
- ✅ Blog post series/collections with navigation
- ✅ Enhanced OpenGraph metadata for social sharing
- ✅ Image optimization documentation
- ✅ Series navigation CSS styling
- ✅ Test coverage for series functionality

### Pattern Generator Refactor (Oct 24)
- ✅ Modular architecture (PatternConfig, RandomGenerator, SVGBuilder)
- ✅ 8 pattern styles with animations
- ✅ Simplified color palettes (monochrome focus)
- ✅ Pattern gallery page

### Content Pages (Oct 19-23)
- ✅ Now page showing current activities
- ✅ Sitemap with ASCII tree navigation
- ✅ RSS feed and SEO sitemap
- ✅ Contact form with rate limiting
- ✅ Projects page with GitHub integration

---

## Ideas & Future Exploration

These are low-priority ideas to consider if there's time/interest:

### Content Features
- Email newsletter subscription
- Comments via Giscus (GitHub Discussions)
- Webmentions integration
- Post scheduling/drafts
- Markdown shortcuts/helpers

### Technical Experiments
- LiveView Native mobile app
- Real-time collaborative editing
- WebAssembly integration for games
- P2P features (Portal file sharing)
- Terminal interface enhancements

### Analytics & Insights
- Privacy-friendly analytics (Plausible/Fathom)
- Reading statistics (time, completion rate)
- Popular posts dashboard
- Search query analytics

---

## Archived Features

These features are built but not currently active on the site:

### Terminal Interface
- Raxol terminal framework (110x45 grid)
- Vim-style navigation (hjkl, /, :)
- 10 plugins (Snake, Tetris, Calculator, etc.)
- 40+ terminal commands
- Plugin system architecture

**Status:** Code retained in `lib/droodotfoo/raxol/` and `lib/droodotfoo/terminal/`
**To reactivate:** Update router to use `DroodotfooLive` at `/`

### Web3 Integration
- MetaMask wallet connection
- ENS resolution
- NFT/token viewing
- IPFS integration
- Smart contract interaction

**Status:** Code retained in `lib/droodotfoo/web3/`
**Note:** Experimental, not actively maintained

### Fileverse P2P
- Portal file sharing (WebRTC)
- dDocs with E2E encryption
- dSheets data visualization
- Real-time collaboration

**Status:** Code retained in `lib/droodotfoo/fileverse/`
**Note:** Requires Fileverse SDK integration to complete

---

## Documentation

**Core Docs:**
- `README.md` - Project overview and quick start
- `CLAUDE.md` - AI assistant context and patterns
- `ARCHITECTURE.md` - System design and architecture
- `DEVELOPMENT.md` - Development setup and testing
- `deployment.md` - Fly.io deployment guide

**Reference:**
- `IMAGE_OPTIMIZATION.md` - Asset optimization strategies
- `MONASPACE_FONTS_GUIDE.md` - Typography setup

**Generated:**
- `doc/index.html` - ExDoc API documentation (run `mix docs`)

---

## Contact & Resources

**Live Site:** [droo.foo](https://droo.foo)
**Repository:** GitHub (private)
**Deployment:** Fly.io
**CDN:** Cloudflare Pages

**Questions?** See `DEVELOPMENT.md` for development setup or `ARCHITECTURE.md` for system design.
