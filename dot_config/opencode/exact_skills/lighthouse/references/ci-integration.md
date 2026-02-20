# Lighthouse CI Integration

Guide to integrating Lighthouse into CI/CD pipelines, setting up performance budgets, and automating audits.

## Lighthouse CI (@lhci/cli)

Lighthouse CI is the official tool for automating Lighthouse in CI pipelines. It handles multiple runs, assertions, report storage, and GitHub integration.

### Installation

```bash
npm install -g @lhci/cli

# Verify
lhci --version
```

### Basic Workflow

```bash
# 1. Collect: Run Lighthouse multiple times
lhci collect --url=https://example.com --numberOfRuns=3

# 2. Assert: Check results against thresholds
lhci assert --preset=lighthouse:recommended

# 3. Upload: Store results (optional)
lhci upload --target=temporary-public-storage
```

### Configuration File

Create `lighthouserc.js` (or `.lighthouserc.json`, `.lighthouserc.yml`) in project root:

```js
module.exports = {
  ci: {
    collect: {
      url: [
        'http://localhost:3000/',
        'http://localhost:3000/about',
        'http://localhost:3000/contact',
      ],
      numberOfRuns: 3,
      settings: {
        preset: 'desktop',
        chromeFlags: '--no-sandbox --headless',
      },
    },
    assert: {
      assertions: {
        'categories:performance': ['error', { minScore: 0.9 }],
        'categories:accessibility': ['warn', { minScore: 0.9 }],
        'categories:best-practices': ['warn', { minScore: 0.9 }],
        'categories:seo': ['warn', { minScore: 0.9 }],
        'first-contentful-paint': ['error', { maxNumericValue: 2000 }],
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],
        'total-blocking-time': ['error', { maxNumericValue: 300 }],
      },
    },
    upload: {
      target: 'temporary-public-storage',
    },
  },
};
```

### Assertion Levels

```js
assertions: {
  // 'error' = fail the CI build
  'categories:performance': ['error', { minScore: 0.9 }],

  // 'warn' = log warning but don't fail
  'categories:accessibility': ['warn', { minScore: 0.85 }],

  // 'off' = skip this assertion
  'categories:seo': 'off',
}
```

### Assertion Types

```js
assertions: {
  // Score-based (0-1 scale)
  'categories:performance': ['error', { minScore: 0.9 }],

  // Numeric value (milliseconds, bytes, etc.)
  'first-contentful-paint': ['error', { maxNumericValue: 2000 }],
  'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
  'total-blocking-time': ['error', { maxNumericValue: 200 }],
  'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],

  // Binary audits (pass/fail)
  'is-on-https': ['error', { minScore: 1 }],
  'viewport': ['error', { minScore: 1 }],

  // Resource size budgets
  'resource-summary:script:size': ['error', { maxNumericValue: 300000 }],
  'resource-summary:total:size': ['error', { maxNumericValue: 500000 }],
}
```

### Presets

```js
assert: {
  // Use a built-in preset
  preset: 'lighthouse:recommended',  // Strict: all audits must pass

  // Or combine preset with overrides
  preset: 'lighthouse:no-pwa',       // Recommended without PWA checks
  assertions: {
    'categories:performance': ['error', { minScore: 0.8 }],  // Override
  },
}
```

### Collecting Against a Local Server

```js
collect: {
  // Start server before collecting
  startServerCommand: 'npm run start',
  startServerReadyPattern: 'Server is running on port',
  startServerReadyTimeout: 30000,

  url: ['http://localhost:3000/'],
  numberOfRuns: 5,
}
```

### Upload Targets

```js
upload: {
  // Temporary public storage (free, links expire after 7 days)
  target: 'temporary-public-storage',

  // Lighthouse CI Server (self-hosted)
  target: 'lhci',
  serverBaseUrl: 'https://your-lhci-server.example.com',
  token: process.env.LHCI_TOKEN,

  // Filesystem (save reports locally)
  target: 'filesystem',
  outputDir: './lighthouse-reports',
}
```

## Performance Budgets

