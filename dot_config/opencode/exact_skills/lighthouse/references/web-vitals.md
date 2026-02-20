# Core Web Vitals & Performance Metrics

Complete reference for all performance metrics Lighthouse measures, their thresholds, how they contribute to the performance score, and optimization strategies.

## Core Web Vitals

Google's Core Web Vitals are the subset of Web Vitals that apply to all web pages. They represent the key dimensions of user experience: **loading**, **interactivity**, and **visual stability**.

### LCP - Largest Contentful Paint

**What it measures**: Time until the largest content element (image, video, text block) is rendered in the viewport.

**Thresholds**:
| Rating | Time |
|--------|------|
| Good | <= 2.5s |
| Needs Improvement | <= 4.0s |
| Poor | > 4.0s |

**Common causes of slow LCP**:
- Slow server response times (high TTFB)
- Render-blocking CSS and JavaScript
- Slow resource load times (large images, fonts)
- Client-side rendering delays

**Optimization strategies**:
- Optimize server response time (caching, CDN, edge computing)
- Eliminate render-blocking resources (`async`/`defer` scripts, critical CSS inlining)
- Optimize and compress images (WebP/AVIF, responsive images, lazy loading below-fold)
- Preload critical resources (`<link rel="preload">`)
- Use `fetchpriority="high"` on LCP image
- Minimize critical request chains

**Lighthouse audit IDs**:
```
largest-contentful-paint
lcp-lazy-loaded
largest-contentful-paint-element
```

### INP - Interaction to Next Paint

**What it measures**: The latency of all interactions (clicks, taps, keyboard) throughout the page lifecycle, reporting the worst interaction (at the 98th percentile).

**Thresholds**:
| Rating | Time |
|--------|------|
| Good | <= 200ms |
| Needs Improvement | <= 500ms |
| Poor | > 500ms |

**Note**: INP replaced FID (First Input Delay) as a Core Web Vital in March 2024. Lighthouse measures **TBT** (Total Blocking Time) as a lab proxy for INP since lab tests don't capture real user interactions.

**Common causes of poor INP**:
- Long JavaScript tasks blocking the main thread
- Excessive DOM size
- Heavy event handlers
- Layout thrashing (forced synchronous layouts)

**Optimization strategies**:
- Break up long tasks with `setTimeout`, `requestAnimationFrame`, or `scheduler.yield()`
- Use web workers for CPU-intensive operations
- Reduce JavaScript bundle size (code splitting, tree shaking)
- Debounce/throttle expensive event handlers
- Minimize DOM size (< 1,400 elements ideal)
- Use `content-visibility: auto` for off-screen content

### CLS - Cumulative Layout Shift

**What it measures**: Total of all unexpected layout shift scores that occur during the entire page lifespan. A layout shift occurs when a visible element changes position between rendered frames.

**Thresholds**:
| Rating | Score |
|--------|-------|
| Good | <= 0.1 |
| Needs Improvement | <= 0.25 |
| Poor | > 0.25 |

**Common causes of high CLS**:
- Images without dimensions (`width`/`height` attributes)
- Ads, embeds, or iframes without reserved space
- Dynamically injected content above existing content
- Web fonts causing FOIT/FOUT (flash of invisible/unstyled text)
- Actions waiting for network response before updating DOM

**Optimization strategies**:
- Always set `width` and `height` on images and videos (or use `aspect-ratio` CSS)
- Reserve space for ads and embeds with fixed-size containers
- Use `font-display: optional` or `font-display: swap` with size-adjusted fallback fonts
- Preload web fonts
- Use CSS `contain` property for layout isolation
- Avoid inserting content above existing content dynamically
- Use CSS transforms for animations instead of properties that trigger layout

**Lighthouse audit IDs**:
```
cumulative-layout-shift
layout-shifts
layout-shift-elements
```

## Additional Lab Metrics

### FCP - First Contentful Paint

**What it measures**: Time from navigation start to when any content (text, image, SVG, canvas) is first rendered.

**Thresholds**:
| Rating | Time |
|--------|------|
| Good | <= 1.8s |
| Needs Improvement | <= 3.0s |
| Poor | > 3.0s |

**Optimization**: Same strategies as LCP (server response, render-blocking resources, critical CSS).

**Lighthouse audit ID**: `first-contentful-paint`

### TBT - Total Blocking Time

**What it measures**: Total time between FCP and Time to Interactive where the main thread was blocked long enough to prevent input responsiveness. A task is "blocking" if it runs longer than 50ms; the blocking time is the portion exceeding 50ms.

**Thresholds**:
| Rating | Time |
|--------|------|
| Good | <= 200ms |
| Needs Improvement | <= 600ms |
| Poor | > 600ms |

**Relationship to INP**: TBT is the lab metric most correlated with INP. Improving TBT generally improves real-world INP.

**Optimization**:
- Reduce JavaScript execution time
- Minimize main-thread work
- Keep request counts low and transfer sizes small
- Break up long tasks
- Remove unused JavaScript (code coverage in DevTools)
- Minimize third-party script impact

**Lighthouse audit ID**: `total-blocking-time`

### Speed Index

**What it measures**: How quickly the visible content of the page is populated. It captures the visual progression of the page load by analyzing video frames.

**Thresholds**:
| Rating | Time |
|--------|------|
| Good | <= 3.4s |
| Needs Improvement | <= 5.8s |
| Poor | > 5.8s |

