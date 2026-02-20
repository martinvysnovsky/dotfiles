---
name: lighthouse
description: Google Lighthouse CLI for auditing web performance, Core Web Vitals, accessibility, SEO, and best practices. Use when (1) running performance audits on URLs, (2) checking Core Web Vitals (LCP, INP, CLS), (3) generating HTML/JSON audit reports, (4) setting up performance budgets in CI/CD, (5) comparing audit results before/after changes, (6) debugging slow page loads, (7) running accessibility or SEO audits.
---

# Lighthouse CLI

Lighthouse analyzes web apps and web pages, collecting modern performance metrics and insights on developer best practices. It runs audits across four categories: **Performance**, **Accessibility**, **Best Practices**, and **SEO**.

## Quick Reference

Load reference files as needed:

**Core:**
- **[cli-options.md](references/cli-options.md)** - Complete CLI flags, presets, throttling, output formats, authentication
- **[web-vitals.md](references/web-vitals.md)** - Core Web Vitals metrics, thresholds, scoring weights, optimization tips

**Advanced:**
- **[ci-integration.md](references/ci-integration.md)** - Lighthouse CI setup, performance budgets, GitHub Actions, Node.js API

## Prerequisites

- **Node.js**: 22 (LTS) or later
- **Chrome/Chromium**: Must be installed on the machine (Lighthouse launches it automatically)
- **Environment variable**: Set `CHROME_PATH` to use a specific Chrome binary

## Installation

```bash
# Global install
npm install -g lighthouse

# Verify installation
lighthouse --version

# Or run without installing
npx lighthouse https://example.com
```

## Essential Commands

```bash
# Basic audit (generates HTML report)
lighthouse https://example.com

# JSON output to stdout
lighthouse https://example.com --output json

# Save HTML report to specific path
lighthouse https://example.com --output html --output-path ./report.html

# Multiple output formats
lighthouse https://example.com --output json --output html --output-path ./reports/audit

# Performance-only audit (faster)
lighthouse https://example.com --only-categories=performance

# Desktop preset (no mobile throttling)
lighthouse https://example.com --preset=desktop

# Headless Chrome (no GUI, for servers/CI)
lighthouse https://example.com --chrome-flags="--headless --no-sandbox"

# Quiet mode (minimal output)
lighthouse https://example.com --quiet --output json

# Open report in browser after run
lighthouse https://example.com --view

# Save trace and devtools logs
lighthouse https://example.com --save-assets
```

## Core Web Vitals Quick Summary

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| **LCP** (Largest Contentful Paint) | <= 2.5s | <= 4.0s | > 4.0s |
| **INP** (Interaction to Next Paint) | <= 200ms | <= 500ms | > 500ms |
| **CLS** (Cumulative Layout Shift) | <= 0.1 | <= 0.25 | > 0.25 |

**Lab metrics** reported by Lighthouse:
- **FCP** (First Contentful Paint) - when first content appears
- **LCP** (Largest Contentful Paint) - when main content is visible
- **TBT** (Total Blocking Time) - lab proxy for INP/interactivity
- **CLS** (Cumulative Layout Shift) - visual stability
- **Speed Index** - how quickly content is visually populated

## Common Workflows

### Run a Full Audit with JSON Output

```bash
lighthouse https://example.com --output json --output-path ./report.json --quiet
```

### Extract Scores from JSON Report

```bash
# Get all category scores
lighthouse https://example.com --output json --quiet | \
  jq '{
    performance: .categories.performance.score,
    accessibility: .categories.accessibility.score,
    bestPractices: .categories["best-practices"].score,
    seo: .categories.seo.score
  }'

# Get Core Web Vitals metrics
lighthouse https://example.com --output json --quiet | \
  jq '{
    FCP: .audits["first-contentful-paint"].numericValue,
    LCP: .audits["largest-contentful-paint"].numericValue,
    TBT: .audits["total-blocking-time"].numericValue,
    CLS: .audits["cumulative-layout-shift"].numericValue,
    SI:  .audits["speed-index"].numericValue
  }'
```

### Performance-Only Audit (Fastest)

```bash
lighthouse https://example.com \
  --only-categories=performance \
  --output json \
  --quiet \
  --chrome-flags="--headless --no-sandbox"
```

### Desktop vs Mobile Comparison

```bash
# Mobile (default)
lighthouse https://example.com --output json --output-path ./mobile.json --quiet

# Desktop
lighthouse https://example.com --preset=desktop --output json --output-path ./desktop.json --quiet

# Compare scores
echo "Mobile:" && jq '.categories.performance.score' mobile.json
echo "Desktop:" && jq '.categories.performance.score' desktop.json
```

