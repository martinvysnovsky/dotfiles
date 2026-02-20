---
name: snyk
description: Snyk CLI security scanning for open source dependencies, application code (SAST), container images, and infrastructure as code. Use when (1) scanning projects for vulnerabilities with snyk test, (2) running static code analysis with snyk code test, (3) scanning Docker images with snyk container test, (4) auditing Terraform/Kubernetes with snyk iac test, (5) monitoring projects with snyk monitor, (6) integrating Snyk into CI/CD pipelines, (7) fixing or ignoring vulnerabilities.
---

# Snyk CLI

## Quick Reference

This skill provides comprehensive Snyk CLI patterns for security scanning. Load reference files as needed:

**Scanning Types:**
- **[open-source-scanning.md](references/open-source-scanning.md)** - `snyk test`, `snyk monitor`, `snyk fix`, dependency vulnerability scanning, `.snyk` policy file
- **[code-scanning.md](references/code-scanning.md)** - `snyk code test`, static application security testing (SAST), supported languages, severity mapping
- **[container-iac-scanning.md](references/container-iac-scanning.md)** - `snyk container test/monitor`, `snyk iac test`, Docker image scanning, Terraform/Kubernetes auditing, base image recommendations

## Installation

```bash
# npm (recommended for Node.js projects)
npm install -g snyk

# Homebrew (macOS/Linux)
brew tap snyk/tap && brew install snyk

# Scoop (Windows)
scoop bucket add snyk https://github.com/snyk/scoop-snyk
scoop install snyk

# Standalone binary (Linux)
curl --compressed https://static.snyk.io/cli/latest/snyk-linux -o snyk
chmod +x snyk
mv snyk /usr/local/bin/

# Docker
docker run --rm -it -e "SNYK_TOKEN=<TOKEN>" -v "$(pwd):/app" snyk/snyk:node snyk test
```

## Authentication

```bash
# Interactive (opens browser for OAuth)
snyk auth

# Token-based (CI/CD environments)
snyk auth <API_TOKEN>
# or
export SNYK_TOKEN=<API_TOKEN>

# Verify authentication
snyk whoami
```

## Core Commands

| Command | Purpose | Scan Type |
|---------|---------|-----------|
| `snyk test` | Scan open source dependencies for vulnerabilities | SCA |
| `snyk code test` | Static application security testing (SAST) | SAST |
| `snyk container test <image>` | Scan container image for vulnerabilities | Container |
| `snyk iac test` | Scan infrastructure as code files | IaC |
| `snyk monitor` | Create monitored snapshot in Snyk dashboard | Monitoring |
| `snyk fix` | Auto-apply remediation for dependency vulnerabilities | Remediation |
| `snyk ignore --id=<ID>` | Ignore a specific vulnerability with reason | Policy |
| `snyk log4shell` | Check for Log4Shell (CVE-2021-44228) | Targeted |

## Global Flags

These flags work across all Snyk commands:

| Flag | Description |
|------|-------------|
| `--severity-threshold=<level>` | Report only: `low`, `medium`, `high`, `critical` |
| `--json` | Output results as JSON |
| `--sarif` | Output in SARIF format (for IDE/CI integration) |
| `--all-projects` | Auto-detect and scan all projects in working directory |
| `--org=<ORG_ID>` | Associate scan with specific Snyk organization |
| `--policy-path=<path>` | Path to `.snyk` policy file |
| `--debug` | Enable debug output for troubleshooting |
| `-q, --quiet` | Suppress output, only show results |

## Common Workflows

### Quick Project Scan

```bash
# Navigate to project directory
cd /my/project

# Scan dependencies
snyk test

# Scan source code
snyk code test

# Scan everything
snyk test && snyk code test
```

### CI/CD Gate

```bash
# Fail pipeline only on high/critical vulnerabilities
snyk test --severity-threshold=high

# Fail only if vulnerabilities have available fixes
snyk test --fail-on=upgradable

# Full scan with JSON output for processing
snyk test --json --all-projects > snyk-results.json
```

### Continuous Monitoring

```bash
# Create a monitored snapshot
snyk monitor --project-name="my-app-production"

# Monitor with custom organization
snyk monitor --org=my-org --project-name="my-app"
```

## `.snyk` Policy File

Manage vulnerability exceptions in `.snyk` at project root:

```yaml
version: v1.5.0
ignore:
  SNYK-JS-LODASH-590103:
    - '*':
        reason: 'Low risk - not using affected function'
        expires: 2025-06-01T00:00:00.000Z
        created: 2025-01-15T00:00:00.000Z
patch: {}
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No vulnerabilities found |
| 1 | Vulnerabilities found |
| 2 | Failure (invalid options, network error, etc.) |
| 3 | No supported projects detected |

## When to Load Reference Files

**Scanning open source dependencies?**
- Detailed `snyk test` options, `snyk monitor`, `snyk fix`, manifest-specific flags, `.snyk` policy management -> [open-source-scanning.md](references/open-source-scanning.md)

**Running static code analysis (SAST)?**
- `snyk code test` options, supported languages, severity levels, SARIF output, IDE integration -> [code-scanning.md](references/code-scanning.md)

**Scanning Docker images or Terraform/Kubernetes configs?**
- `snyk container test/monitor`, `snyk iac test`, base image recommendations, Dockerfile scanning, IaC rules -> [container-iac-scanning.md](references/container-iac-scanning.md)
