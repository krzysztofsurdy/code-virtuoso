# Frontend Performance Checklist

A checklist for frontend performance work, organized by area of impact, with specific actions and measurement guidance.

## Contents

- [Core Web Vitals targets](#core-web-vitals-targets)
- [Loading performance](#loading-performance)
- [Image optimization](#image-optimization)
- [Rendering performance](#rendering-performance)
- [Network optimization](#network-optimization)
- [Measurement and monitoring](#measurement-and-monitoring)
- [Quick wins checklist](#quick-wins-checklist)
- [Anti-patterns](#anti-patterns)

---

## Core Web Vitals targets

| Metric | What it measures | Good | Needs improvement | Poor |
|---|---|---|---|---|
| **LCP** (Largest Contentful Paint) | Loading performance | < 2.5s | 2.5s - 4.0s | > 4.0s |
| **INP** (Interaction to Next Paint) | Responsiveness | < 200ms | 200ms - 500ms | > 500ms |
| **CLS** (Cumulative Layout Shift) | Visual stability | < 0.1 | 0.1 - 0.25 | > 0.25 |

---

## Loading performance

### Critical rendering path

| # | Check | Impact |
|---|---|---|
| 1 | CSS is loaded in `<head>` with no render-blocking JavaScript before it | High |
| 2 | Critical CSS is inlined for above-the-fold content | High |
| 3 | Non-critical CSS is loaded asynchronously or deferred | Medium |
| 4 | JavaScript is loaded with `defer` or `async` attribute | High |
| 5 | Third-party scripts load after first-party content | Medium |
| 6 | Web fonts use `font-display: swap` or `optional` | Medium |
| 7 | Preload hints are used for critical resources (`<link rel="preload">`) | Medium |
| 8 | DNS prefetch is used for known third-party domains (`<link rel="dns-prefetch">`) | Low |

### Code splitting

| # | Check | Impact |
|---|---|---|
| 1 | Route-based code splitting is implemented (each page loads only its own code) | High |
| 2 | Large libraries are loaded on demand (chart libraries, rich text editors) | High |
| 3 | Modal/dialog content is lazy-loaded when the modal opens | Medium |
| 4 | Below-the-fold components are lazy-loaded | Medium |
| 5 | Vendor bundle is separated from application code for better caching | Medium |

### Bundle size

| # | Check | Impact |
|---|---|---|
| 1 | Bundle analyzer has been run to identify large dependencies | High |
| 2 | Unused code is removed (tree shaking is enabled) | High |
| 3 | No duplicate dependencies in the bundle (different versions of the same library) | Medium |
| 4 | Moment.js or similar heavy libraries are replaced with lighter alternatives (date-fns, dayjs) | Medium |
| 5 | Source maps are not shipped to production | Low |
| 6 | Total JavaScript budget is defined and monitored (target: < 200KB gzipped for initial load) | High |

---

## Image optimization

| # | Check | Impact |
|---|---|---|
| 1 | Images use modern formats (WebP with JPEG/PNG fallback, or AVIF) | High |
| 2 | Images are served at the correct dimensions (no 2000px image displayed at 200px) | High |
| 3 | Responsive images use `srcset` and `sizes` attributes | High |
| 4 | Images below the fold use `loading="lazy"` | High |
| 5 | The LCP image does NOT use `loading="lazy"` (it must load immediately) | High |
| 6 | Hero/LCP images are preloaded with `<link rel="preload" as="image">` | Medium |
| 7 | Image dimensions are specified in HTML (width/height attributes) to prevent layout shift | High |
| 8 | SVG icons are inlined or loaded as a sprite, not as individual image requests | Medium |
| 9 | Background images in CSS are compressed | Medium |

### Image format guide

| Format | Best for | Browser support |
|---|---|---|
| WebP | Photos and complex images | All modern browsers |
| AVIF | Photos (better compression than WebP) | Chrome, Firefox, Safari 16+ |
| SVG | Icons, logos, illustrations | Universal |
| PNG | Screenshots, images requiring transparency with sharp edges | Universal |
| JPEG | Photos when WebP/AVIF not possible | Universal |

---

## Rendering performance

### Layout shift prevention

| # | Check | Impact |
|---|---|---|
| 1 | Images and videos have explicit width/height or aspect-ratio CSS | High |
| 2 | Web fonts have `font-display: swap` and a size-adjusted fallback | Medium |
| 3 | Dynamic content (ads, embeds) has reserved space | High |
| 4 | No content is injected above existing content after initial render | High |
| 5 | Skeleton screens match the dimensions of actual content | Medium |

### Rendering efficiency

| # | Check | Impact |
|---|---|---|
| 1 | Expensive computations are memoized and only re-run when inputs change | Medium |
| 2 | List rendering uses virtualization for lists with 100+ items | High |
| 3 | Scroll and resize event handlers are debounced or throttled | Medium |
| 4 | CSS animations use `transform` and `opacity` (GPU-accelerated properties) | Medium |
| 5 | `will-change` is used sparingly and only for known animation targets | Low |
| 6 | DOM size is kept small (target: < 1500 elements on the page) | Medium |

---

## Network optimization

### Caching strategy

| Resource type | Cache strategy | Cache duration |
|---|---|---|
| HTML pages | `no-cache` or short TTL | Revalidate on each request |
| CSS/JS bundles (hashed filenames) | `immutable`, long TTL | 1 year |
| Images (hashed filenames) | `immutable`, long TTL | 1 year |
| API responses | `Cache-Control` based on data freshness needs | Varies (60s to 3600s) |
| Fonts | Long TTL with `immutable` | 1 year |

### Data fetching

| # | Check | Impact |
|---|---|---|
| 1 | API requests are batched where possible (one request for a list, not N requests for N items) | High |
| 2 | Stale-while-revalidate pattern is used for data that tolerates brief staleness | Medium |
| 3 | Optimistic updates are used for mutations where immediate feedback matters | Medium |
| 4 | Failed requests have retry logic with exponential backoff | Low |
| 5 | Unnecessary re-fetching is prevented (cache API responses client-side) | Medium |
| 6 | Prefetching is used for likely next actions (preload data for links the user is likely to click) | Medium |

### Compression

| # | Check | Impact |
|---|---|---|
| 1 | Server sends gzip or Brotli compressed responses for text assets | High |
| 2 | Brotli is preferred over gzip where supported (10-20% better compression) | Medium |
| 3 | Compression is verified in network tab (check Content-Encoding header) | Medium |

---

## Measurement and monitoring

### Lab tools (development)

| Tool | What it measures | When to use |
|---|---|---|
| Lighthouse | Core Web Vitals, accessibility, best practices | Every PR, CI pipeline |
| Chrome DevTools Performance tab | Rendering timeline, long tasks, layout shifts | Debugging specific issues |
| WebPageTest | Multi-location testing, filmstrip view, waterfall analysis | Before and after major changes |
| Bundle analyzer (webpack/vite plugin) | JavaScript bundle composition and size | When adding/updating dependencies |

### Field tools (production)

| Tool | What it measures | When to use |
|---|---|---|
| Chrome UX Report (CrUX) | Real-user Core Web Vitals | Monthly review of site-wide performance |
| Web Vitals JS library | Real-user metrics in your analytics | Continuous monitoring |
| Performance Observer API | Custom real-user performance data | When you need metrics not covered by standard tools |

### Performance budgets

Define budgets and enforce them in CI:

| Metric | Budget | How to enforce |
|---|---|---|
| Total JS (gzipped) | < 200KB | Bundle size check in CI |
| Total CSS (gzipped) | < 50KB | Bundle size check in CI |
| LCP | < 2.5s | Lighthouse CI threshold |
| CLS | < 0.1 | Lighthouse CI threshold |
| INP | < 200ms | Real-user monitoring alert |
| Time to Interactive | < 3.5s | Lighthouse CI threshold |

---

## Quick wins checklist

If time is short, start with the highest-impact items:

| Priority | Action | Expected impact |
|---|---|---|
| 1 | Optimize the LCP image (size, format, preload, no lazy-load) | Large LCP improvement |
| 2 | Enable code splitting per route | Large reduction in initial JS |
| 3 | Set explicit dimensions on images and embeds | Eliminates major CLS |
| 4 | Defer non-critical JavaScript | Faster initial render |
| 5 | Enable Brotli/gzip compression | 60-80% reduction in transfer size |
| 6 | Lazy-load below-fold images | Reduced initial page weight |
| 7 | Remove unused CSS and JavaScript | Smaller bundles |
| 8 | Use a CDN for static assets | Lower latency globally |

---

## Anti-patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Loading all JS upfront | Blocks rendering, wastes bandwidth | Route-based code splitting |
| Unoptimized hero image | Slow LCP, wasted bandwidth | Serve correct size, modern format, preload |
| No image dimensions | Layout shift as images load | Set width/height or aspect-ratio |
| Synchronous third-party scripts | Blocks page rendering | Load async or defer |
| Over-fetching API data | Slow responses, wasted bandwidth | Fetch only needed fields, paginate |
| Measuring only in lab conditions | Misses real-user performance issues | Monitor field metrics continuously |
| Premature optimization | Wasted effort on non-bottlenecks | Measure first, optimize the biggest issue |