### Lighthouse Budget File

Create `budget.json` and pass it to Lighthouse:

```json
[
  {
    "path": "/*",
    "timings": [
      { "metric": "first-contentful-paint", "budget": 2000 },
      { "metric": "largest-contentful-paint", "budget": 2500 },
      { "metric": "total-blocking-time", "budget": 200 },
      { "metric": "cumulative-layout-shift", "budget": 0.1 },
      { "metric": "speed-index", "budget": 3400 },
      { "metric": "interactive", "budget": 3800 }
    ],
    "resourceSizes": [
      { "resourceType": "script", "budget": 300 },
      { "resourceType": "stylesheet", "budget": 100 },
      { "resourceType": "image", "budget": 500 },
      { "resourceType": "total", "budget": 1000 }
    ],
    "resourceCounts": [
      { "resourceType": "script", "budget": 15 },
      { "resourceType": "third-party", "budget": 10 },
      { "resourceType": "total", "budget": 50 }
    ]
  }
]
```

**Usage**:
```bash
lighthouse https://example.com --budget-path=./budget.json --output json
```

### Resource Types for Budgets

```
script          # JavaScript files
stylesheet      # CSS files
image           # Images (all formats)
media           # Audio/video
font            # Web fonts
document        # HTML documents
other           # Unclassified resources
third-party     # Resources from other origins
total           # Sum of all resources
```

## GitHub Actions

### Basic Lighthouse CI Action

```yaml
name: Lighthouse CI
on: [push, pull_request]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 22

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v12
        with:
          urls: |
            https://example.com/
            https://example.com/about
          budgetPath: ./budget.json
          uploadArtifacts: true
          temporaryPublicStorage: true
```

### Lighthouse CI with Local Server

```yaml
name: Lighthouse CI
on: [push, pull_request]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 22

      - name: Install and Build
        run: |
          npm ci
          npm run build

      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v12
        with:
          configPath: ./lighthouserc.js
          uploadArtifacts: true
          temporaryPublicStorage: true
```

### Manual Lighthouse in GitHub Actions

```yaml
name: Lighthouse Audit
on:
  pull_request:
    branches: [main]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 22

      - name: Install Lighthouse
        run: npm install -g lighthouse

      - name: Run Lighthouse
        run: |
          lighthouse https://example.com \
            --output json \
            --output html \
            --output-path=./lighthouse-report \
            --chrome-flags="--headless --no-sandbox --disable-gpu" \
            --quiet

      - name: Check Performance Score
        run: |
          SCORE=$(jq '.categories.performance.score * 100' lighthouse-report.report.json)
          echo "Performance score: $SCORE"
          if (( $(echo "$SCORE < 80" | bc -l) )); then
            echo "::error::Performance score $SCORE is below threshold of 80"
            exit 1
          fi

      - name: Upload Report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: lighthouse-report
          path: lighthouse-report.*
```

### Comment PR with Results

```yaml
      - name: Format Results
        if: github.event_name == 'pull_request'
        id: results
        run: |
          PERF=$(jq '.categories.performance.score * 100' lighthouse-report.report.json)
          A11Y=$(jq '.categories.accessibility.score * 100' lighthouse-report.report.json)
          BP=$(jq '.categories["best-practices"].score * 100' lighthouse-report.report.json)
          SEO=$(jq '.categories.seo.score * 100' lighthouse-report.report.json)
          LCP=$(jq '.audits["largest-contentful-paint"].displayValue' lighthouse-report.report.json)
          CLS=$(jq '.audits["cumulative-layout-shift"].displayValue' lighthouse-report.report.json)
          TBT=$(jq '.audits["total-blocking-time"].displayValue' lighthouse-report.report.json)

          echo "comment<<EOF" >> $GITHUB_OUTPUT
          echo "## Lighthouse Results" >> $GITHUB_OUTPUT
          echo "" >> $GITHUB_OUTPUT
          echo "| Category | Score |" >> $GITHUB_OUTPUT
          echo "|----------|-------|" >> $GITHUB_OUTPUT
          echo "| Performance | $PERF |" >> $GITHUB_OUTPUT
          echo "| Accessibility | $A11Y |" >> $GITHUB_OUTPUT
          echo "| Best Practices | $BP |" >> $GITHUB_OUTPUT
          echo "| SEO | $SEO |" >> $GITHUB_OUTPUT
          echo "" >> $GITHUB_OUTPUT
          echo "| Metric | Value |" >> $GITHUB_OUTPUT
          echo "|--------|-------|" >> $GITHUB_OUTPUT
          echo "| LCP | $LCP |" >> $GITHUB_OUTPUT
          echo "| CLS | $CLS |" >> $GITHUB_OUTPUT
          echo "| TBT | $TBT |" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT

      - name: Comment on PR
        if: github.event_name == 'pull_request'
        uses: marocchino/sticky-pull-request-comment@v2
        with:
          message: ${{ steps.results.outputs.comment }}
```

