# Snyk Container & Infrastructure as Code Scanning

## Contents
- snyk container test command
- snyk container monitor command
- Base image recommendations
- Dockerfile scanning
- snyk iac test command
- Terraform scanning
- Kubernetes scanning
- CloudFormation and ARM templates

---

## Snyk Container

### snyk container test

Scans container images for known vulnerabilities in OS packages and application dependencies.

#### Basic Usage

```bash
# Scan a Docker image by tag
snyk container test node:18-alpine

# Scan a locally built image
snyk container test my-app:latest

# Scan from a registry
snyk container test docker.io/library/nginx:latest

# Scan with Dockerfile for base image recommendations
snyk container test my-app:latest --file=Dockerfile

# Filter by severity
snyk container test my-app:latest --severity-threshold=high

# Output as JSON
snyk container test my-app:latest --json
```

#### Command-Specific Flags

| Flag | Description |
|------|-------------|
| `--file=<Dockerfile>` | Provide Dockerfile for base image upgrade advice |
| `--severity-threshold=<level>` | Filter: `low`, `medium`, `high`, `critical` |
| `--exclude-base-image-vulns` | Only show vulnerabilities from your layers |
| `--exclude-app-vulns` | Only show OS package vulnerabilities |
| `--app-vulns` | Include application dependencies (npm, pip, etc.) |
| `--nested-jars-depth=<N>` | Depth for scanning nested JARs (Java) |
| `--json` | JSON output |
| `--json-file-output=<file>` | Write JSON to file |
| `--sarif` | SARIF format output |
| `--platform=<os/arch>` | Specify platform (e.g., `linux/amd64`, `linux/arm64`) |
| `--username=<user>` | Registry username |
| `--password=<pass>` | Registry password |

#### Output Interpretation

```
Testing node:18-alpine...

Organization:     my-org
Package manager:  apk
Target file:      Dockerfile
Project name:     docker-image|node
Docker image:     node:18-alpine
Platform:         linux/amd64
Base image:       alpine:3.18
Licenses:         enabled

Tested 42 dependencies for known issues, found 5 issues.

Base Image     Vulnerabilities  Severity
node:18-alpine 5               1 critical, 2 high, 2 medium

Recommendations for base image upgrade:

Minor upgrades
Base Image         Vulnerabilities  Severity
node:18.19-alpine  2               0 critical, 1 high, 1 medium

Major upgrades
Base Image         Vulnerabilities  Severity
node:20-alpine     0               no known vulnerabilities

Alternative image types
Base Image             Vulnerabilities  Severity
node:18-slim           3               0 critical, 1 high, 2 medium
```

**Key insight:** Always pass `--file=Dockerfile` to get base image upgrade recommendations.

### snyk container monitor

Creates a monitored snapshot of the container image for continuous vulnerability alerts.

```bash
# Monitor an image
snyk container monitor my-app:latest --file=Dockerfile

# Monitor with project name
snyk container monitor my-app:latest \
  --file=Dockerfile \
  --project-name="my-app-container" \
  --org=my-team

# Monitor with environment tags
snyk container monitor my-app:latest \
  --file=Dockerfile \
  --project-environment=production
```

### Base Image Recommendations

When Snyk scans with a Dockerfile, it provides upgrade suggestions:

| Recommendation Type | Description |
|---------------------|-------------|
| **Minor upgrade** | Same major version, fewer vulnerabilities |
| **Major upgrade** | New major version, significantly fewer vulnerabilities |
| **Alternative type** | Different base image variant (slim, alpine, distroless) |

#### Best Practices for Base Images

```dockerfile
# Prefer specific version tags over 'latest'
FROM node:20.11-alpine3.19

# Use multi-stage builds to minimize attack surface
FROM node:20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:20-alpine AS production
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER node
CMD ["node", "dist/main.js"]
```

**Image selection priority:**
1. **Distroless** - Minimal attack surface (no shell, no package manager)
2. **Alpine** - Small footprint (~5MB base), uses musl libc
3. **Slim** - Debian-based, smaller than full images
4. **Full** - Complete OS, largest attack surface (avoid in production)

### Scanning Application Dependencies in Containers

```bash
# Include app vulnerabilities (node_modules, pip packages, etc.)
snyk container test my-app:latest --app-vulns

# Exclude base image vulns (focus on your code)
snyk container test my-app:latest --exclude-base-image-vulns --app-vulns
```

### CI/CD Integration

