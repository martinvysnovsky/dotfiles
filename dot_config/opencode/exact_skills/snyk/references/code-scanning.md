# Snyk Code - Static Application Security Testing (SAST)

## Contents
- snyk code test command
- Supported languages and frameworks
- Severity levels and categories
- Output formats
- Configuration options
- Interfile analysis
- IDE integration tips

## snyk code test

Performs static analysis of source code to find security vulnerabilities without executing the code. Analyzes data flow, control flow, and taint tracking across files.

### Basic Usage

```bash
# Scan current directory
snyk code test

# Scan specific directory
snyk code test /path/to/project

# Filter by severity
snyk code test --severity-threshold=high

# Output as JSON
snyk code test --json

# Output as SARIF (for IDE/CI integration)
snyk code test --sarif
```

### Command-Specific Flags

| Flag | Description |
|------|-------------|
| `--severity-threshold=<level>` | Filter: `low`, `medium`, `high` |
| `--json` | JSON output |
| `--json-file-output=<file>` | Write JSON to file |
| `--sarif` | SARIF format output |
| `--sarif-file-output=<file>` | Write SARIF to file |
| `--org=<ORG_ID>` | Associate with Snyk organization |

**Note:** `snyk code test` does not support `--all-projects` or `--file` flags. It always scans the entire project directory.

## Supported Languages

| Language | File Extensions | Framework Support |
|----------|----------------|-------------------|
| JavaScript | `.js`, `.jsx` | Express, React, Angular, Vue |
| TypeScript | `.ts`, `.tsx` | NestJS, Next.js, Angular |
| Python | `.py` | Django, Flask, FastAPI |
| Java | `.java` | Spring, Spring Boot, Jakarta |
| C# | `.cs` | .NET, ASP.NET Core |
| PHP | `.php` | Laravel, Symfony |
| Ruby | `.rb` | Rails, Sinatra |
| Go | `.go` | Gin, Echo, net/http |
| Swift | `.swift` | iOS/macOS apps |
| Kotlin | `.kt` | Android, Spring Boot |
| Scala | `.scala` | Play, Akka |
| C/C++ | `.c`, `.cpp`, `.h` | Various |
| Apex | `.cls`, `.trigger` | Salesforce |

## Vulnerability Categories

Snyk Code detects vulnerabilities across these categories:

### Injection Flaws
- **SQL Injection** - Unsanitized input in SQL queries
- **NoSQL Injection** - Unsanitized input in NoSQL queries (MongoDB, etc.)
- **Command Injection** - OS command execution with user input
- **LDAP Injection** - Unsanitized input in LDAP queries
- **XPath Injection** - Unsanitized input in XPath expressions
- **Code Injection** - Dynamic code execution (`eval`, `Function()`)
- **Template Injection** - Server-side template injection (SSTI)

### Cross-Site Scripting (XSS)
- **Reflected XSS** - User input reflected in response
- **Stored XSS** - Malicious data stored and rendered
- **DOM-based XSS** - Client-side DOM manipulation

### Authentication & Session
- **Hardcoded Credentials** - Passwords/keys in source code
- **Weak Cryptography** - Insecure algorithms (MD5, SHA1 for passwords)
- **Insecure Random** - Predictable random number generation
- **Session Fixation** - Reuse of session identifiers

### Data Exposure
- **Information Disclosure** - Sensitive data in logs/responses
- **Path Traversal** - Directory traversal via user input
- **Server-Side Request Forgery (SSRF)** - Unvalidated external requests
- **Open Redirect** - Unvalidated redirect URLs

### Configuration
- **Insecure TLS/SSL** - Disabled certificate validation
- **Missing Security Headers** - CSP, HSTS, X-Frame-Options
- **Debug Mode** - Debug enabled in production
- **CORS Misconfiguration** - Overly permissive CORS

## Severity Levels

| Level | Description | Examples |
|-------|-------------|----------|
| **High** | Exploitable vulnerability with significant impact | SQL injection, RCE, hardcoded secrets |
| **Medium** | Vulnerability requiring specific conditions | XSS with limited context, open redirect |
| **Low** | Minor issue or best practice violation | Information disclosure, weak crypto usage |

## Output Interpretation

### CLI Output

```
Testing /my/project ...

 ✗ [High] SQL Injection
   Path: src/users/users.service.ts, line 45
   Info: Unsanitized input from request parameter 'id' flows into SQL query

 ✗ [Medium] Cross-Site Scripting (XSS)
   Path: src/components/UserProfile.tsx, line 23
   Info: User input rendered without sanitization via dangerouslySetInnerHTML

 ✗ [Low] Cleartext Logging of Sensitive Data
   Path: src/auth/auth.service.ts, line 67
   Info: Password value logged to console

Test Summary

  Organization: my-org
  Test type:    Static code analysis
  Project path: /my/project

  3 Code issues found
  1 [High]  2 [Medium]  0 [Low]
```