## Node.js Programmatic Usage

### Basic Usage

```js
import lighthouse from 'lighthouse';
import * as chromeLauncher from 'chrome-launcher';

const chrome = await chromeLauncher.launch({ chromeFlags: ['--headless'] });

const options = {
  logLevel: 'info',
  output: 'json',
  onlyCategories: ['performance'],
  port: chrome.port,
};

const result = await lighthouse('https://example.com', options);

// Access results
const report = JSON.parse(result.report);
console.log('Performance score:', report.categories.performance.score * 100);
console.log('LCP:', report.audits['largest-contentful-paint'].numericValue);

await chrome.kill();
```

### With Custom Configuration

```js
import lighthouse from 'lighthouse';
import * as chromeLauncher from 'chrome-launcher';

const chrome = await chromeLauncher.launch({ chromeFlags: ['--headless'] });

const config = {
  extends: 'lighthouse:default',
  settings: {
    formFactor: 'desktop',
    screenEmulation: {
      mobile: false,
      width: 1350,
      height: 940,
      deviceScaleFactor: 1,
    },
    throttling: {
      rttMs: 40,
      throughputKbps: 10240,
      cpuSlowdownMultiplier: 1,
    },
  },
};

const result = await lighthouse('https://example.com', { port: chrome.port }, config);
const report = JSON.parse(result.report);

// Process results
const metrics = {
  performance: report.categories.performance.score * 100,
  fcp: report.audits['first-contentful-paint'].numericValue,
  lcp: report.audits['largest-contentful-paint'].numericValue,
  tbt: report.audits['total-blocking-time'].numericValue,
  cls: report.audits['cumulative-layout-shift'].numericValue,
  si: report.audits['speed-index'].numericValue,
};

console.table(metrics);
await chrome.kill();
```

### Batch Auditing Multiple URLs

```js
import lighthouse from 'lighthouse';
import * as chromeLauncher from 'chrome-launcher';

const urls = [
  'https://example.com/',
  'https://example.com/about',
  'https://example.com/products',
];

const chrome = await chromeLauncher.launch({ chromeFlags: ['--headless'] });
const results = [];

for (const url of urls) {
  const result = await lighthouse(url, {
    port: chrome.port,
    output: 'json',
    onlyCategories: ['performance'],
  });

  const report = JSON.parse(result.report);
  results.push({
    url,
    score: report.categories.performance.score * 100,
    lcp: Math.round(report.audits['largest-contentful-paint'].numericValue),
    tbt: Math.round(report.audits['total-blocking-time'].numericValue),
    cls: report.audits['cumulative-layout-shift'].numericValue.toFixed(3),
  });
}

console.table(results);
await chrome.kill();
```

## Comparing Results Over Time

### Script to Compare Two JSON Reports