```yaml
# Bitbucket Pipeline
- step:
    name: Container Security Scan
    services:
      - docker
    script:
      - docker build -t my-app:$BITBUCKET_COMMIT .
      - npm install -g snyk
      - snyk auth $SNYK_TOKEN
      - snyk container test my-app:$BITBUCKET_COMMIT --file=Dockerfile --severity-threshold=high
      - snyk container monitor my-app:$BITBUCKET_COMMIT --file=Dockerfile --project-name="my-app-container"
```

---

## Snyk Infrastructure as Code (IaC)

### snyk iac test

Scans infrastructure as code files for security misconfigurations before deployment.

#### Basic Usage

```bash
# Scan current directory
snyk iac test

# Scan specific file
snyk iac test main.tf

# Scan specific directory
snyk iac test /path/to/terraform/

# Filter by severity
snyk iac test --severity-threshold=medium

# Output as JSON
snyk iac test --json
```

#### Command-Specific Flags

| Flag | Description |
|------|-------------|
| `--severity-threshold=<level>` | Filter: `low`, `medium`, `high`, `critical` |
| `--json` | JSON output |
| `--json-file-output=<file>` | Write JSON to file |
| `--sarif` | SARIF format output |
| `--sarif-file-output=<file>` | Write SARIF to file |
| `--scan=<type>` | Scan type: `resource-changes` (Terraform plan) or `planned-values` |
| `--rules=<path>` | Path to custom rules bundle |
| `--org=<ORG_ID>` | Associate with Snyk organization |
| `--report` | Share results to Snyk web UI |

### Supported IaC Formats

| Format | File Types | Description |
|--------|-----------|-------------|
| **Terraform** | `.tf`, `.tf.json` | HCL configuration files |
| **Terraform Plan** | JSON plan output | `terraform plan -out=plan.bin && terraform show -json plan.bin > plan.json` |
| **Kubernetes** | `.yaml`, `.yml`, `.json` | K8s manifests, Helm charts |
| **CloudFormation** | `.yaml`, `.yml`, `.json` | AWS CloudFormation templates |
| **ARM Templates** | `.json` | Azure Resource Manager templates |

### Terraform Scanning

#### Basic Terraform Scan

```bash
# Scan all .tf files in directory
snyk iac test

# Scan specific file
snyk iac test main.tf

# Scan with severity filter
snyk iac test --severity-threshold=medium --json
```

#### Terraform Plan Scanning

Scanning the plan output detects issues in the actual planned changes, including dynamic values and module outputs.

```bash
# Generate plan
terraform plan -out=tfplan.bin

# Convert to JSON
terraform show -json tfplan.bin > tfplan.json

# Scan the plan
snyk iac test tfplan.json --scan=planned-values
```

#### Common Terraform Issues Detected

| Issue | Severity | Description |
|-------|----------|-------------|
| S3 bucket public access | High | S3 bucket allows public read/write |
| Security group open to world | High | Ingress rule allows 0.0.0.0/0 |
| Unencrypted storage | Medium | EBS/RDS/S3 without encryption |
| Missing logging | Medium | CloudTrail/VPC flow logs disabled |
| Overly permissive IAM | High | Wildcard `*` in IAM policy actions |
| No HTTPS enforcement | Medium | ALB/CloudFront without HTTPS redirect |
| Missing tags | Low | Resources without required tags |
| Default VPC usage | Low | Resources in default VPC |

#### Example Output

```
Testing main.tf...

Infrastructure as code issues:

  ✗ S3 Bucket does not have encryption enabled [Medium Severity] [SNYK-CC-TF-45]
    introduced by resource > aws_s3_bucket[data] > server_side_encryption_configuration
    Path: main.tf > resource > aws_s3_bucket[data]

  ✗ Security Group allows open ingress [High Severity] [SNYK-CC-TF-1]
    introduced by resource > aws_security_group[web] > ingress
    Path: main.tf > resource > aws_security_group[web] > ingress[0]

  ✗ EC2 instance does not use IMDSv2 [Medium Severity] [SNYK-CC-AWS-426]
    introduced by resource > aws_instance[web] > metadata_options
    Path: main.tf > resource > aws_instance[web]

Test Summary

  Organization: my-org
  Project name: my-infra

  3 issues found
  1 [High]  2 [Medium]  0 [Low]
```

### Kubernetes Scanning

```bash
# Scan K8s manifests
snyk iac test deployment.yaml

# Scan Helm rendered templates
helm template my-release ./my-chart | snyk iac test --stdin

# Scan entire k8s directory
snyk iac test k8s/
```

