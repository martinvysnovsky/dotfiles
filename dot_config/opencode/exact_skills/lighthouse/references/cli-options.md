# Lighthouse CLI Options Reference

Complete reference for all Lighthouse CLI flags and configuration options.

## Basic Usage

```bash
lighthouse <url> [options]
```

Lighthouse requires a URL as the first argument. It launches Chrome, navigates to the URL, runs audits, and generates a report.

## Logging

```bash
--verbose                  # Display verbose logging (debug info)
--quiet                    # Suppress all progress, debug logs, and errors
```

## Configuration Flags

### Presets

```bash
--preset=perf              # Performance-focused (lighter, faster)
--preset=desktop           # Desktop emulation (no mobile throttling, desktop viewport)
--preset=experimental      # Include experimental audits
```

**Note**: `--preset` is ignored if `--config-path` is also provided.

### Category Selection

```bash
# Run specific categories only
--only-categories=performance
--only-categories=performance,seo
--only-categories=accessibility,best-practices

# Available categories:
#   performance
#   accessibility
#   best-practices
#   seo
```

### Audit Selection

```bash
# Run only specific audits
--only-audits=first-contentful-paint,largest-contentful-paint

# Skip specific audits
--skip-audits=screenshot-thumbnails,full-page-screenshot

# List all available audits
--list-all-audits
```

### Custom Configuration

```bash
# Use a custom config file
--config-path=./my-config.js

# Load CLI flags from JSON file (command-line flags still override)
--cli-flags-path=./flags.json
```

**Example `flags.json`**:
```json
{
  "output": ["json", "html"],
  "onlyCategories": ["performance"],
  "chromeFlags": "--headless --no-sandbox",
  "quiet": true
}
```

## Chrome Flags

```bash
# Pass flags to Chrome (space-delimited)
--chrome-flags="--headless --no-sandbox"
--chrome-flags="--headless --no-sandbox --disable-gpu"
--chrome-flags="--window-size=412,660"

# Common Chrome flags:
#   --headless             Run without GUI (for CI/servers)
#   --no-sandbox           Required in Docker/CI environments
#   --disable-gpu          Disable GPU acceleration
#   --window-size=W,H      Set viewport dimensions
#   --incognito            Run in incognito mode
#   --disable-extensions   Disable all extensions

# Ignore Lighthouse's default Chrome flags
--chrome-ignore-default-flags

# Use specific Chrome binary (environment variable)
CHROME_PATH=/usr/bin/chromium lighthouse https://example.com
```

## Debugging Protocol

```bash
# Connect to an already-running Chrome instance
--port=9222                # Debugging protocol port (0 = random)
--hostname=localhost        # Debugging protocol hostname
```

## Device Emulation

### Form Factor

```bash
# Set form factor (affects scoring and mobile-only audits)
--form-factor=mobile       # Default
--form-factor=desktop      # Skip mobile-only audits
```

**Note**: For desktop testing, prefer `--preset=desktop` which also adjusts throttling and viewport.

### Screen Emulation

```bash
# Disable screen emulation entirely
--screenEmulation.disabled

# Custom screen emulation (all four required if not disabled)
--screenEmulation.mobile=true
--screenEmulation.width=360
--screenEmulation.height=640
--screenEmulation.deviceScaleFactor=2

# Desktop example
--screenEmulation.mobile=false
--screenEmulation.width=1350
--screenEmulation.height=940
--screenEmulation.deviceScaleFactor=1
```

### User Agent

```bash
# Set custom user agent
--emulatedUserAgent="Mozilla/5.0 (Linux; Android 11; Pixel 5) ..."

# Disable user agent emulation
--no-emulatedUserAgent
```

## Throttling

Lighthouse throttles network and CPU to simulate typical mobile conditions.

### Throttling Method

```bash
--throttling-method=simulate    # Default: fast simulation (no real throttling)
--throttling-method=devtools    # Real throttling via DevTools protocol
--throttling-method=provided    # No throttling (use real device conditions)
```

**Differences**:
| Method | Speed | Accuracy | Use Case |
|--------|-------|----------|----------|
| `simulate` | Fast | Estimated | CI/CD, quick checks |
| `devtools` | Slow | Real throttling | Accurate mobile simulation |
| `provided` | Fastest | Real conditions | Testing actual device performance |

### Network Throttling Parameters

```bash
# Simulated throttling (used with simulate method)
--throttling.rttMs=150                    # Round-trip time (TCP layer)
--throttling.throughputKbps=1638.4        # Download throughput

# Emulated throttling (used with devtools method)
--throttling.requestLatencyMs=150         # HTTP layer latency
--throttling.downloadThroughputKbps=1638.4
--throttling.uploadThroughputKbps=675

# CPU throttling (both methods)
--throttling.cpuSlowdownMultiplier=4      # 4x CPU slowdown (default mobile)
```

### Default Throttling Profiles

**Mobile (default)**:
- RTT: 150ms
- Download: 1.6 Mbps
- Upload: 750 Kbps
- CPU: 4x slowdown

**Desktop (with `--preset=desktop`)**:
- No network throttling
- No CPU slowdown

### Disable All Throttling

```bash
lighthouse https://example.com \
  --throttling-method=provided \
  --screenEmulation.disabled \
  --no-emulatedUserAgent
```