```bash
#!/bin/bash
# compare-reports.sh <before.json> <after.json>

BEFORE=$1
AFTER=$2

echo "=== Performance Score ==="
echo "Before: $(jq '.categories.performance.score * 100' $BEFORE)"
echo "After:  $(jq '.categories.performance.score * 100' $AFTER)"

echo ""
echo "=== Core Web Vitals ==="
for metric in first-contentful-paint largest-contentful-paint total-blocking-time cumulative-layout-shift speed-index; do
  BEFORE_VAL=$(jq ".audits[\"$metric\"].numericValue" $BEFORE)
  AFTER_VAL=$(jq ".audits[\"$metric\"].numericValue" $AFTER)
  DIFF=$(echo "$AFTER_VAL - $BEFORE_VAL" | bc 2>/dev/null || echo "N/A")
  echo "$metric:"
  echo "  Before: $BEFORE_VAL"
  echo "  After:  $AFTER_VAL"
  echo "  Delta:  $DIFF"
done
```

### Median Score from Multiple Runs

```bash
#!/bin/bash
# median-score.sh <url> <num_runs>

URL=$1
RUNS=${2:-5}
SCORES=()

for i in $(seq 1 $RUNS); do
  SCORE=$(lighthouse "$URL" \
    --only-categories=performance \
    --output json --quiet \
    --chrome-flags="--headless --no-sandbox" | \
    jq '.categories.performance.score * 100')
  SCORES+=($SCORE)
  echo "Run $i: $SCORE"
done

# Sort and get median
SORTED=($(printf '%s\n' "${SCORES[@]}" | sort -n))
MEDIAN=${SORTED[$((RUNS / 2))]}
echo "Median score: $MEDIAN"
```

## Docker Setup

### Dockerfile for Lighthouse

```dockerfile
FROM node:22-slim

# Install Chrome dependencies
RUN apt-get update && apt-get install -y \
    chromium \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Set Chrome path
ENV CHROME_PATH=/usr/bin/chromium

# Install Lighthouse
RUN npm install -g lighthouse @lhci/cli

WORKDIR /app

# Run as non-root
RUN useradd -m lighthouse
USER lighthouse

ENTRYPOINT ["lighthouse"]
```

**Usage**:
```bash
docker build -t lighthouse .
docker run --rm lighthouse https://example.com \
  --output json \
  --chrome-flags="--headless --no-sandbox --disable-gpu" \
  --quiet
```

## Bitbucket Pipelines

```yaml
pipelines:
  pull-requests:
    '**':
      - step:
          name: Lighthouse Audit
          image: node:22
          script:
            - apt-get update && apt-get install -y chromium --no-install-recommends
            - export CHROME_PATH=$(which chromium)
            - npm install -g lighthouse
            - lighthouse https://example.com
                --only-categories=performance
                --output json
                --output-path=./lighthouse-report.json
                --chrome-flags="--headless --no-sandbox --disable-gpu"
                --quiet
            - |
              SCORE=$(node -e "
                const r = require('./lighthouse-report.json');
                console.log(Math.round(r.categories.performance.score * 100));
              ")
              echo "Performance score: $SCORE"
              if [ "$SCORE" -lt 80 ]; then
                echo "Performance score $SCORE is below threshold of 80"
                exit 1
              fi
          artifacts:
            - lighthouse-report.json
```

## Best Practices for CI

### Reducing Variance
- Run **3-5 times** and use median score
- Use `--chrome-flags="--headless --no-sandbox"` consistently
- Pin Chrome/Chromium version in Docker images
- Avoid running other CPU-intensive tasks in parallel
- Use `--throttling-method=simulate` (default) for most consistent results

### Threshold Strategy
- Start with **lenient thresholds** (e.g., performance >= 70)
- Gradually tighten as you improve
- Use **`warn`** for aspirational targets, **`error`** for hard requirements
- Set metric-specific budgets (LCP < 2.5s) alongside category scores

### Report Storage
- Upload HTML reports as CI artifacts for debugging
- Use `temporary-public-storage` for quick PR review links
- Self-host LHCI server for long-term historical tracking

### Performance Monitoring
- Run on every PR to catch regressions early
- Run nightly on production URLs for trend monitoring
- Alert on score drops > 5 points between runs

## See Also

- [CLI Options](cli-options.md) - Complete CLI reference
- [Web Vitals](web-vitals.md) - Metrics and thresholds