**Optimization**: Minimize main-thread work, reduce JavaScript execution, optimize fonts loading, reduce render-blocking resources.

**Lighthouse audit ID**: `speed-index`

### TTFB - Time to First Byte

**What it measures**: Time from the request to when the first byte of the response is received. Not a direct Lighthouse metric in the score, but reported in audits.

**Thresholds**:
| Rating | Time |
|--------|------|
| Good | <= 800ms |
| Needs Improvement | <= 1800ms |
| Poor | > 1800ms |

**Optimization**:
- Use a CDN
- Optimize server-side rendering
- Use HTTP/2 or HTTP/3
- Enable compression (Brotli > gzip)
- Implement server-side caching
- Use `103 Early Hints`

**Lighthouse audit ID**: `server-response-time`

## Performance Score Calculation

Lighthouse calculates the overall performance score (0-100) as a **weighted average** of the individual metric scores.

### Lighthouse 12 Scoring Weights

| Metric | Weight |
|--------|--------|
| **TBT** (Total Blocking Time) | 30% |
| **LCP** (Largest Contentful Paint) | 25% |
| **CLS** (Cumulative Layout Shift) | 25% |
| **FCP** (First Contentful Paint) | 10% |
| **Speed Index** | 10% |

**Total**: 100%

### How Individual Metrics Are Scored

Each metric is scored on a 0-1 scale using a **log-normal distribution** curve derived from real-world performance data (HTTP Archive). The scoring maps raw metric values to scores:

- **0.9-1.0** (green): Fast - top ~10% of sites
- **0.5-0.89** (orange): Moderate - middle range
- **0.0-0.49** (red): Slow - bottom performers

### Score Ranges

| Score | Rating | Color |
|-------|--------|-------|
| 90-100 | Good | Green |
| 50-89 | Needs Improvement | Orange |
| 0-49 | Poor | Red |

### Score Variability

Lighthouse scores can vary between runs due to:
- Network conditions and latency
- CPU load from other processes
- Chrome's internal scheduling
- Ads and third-party scripts loading differently
- Server response time variance

**Mitigation**: Run Lighthouse 3-5 times and use the median score. In CI, use Lighthouse CI which handles multiple runs automatically.

## Audit Categories Beyond Performance

### Accessibility (score 0-100)

Checks for WCAG 2.1 compliance:
- Color contrast ratios
- ARIA attributes and roles
- Image alt text
- Form labels
- Heading hierarchy
- Keyboard navigation
- Focus management

### Best Practices (score 0-100)

Checks for modern web development standards:
- HTTPS usage
- No browser errors in console
- Correct image aspect ratios
- No deprecated APIs
- No vulnerable JavaScript libraries
- CSP and security headers

### SEO (score 0-100)

Checks for search engine optimization basics:
- Valid `<meta>` description
- Document has a `<title>`
- Valid `hreflang` attributes
- Links are crawlable
- Page is not blocked by `robots.txt`
- Mobile-friendly viewport
- Valid structured data

## Key Audit IDs for Scripting

Commonly used audit IDs when extracting data from JSON reports:

### Performance Metrics
```
first-contentful-paint
largest-contentful-paint
total-blocking-time
cumulative-layout-shift
speed-index
interactive                    # Time to Interactive (TTI)
server-response-time           # TTFB
```

### Performance Opportunities
```
render-blocking-resources      # Eliminate render-blocking resources
unused-css-rules               # Remove unused CSS
unused-javascript              # Remove unused JavaScript
modern-image-formats           # Serve images in modern formats
uses-optimized-images          # Efficiently encode images
uses-responsive-images         # Properly size images
offscreen-images               # Defer offscreen images
uses-text-compression          # Enable text compression
uses-long-cache-ttl            # Serve static assets with efficient cache policy
unminified-css                 # Minify CSS
unminified-javascript          # Minify JavaScript
efficient-animated-content     # Use video formats for animated content
```

### Performance Diagnostics
```
mainthread-work-breakdown      # Minimize main-thread work
bootup-time                    # Reduce JavaScript execution time
font-display                   # Font display strategy
dom-size                       # DOM size
critical-request-chains        # Critical request chains
third-party-summary            # Third-party usage
largest-contentful-paint-element
layout-shift-elements
long-tasks                     # Long main-thread tasks
```

### Extracting Specific Metrics

```bash
# Get all metric values in ms/score
lighthouse https://example.com --output json --quiet | jq '{
  FCP_ms: .audits["first-contentful-paint"].numericValue,
  LCP_ms: .audits["largest-contentful-paint"].numericValue,
  TBT_ms: .audits["total-blocking-time"].numericValue,
  CLS: .audits["cumulative-layout-shift"].numericValue,
  SI_ms: .audits["speed-index"].numericValue,
  TTI_ms: .audits["interactive"].numericValue,
  TTFB_ms: .audits["server-response-time"].numericValue,
  perfScore: (.categories.performance.score * 100)
}'

# Get LCP element details
lighthouse https://example.com --output json --quiet | \
  jq '.audits["largest-contentful-paint-element"].details.items'

# Get layout shift elements
lighthouse https://example.com --output json --quiet | \
  jq '.audits["layout-shift-elements"].details.items'

# Get render-blocking resources
lighthouse https://example.com --output json --quiet | \
  jq '.audits["render-blocking-resources"].details.items'
```

## See Also

- [CLI Options](cli-options.md) - Complete CLI reference
- [CI Integration](ci-integration.md) - Automation and budgets
