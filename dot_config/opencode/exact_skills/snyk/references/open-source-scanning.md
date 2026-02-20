# Snyk Open Source Scanning

## Contents
- snyk test command
- snyk monitor command
- snyk fix command
- Manifest-specific options
- Policy file management
- Monorepo and multi-project scanning
- CI/CD integration patterns

## snyk test

Scans project dependencies for known vulnerabilities using the package manifest (e.g., `package.json`, `pom.xml`, `requirements.txt`).

### Basic Usage

```bash
# Scan current directory
snyk test

# Scan specific manifest file
snyk test --file=package.json

# Scan with severity filter
snyk test --severity-threshold=high

# Scan all projects in directory
snyk test --all-projects
```

### Command-Specific Flags

| Flag | Description |
|------|-------------|
| `--file=<manifest>` | Specify package manifest file path |
| `--package-manager=<pm>` | Force specific package manager |
| `--all-projects` | Auto-detect and scan all projects |
| `--detection-depth=<N>` | Subdirectory search depth (default: 4) |
| `--exclude=<dirs>` | Comma-separated directories to exclude |
| `--prune-repeated-subdependencies` | Reduce dependency tree size |
| `--fail-on=<type>` | Fail only for: `all`, `upgradable`, `patchable` |
| `--severity-threshold=<level>` | Filter: `low`, `medium`, `high`, `critical` |
| `--json` | JSON output |
| `--json-file-output=<file>` | Write JSON to file while showing CLI output |
| `--sarif` | SARIF format output |
| `--sarif-file-output=<file>` | Write SARIF to file |
| `--project-name=<name>` | Custom project name |
| `--target-reference=<ref>` | Git reference for project association |
| `--dev` | Include dev dependencies |
| `--all-sub-projects` | Scan all sub-projects (Gradle, sbt) |
| `--reachable-vulns` | Analyze if vulnerable functions are actually called |
| `--strict-out-of-sync` | Fail if lockfile is out of sync (default: true) |

### Output Interpretation

```
Testing /my/project...

Tested 256 dependencies for known issues, found 3 issues, 1 with a known fix.

Issues to fix by upgrading:

  Upgrade lodash@4.17.15 to lodash@4.17.21 to fix
  ✗ Prototype Pollution [High Severity][https://snyk.io/vuln/SNYK-JS-LODASH-590103] in lodash@4.17.15
    introduced by direct dependency

  Upgrade express@4.17.1 to express@4.18.2 to fix
  ✗ Open Redirect [Medium Severity][https://snyk.io/vuln/SNYK-JS-EXPRESS-123456] in express@4.17.1
    introduced by direct dependency

Issues with no direct upgrade or patch:
  ✗ ReDoS [Low Severity][https://snyk.io/vuln/SNYK-JS-MINIMATCH-3050818] in minimatch@3.0.4
    introduced by glob@7.1.6 > minimatch@3.0.4
    No upgrade or patch available
```

**Key elements:**
- Severity levels: Critical, High, Medium, Low
- Vulnerability ID: `SNYK-<ECOSYSTEM>-<PACKAGE>-<ID>`
- Fix type: Upgrade (direct dependency change) or Patch (code-level fix)
- Introduction path: How the vulnerable package entered your dependency tree

## snyk monitor

Creates a snapshot of dependencies in the Snyk dashboard for continuous monitoring. Snyk periodically checks for new vulnerabilities and sends email alerts.

```bash
# Monitor current project
snyk monitor

# Monitor with custom name
snyk monitor --project-name="my-app-production"

# Monitor specific org
snyk monitor --org=my-team --project-name="api-service"

# Monitor all projects
snyk monitor --all-projects

# Monitor with environment tags
snyk monitor --project-environment=production --project-lifecycle=production
```

### Monitor-Specific Flags

| Flag | Description |
|------|-------------|
| `--project-name=<name>` | Custom name in Snyk dashboard |
| `--project-environment=<env>` | Tag: `frontend`, `backend`, `internal`, `external`, `production`, etc. |
| `--project-lifecycle=<stage>` | Tag: `production`, `development`, `sandbox` |
| `--project-business-criticality=<level>` | Tag: `critical`, `high`, `medium`, `low` |
| `--project-tags=<key>=<value>` | Custom tags (comma-separated) |
| `--target-reference=<ref>` | Associate with git branch/tag |

### Best Practice: Monitor Main Branch Only

```bash
# In CI/CD, only monitor on main branch
if [ "$BRANCH" = "main" ]; then
  snyk monitor --project-name="$PROJECT_NAME" --org="$SNYK_ORG"
fi
```

## snyk fix

Automatically applies remediation for vulnerable dependencies. Upgrades packages or applies patches.

```bash
# Auto-fix vulnerabilities
snyk fix

# Dry-run to preview fixes
snyk fix --dry-run

# Fix specific package ecosystem
snyk fix --file=package.json
```

**Limitations:**
- Only available for npm, Yarn, and pip projects
- Cannot fix vulnerabilities that require major version upgrades
- Some vulnerabilities have no available fix

## Manifest-Specific Options

### Node.js (npm/Yarn)

```bash
# Scan with specific lockfile
snyk test --file=package-lock.json
snyk test --file=yarn.lock

# Include dev dependencies
snyk test --dev

# Strict lockfile sync check
snyk test --strict-out-of-sync=true

# Prune repeated sub-dependencies
snyk test --prune-repeated-subdependencies
```