### JSON Output

```bash
snyk code test --json | jq '.runs[0].results[] | {
  severity: .level,
  rule: .ruleId,
  message: .message.text,
  file: .locations[0].physicalLocation.artifactLocation.uri,
  line: .locations[0].physicalLocation.region.startLine
}'
```

### SARIF Output

SARIF (Static Analysis Results Interchange Format) is ideal for:
- IDE integration (VS Code, IntelliJ)
- GitHub Code Scanning alerts
- Azure DevOps integration
- Aggregating results from multiple tools

```bash
# Generate SARIF
snyk code test --sarif-file-output=snyk-code.sarif

# Upload to GitHub Code Scanning
gh api repos/{owner}/{repo}/code-scanning/sarifs \
  -f "sarif=$(cat snyk-code.sarif | base64)" \
  -f "ref=refs/heads/main"
```

## Interfile Analysis

Snyk Code performs analysis across multiple files, tracking data flow through:

- Function calls and returns
- Module imports/exports
- Class methods and inheritance
- Callback functions and promises
- Framework-specific patterns (e.g., Express middleware chain)

**Example: Cross-file taint tracking**

```
// routes/users.ts (source)
router.get('/users', (req, res) => {
  const id = req.query.id;        // <-- Taint source
  const user = userService.find(id);  // Data flows to service
});

// services/userService.ts (sink)
find(id: string) {
  return db.query(`SELECT * FROM users WHERE id = ${id}`);  // <-- SQL Injection sink
}
```

Snyk Code traces `req.query.id` from the route handler through `userService.find()` to the SQL query, identifying the injection vulnerability even though source and sink are in different files.

## Configuration

### .snyk Policy for Code Issues

```yaml
version: v1.5.0
ignore:
  # Ignore specific code finding by rule ID
  javascript/NoHardcodedCredentials:
    - '*':
        reason: 'Test fixtures, not production credentials'
        expires: 2025-06-01T00:00:00.000Z
```

### Excluding Files from Scan

Create or update `.snyk` file:

```yaml
exclude:
  global:
    - tests/**
    - "**/*.test.ts"
    - "**/*.spec.ts"
    - node_modules/**
    - dist/**
    - build/**
    - coverage/**
    - "**/*.min.js"
```

## CI/CD Integration

### Basic Pipeline Step

```bash
# Run SAST scan, fail on high severity
snyk code test --severity-threshold=high

# Save results for artifact
snyk code test --sarif-file-output=snyk-code.sarif || true
```

### Bitbucket Pipeline

```yaml
- step:
    name: SAST Scan
    script:
      - npm install -g snyk
      - snyk auth $SNYK_TOKEN
      - snyk code test --severity-threshold=high --sarif-file-output=snyk-code.sarif
    artifacts:
      upload:
        - name: sast-results
          type: scoped
          paths:
            - snyk-code.sarif
```

### Combined SCA + SAST

```bash
#!/bin/bash
set -e

echo "=== Dependency Scan (SCA) ==="
snyk test --severity-threshold=high

echo "=== Source Code Scan (SAST) ==="
snyk code test --severity-threshold=high

echo "All security scans passed"
```

## Comparison: snyk test vs snyk code test

| Feature | `snyk test` (SCA) | `snyk code test` (SAST) |
|---------|-------------------|------------------------|
| Scans | Dependencies/packages | Source code |
| Detects | Known CVEs in libraries | Code-level vulnerabilities |
| Data source | Snyk vulnerability DB | Code analysis engine |
| Fix available | Yes (upgrade/patch) | Manual remediation |
| `--file` flag | Yes | No |
| `--all-projects` | Yes | No |
| `--monitor` | Yes (`snyk monitor`) | No |
| Speed | Fast (manifest parsing) | Slower (code analysis) |

## Best Practices

1. **Run both SCA and SAST** - `snyk test` catches known CVEs, `snyk code test` catches custom code vulnerabilities
2. **Set severity threshold in CI** - Use `--severity-threshold=high` to avoid blocking on low-risk findings
3. **Use SARIF for reporting** - Machine-readable format integrates with most CI/CD and IDE tools
4. **Exclude test files** - Configure `.snyk` exclude to skip test fixtures and mock data
5. **Review interfile findings carefully** - Cross-file vulnerabilities are often the most impactful
6. **Fix high-severity first** - Prioritize findings by exploitability and business impact