#### Common Kubernetes Issues Detected

| Issue | Severity | Description |
|-------|----------|-------------|
| Container running as root | Medium | `securityContext.runAsNonRoot` not set |
| Missing resource limits | Low | No CPU/memory limits defined |
| Privileged container | High | `securityContext.privileged: true` |
| Writable root filesystem | Medium | `readOnlyRootFilesystem` not set |
| Missing network policy | Medium | No NetworkPolicy restricting traffic |
| Host PID/network sharing | High | `hostPID` or `hostNetwork` enabled |
| Latest tag used | Low | Image tag `:latest` instead of pinned version |

### Custom Rules

Create custom IaC rules for organization-specific policies:

```bash
# Scan with custom rules bundle
snyk iac test --rules=custom-rules.tar.gz

# Combine with built-in rules
snyk iac test --rules=custom-rules.tar.gz --severity-threshold=medium
```

### Ignoring IaC Issues

```bash
# Ignore specific rule
snyk ignore --id=SNYK-CC-TF-45 --reason="Encryption handled by KMS policy" --expiry=2025-06-01

# In .snyk policy file
```

```yaml
version: v1.5.0
ignore:
  SNYK-CC-TF-45:
    - '*':
        reason: 'S3 encryption managed by AWS KMS default key'
        expires: 2025-06-01T00:00:00.000Z
```

### CI/CD Integration

#### Terraform Pipeline

```yaml
# Bitbucket Pipeline
- step:
    name: IaC Security Scan
    image: hashicorp/terraform:1.7
    script:
      - terraform init
      - terraform plan -out=tfplan.bin
      - terraform show -json tfplan.bin > tfplan.json
      - npm install -g snyk
      - snyk auth $SNYK_TOKEN
      - snyk iac test --severity-threshold=medium
      - snyk iac test tfplan.json --scan=planned-values --severity-threshold=high
```

#### Kubernetes Pipeline

```yaml
- step:
    name: K8s Manifest Scan
    script:
      - npm install -g snyk
      - snyk auth $SNYK_TOKEN
      - snyk iac test k8s/ --severity-threshold=medium --json-file-output=iac-results.json
    artifacts:
      upload:
        - name: iac-results
          type: scoped
          paths:
            - iac-results.json
```

## Complete Security Pipeline

Combining all scan types in a single CI/CD pipeline:

```yaml
pipelines:
  default:
    - parallel:
        - step:
            name: Dependency Scan (SCA)
            caches:
              - node
            script:
              - npm ci
              - npm install -g snyk
              - snyk auth $SNYK_TOKEN
              - snyk test --severity-threshold=high
        
        - step:
            name: Code Scan (SAST)
            script:
              - npm install -g snyk
              - snyk auth $SNYK_TOKEN
              - snyk code test --severity-threshold=high
        
        - step:
            name: IaC Scan
            script:
              - npm install -g snyk
              - snyk auth $SNYK_TOKEN
              - snyk iac test --severity-threshold=medium
    
    - step:
        name: Container Scan
        services:
          - docker
        script:
          - docker build -t app:$BITBUCKET_COMMIT .
          - npm install -g snyk
          - snyk auth $SNYK_TOKEN
          - snyk container test app:$BITBUCKET_COMMIT --file=Dockerfile --severity-threshold=high

  branches:
    main:
      - step:
          name: Monitor
          script:
            - npm ci
            - npm install -g snyk
            - snyk auth $SNYK_TOKEN
            - snyk monitor --project-name="$BITBUCKET_REPO_SLUG-deps"
            - docker build -t app:latest .
            - snyk container monitor app:latest --file=Dockerfile --project-name="$BITBUCKET_REPO_SLUG-container"
```

## Best Practices

### Container Scanning
1. **Always provide Dockerfile** with `--file` for base image recommendations
2. **Scan in CI/CD** after `docker build`, before `docker push`
3. **Monitor production images** with `snyk container monitor`
4. **Use multi-stage builds** to minimize final image size and attack surface
5. **Pin base image versions** to specific digests or version tags
6. **Prefer distroless/alpine** over full OS images

### IaC Scanning
1. **Scan both HCL and plan output** for comprehensive coverage
2. **Set severity thresholds** to avoid blocking on informational findings
3. **Use custom rules** for organization-specific security policies
4. **Scan early** in the development cycle, not just before deployment
5. **Integrate with PR checks** to catch misconfigurations before merge
6. **Track ignores** with expiry dates and clear justifications