### Python (pip/Poetry/Pipenv)

```bash
# Scan requirements file
snyk test --file=requirements.txt

# Scan Poetry project
snyk test --file=pyproject.toml --package-manager=poetry

# Scan Pipenv project
snyk test --file=Pipfile

# Specify Python command (for virtual envs)
snyk test --command=python3
```

### Java (Maven/Gradle)

```bash
# Maven
snyk test --file=pom.xml

# Gradle (all sub-projects)
snyk test --file=build.gradle --all-sub-projects

# Gradle specific configuration
snyk test --file=build.gradle --configuration-matching='^(compile|runtime)'
```

### Go

```bash
snyk test --file=go.mod
```

### .NET

```bash
# Scan solution
snyk test --file=MySolution.sln

# Scan specific project
snyk test --file=MyProject.csproj

# Include runtime assemblies
snyk test --assets-project-name
```

### PHP (Composer)

```bash
snyk test --file=composer.lock
```

### Ruby (Bundler)

```bash
snyk test --file=Gemfile.lock
```

## .snyk Policy File

The `.snyk` file at project root manages vulnerability exceptions, patches, and settings.

### Structure

```yaml
version: v1.5.0

# Ignore specific vulnerabilities
ignore:
  SNYK-JS-LODASH-590103:
    - '*':
        reason: 'Not using the vulnerable function _.template()'
        expires: 2025-06-01T00:00:00.000Z
        created: 2025-01-15T00:00:00.000Z
  
  SNYK-JS-MINIMATCH-3050818:
    - 'glob > minimatch':
        reason: 'Only used in build scripts, not in production'
        expires: 2025-12-31T00:00:00.000Z
        created: 2025-01-15T00:00:00.000Z

# Language settings
language-settings:
  python: '3.11'

# Patches (auto-managed by snyk protect)
patch: {}
```

### Managing Ignores via CLI

```bash
# Ignore a specific vulnerability
snyk ignore --id=SNYK-JS-LODASH-590103 \
  --reason="Not using affected function" \
  --expiry=2025-06-01

# Ignore for specific path
snyk ignore --id=SNYK-JS-LODASH-590103 \
  --path="lodash" \
  --reason="Accepted risk"
```

**Best practices for ignores:**
- Always set an expiry date (re-evaluate periodically)
- Always provide a reason for the ignore
- Review `.snyk` file in code reviews
- Commit `.snyk` to version control

## Monorepo and Multi-Project Scanning

### Auto-Detection

```bash
# Scan all projects in workspace
snyk test --all-projects

# Limit scan depth
snyk test --all-projects --detection-depth=3

# Exclude specific directories
snyk test --all-projects --exclude=node_modules,dist,build,.git

# Scan with specific organization
snyk test --all-projects --org=my-org
```

### Yarn/npm Workspaces

```bash
# Scan all workspace packages
snyk test --all-projects --detection-depth=4

# Monitor all workspace packages
snyk monitor --all-projects --project-name-prefix="my-monorepo/"
```

## CI/CD Integration Patterns

### Bitbucket Pipelines

```yaml
pipelines:
  default:
    - step:
        name: Security Scan
        caches:
          - node
        script:
          - npm ci
          - npm install -g snyk
          - snyk auth $SNYK_TOKEN
          - snyk test --severity-threshold=high
          - snyk code test

  branches:
    main:
      - step:
          name: Security Scan & Monitor
          caches:
            - node
          script:
            - npm ci
            - npm install -g snyk
            - snyk auth $SNYK_TOKEN
            - snyk test --severity-threshold=high
            - snyk monitor --project-name="$BITBUCKET_REPO_SLUG"
```

### GitHub Actions

```yaml
- name: Run Snyk Security Scan
  uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  with:
    args: --severity-threshold=high
```

### Generic CI Script

```bash
#!/bin/bash
set -e

# Install Snyk
npm install -g snyk

# Authenticate
snyk auth "$SNYK_TOKEN"

# Test dependencies (fail on high/critical)
echo "Scanning dependencies..."
snyk test --severity-threshold=high --json-file-output=snyk-deps.json || DEPS_FAILED=1

# Test source code (SAST)
echo "Running static analysis..."
snyk code test --json-file-output=snyk-code.json || CODE_FAILED=1

# Monitor on main branch
if [ "$CI_BRANCH" = "main" ]; then
  snyk monitor --project-name="$PROJECT_NAME"
fi

# Report results
if [ "$DEPS_FAILED" = "1" ] || [ "$CODE_FAILED" = "1" ]; then
  echo "Security vulnerabilities found. Check snyk-deps.json and snyk-code.json"
  exit 1
fi

echo "Security scan passed"
```

## JSON Output Processing

```bash
# Save JSON and display CLI output simultaneously
snyk test --json-file-output=results.json

# Parse JSON with jq
snyk test --json | jq '.vulnerabilities[] | {id: .id, severity: .severity, title: .title}'

# Count by severity
snyk test --json | jq '[.vulnerabilities[].severity] | group_by(.) | map({(.[0]): length}) | add'

# List only high/critical
snyk test --json | jq '.vulnerabilities[] | select(.severity == "high" or .severity == "critical") | .title'
```