### Audit with Authentication

```bash
# Cookie-based auth
lighthouse https://example.com/dashboard \
  --extra-headers '{"Cookie":"session=abc123"}'

# Bearer token auth
lighthouse https://example.com/api \
  --extra-headers '{"Authorization":"Bearer eyJhbGc..."}'

# Headers from file
lighthouse https://example.com --extra-headers=./headers.json
```

### Disable Throttling (Test Real Conditions)

```bash
lighthouse https://example.com \
  --screenEmulation.disabled \
  --throttling-method=provided \
  --no-emulatedUserAgent
```

### Audit Multiple URLs

```bash
# Simple bash loop
for url in https://example.com https://example.com/about https://example.com/contact; do
  lighthouse "$url" \
    --output json \
    --output-path "./reports/$(echo $url | sed 's/[^a-zA-Z0-9]/_/g').json" \
    --quiet \
    --chrome-flags="--headless --no-sandbox"
done
```

### Gather and Audit Separately

```bash
# Step 1: Gather artifacts (launches browser)
lighthouse https://example.com -G

# Step 2: Run audits on saved artifacts (no browser needed)
lighthouse https://example.com -A

# Both in one run, saving artifacts for later
lighthouse https://example.com -GA
```

## Output Parsing Patterns

### Performance Score as Exit Code

```bash
#!/bin/bash
SCORE=$(lighthouse https://example.com \
  --output json --quiet \
  --chrome-flags="--headless --no-sandbox" | \
  jq '.categories.performance.score * 100')

echo "Performance score: $SCORE"

if (( $(echo "$SCORE < 90" | bc -l) )); then
  echo "FAIL: Performance score below 90"
  exit 1
fi
```

### Extract All Failing Audits

```bash
lighthouse https://example.com --output json --quiet | \
  jq '[.audits | to_entries[] | select(.value.score != null and .value.score < 1) | {id: .key, title: .value.title, score: .value.score}]'
```

### Get Opportunity Savings

```bash
lighthouse https://example.com --output json --quiet | \
  jq '[.audits | to_entries[] | select(.value.details.overallSavingsMs != null) | {id: .key, title: .value.title, savingsMs: .value.details.overallSavingsMs}] | sort_by(-.savingsMs)'
```

## Best Practices

### Audit Reliability
- **Run multiple times**: Performance scores vary between runs due to network and CPU conditions
- **Use headless mode**: Reduces variance from browser rendering
- **Close other applications**: Reduce CPU contention for more stable results
- **Use `--quiet`**: Suppresses verbose logs for cleaner JSON output

### Throttling
- **Default mobile**: 4x CPU slowdown + simulated slow 4G (1.6 Mbps down, 150ms RTT)
- **Desktop preset**: No CPU slowdown + no network throttling
- **Simulated** (default): Fast but estimated; use `--throttling-method=devtools` for real throttling
- **Disable all**: Use `--throttling-method=provided` to test real device conditions

### Output Management
- **JSON for automation**: Parse with `jq` for CI/CD pipelines
- **HTML for humans**: Share visual reports with stakeholders
- **Save assets**: Use `--save-assets` for traces you can load in Chrome DevTools

### Security
- **Never log auth headers**: Be careful with `--extra-headers` containing tokens
- **Use file-based headers**: `--extra-headers=./headers.json` keeps secrets out of shell history

## When to Load Reference Files

**Need complete CLI flag reference?**
- All flags and options -> [cli-options.md](references/cli-options.md)
- Throttling configuration -> [cli-options.md](references/cli-options.md)
- Authentication and headers -> [cli-options.md](references/cli-options.md)
- Presets and screen emulation -> [cli-options.md](references/cli-options.md)

**Understanding Web Vitals metrics?**
- Metric definitions and thresholds -> [web-vitals.md](references/web-vitals.md)
- Performance score calculation -> [web-vitals.md](references/web-vitals.md)
- Optimization tips per metric -> [web-vitals.md](references/web-vitals.md)

**Setting up CI/CD or automation?**
- Lighthouse CI setup -> [ci-integration.md](references/ci-integration.md)
- Performance budgets -> [ci-integration.md](references/ci-integration.md)
- GitHub Actions workflow -> [ci-integration.md](references/ci-integration.md)
- Node.js programmatic usage -> [ci-integration.md](references/ci-integration.md)