## Output Options

### Output Format

```bash
--output=html              # Default: HTML report
--output=json              # JSON report (stdout by default)
--output=csv               # CSV format

# Multiple formats
--output json --output html
```

### Output Path

```bash
# Save to specific file
--output-path=./report.html
--output-path=./reports/my-audit.json

# Output to stdout
--output-path=stdout

# Multiple formats with base path
--output json --output html --output-path=./reports/audit
# Creates: ./reports/audit.report.json and ./reports/audit.report.html
```

**Default naming**: `./<HOST>_<DATE>.report.<ext>`

### View Report

```bash
--view                     # Open HTML report in browser after run
```

### Screenshots

```bash
--disable-full-page-screenshot    # Skip full-page screenshot (reduces report size)
```

## Authentication and Headers

```bash
# Inline JSON headers
--extra-headers '{"Cookie":"session=abc123; token=xyz"}'
--extra-headers '{"Authorization":"Bearer eyJhbGci..."}'

# Multiple headers
--extra-headers '{"Cookie":"session=abc123", "X-Custom":"value"}'

# Headers from JSON file (recommended for secrets)
--extra-headers=./headers.json
```

**Example `headers.json`**:
```json
{
  "Cookie": "session=abc123",
  "Authorization": "Bearer eyJhbGci...",
  "X-Custom-Header": "value"
}
```

## Network Control

```bash
# Block specific URL patterns
--blocked-url-patterns="https://ads.example.com/*"
--blocked-url-patterns="*.analytics.com" "*.tracking.net"

# Disable clearing cache/storage before run
--disable-storage-reset
```

## Gather and Audit Modes

Lighthouse's lifecycle can be split into gather (browser interaction) and audit (analysis) phases.

```bash
# Gather only: collect artifacts, save to disk, quit
lighthouse https://example.com -G
lighthouse https://example.com -G=./my-artifacts

# Audit only: load artifacts from disk, run audits
lighthouse https://example.com -A
lighthouse https://example.com -A=./my-artifacts

# Both: normal run + save artifacts for later
lighthouse https://example.com -GA

# Useful for:
# 1. Gathering once, auditing with different configs
# 2. Debugging artifact collection issues
# 3. Sharing artifacts between team members
```

**Default artifact path**: `./latest-run/`

## Trace and DevTools Logs

```bash
# Save trace and devtools logs
--save-assets
# Creates: <output-path>-0.trace.json and <output-path>-0.devtoolslog.json

# List all required trace categories
--list-trace-categories

# Add extra trace categories
--additional-trace-categories="v8,v8.execute"
```

## Lantern Data

Lantern is Lighthouse's simulation engine for network/CPU modeling.

```bash
# Use precomputed lantern data (skip estimation)
--precomputed-lantern-data-path=./lantern-data.json

# Export lantern data for future runs
--lantern-data-output-path=./lantern-data.json
```

## Localization

```bash
# Set report locale
--locale=es        # Spanish
--locale=ja        # Japanese
--locale=de        # German
--locale=fr        # French
```

Lighthouse relies on Node's native `Intl` support (Node 14+ with `full-icu`).

## Plugins

```bash
# Run with plugins
--plugins=lighthouse-plugin-field-performance
--plugins=lighthouse-plugin-publisher-ads

# Multiple plugins
--plugins lighthouse-plugin-field-performance lighthouse-plugin-crux
```

## Load Timeout

```bash
# Set page load timeout (ms)
--max-wait-for-load=45000    # Default varies; high values may cause instability
```

## Error Reporting

```bash
# Enable anonymous error reporting to Lighthouse team
--enable-error-reporting

# Disable
--no-enable-error-reporting
```

## Complete Example Commands

```bash
# Quick perf check on CI
lighthouse https://example.com \
  --only-categories=performance \
  --output json \
  --quiet \
  --chrome-flags="--headless --no-sandbox"

# Full audit with all outputs
lighthouse https://example.com \
  --output json --output html \
  --output-path=./reports/full-audit \
  --save-assets \
  --view

# Desktop audit with no throttling
lighthouse https://example.com \
  --preset=desktop \
  --throttling-method=provided \
  --output json \
  --output-path=./reports/desktop.json

# Authenticated page audit
lighthouse https://example.com/admin \
  --extra-headers=./auth-headers.json \
  --only-categories=performance,accessibility \
  --output html \
  --view

# Docker/CI-friendly audit
lighthouse https://example.com \
  --chrome-flags="--headless --no-sandbox --disable-gpu" \
  --quiet \
  --output json \
  --output-path=stdout

# Audit with custom throttling (3G simulation)
lighthouse https://example.com \
  --throttling-method=devtools \
  --throttling.requestLatencyMs=300 \
  --throttling.downloadThroughputKbps=700 \
  --throttling.uploadThroughputKbps=300 \
  --throttling.cpuSlowdownMultiplier=6 \
  --output json
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `CHROME_PATH` | Path to Chrome/Chromium binary |
| `LIGHTHOUSE_CHROMIUM_PATH` | Alternative to `CHROME_PATH` |

## See Also

- [Web Vitals Reference](web-vitals.md) - Metrics and thresholds
- [CI Integration](ci-integration.md) - Automation and budgets
