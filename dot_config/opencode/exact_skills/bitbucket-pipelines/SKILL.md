---
name: bitbucket-pipelines
description: Bitbucket Pipelines CI/CD patterns including pipeline configuration, caching strategies, deployments, Docker workflows, and NestJS-specific builds. Use when (1) creating or modifying bitbucket-pipelines.yml, (2) setting up CI/CD workflows, (3) configuring caching and artifacts, (4) implementing deployment strategies, (5) building and pushing Docker images, (6) running tests in pipelines, (7) optimizing build performance.
---

# Bitbucket Pipelines Patterns

## Core Principles

1. **Fail Fast, Save Minutes** - Configure all steps to fail immediately on errors. Stop parallel steps when any fails. Use `bail: 1` in tests, `--max-warnings=0` in linting, and `fail-fast: true` in parallel blocks.
2. **Cache Aggressively** - Cache dependencies, build outputs, and intermediate artifacts to minimize redundant work.
3. **Run Tests in Parallel** - Execute independent checks (lint, test, typecheck) concurrently for faster feedback.
4. **Use Appropriate Pipeline Sizes** - Match pipeline resources (1x, 2x, 4x, 8x) to workload requirements.

## Quick Reference

This skill provides comprehensive Bitbucket Pipelines patterns for CI/CD workflows. Load reference files as needed:

**Core Concepts:**
- **[fail-fast-patterns.md](references/fail-fast-patterns.md)** - Save pipeline minutes by failing early (Jest bail, Playwright maxFailures, ESLint --max-warnings=0)
- **[basic-pipeline.md](references/basic-pipeline.md)** - Pipeline structure, steps, triggers, branches, variables, services, Pipes, image overrides
- **[caching.md](references/caching.md)** - Cache definitions, custom caches, cache invalidation strategies
- **[deployments.md](references/deployments.md)** - Environment deployments, manual triggers, deployment variables

**Cloud Providers:**
- **[gcp-deployment.md](references/gcp-deployment.md)** - Cloud Run, Artifact Registry, Cloud Storage, GCP authentication
- **[sentry-integration.md](references/sentry-integration.md)** - Sentry releases, sourcemap uploads, deployment tracking

**Application Types:**
- **[docker.md](references/docker.md)** - Docker builds, multi-stage builds, image pushing, Docker-in-Docker
- **[nestjs-pipeline.md](references/nestjs-pipeline.md)** - NestJS testing, builds, GCP deployment, Sentry integration
- **[frontend-pipelines.md](references/frontend-pipelines.md)** - React, Vite, Remix, Next.js, Firebase, Playwright testing

## Basic Pipeline Structure

```yaml
image: node:18

definitions:
  caches:
    npm: ~/.npm
  
  steps:
    - step: &build-and-test
        name: Build and Test
        caches:
          - node
        script:
          - npm ci
          - npm run build
          - npm run test

pipelines:
  default:
    - step: *build-and-test
  
  branches:
    main:
      - step: *build-and-test
      - step:
          name: Deploy to Production
          deployment: production
          script:
            - npm run deploy:prod
```

## File Location

Always create pipeline configuration at repository root:
```
bitbucket-pipelines.yml
```

## Common Patterns

### Step Anchors and Reuse
```yaml
definitions:
  steps:
    - step: &build
        name: Build
        script:
          - npm ci
          - npm run build

pipelines:
  default:
    - step: *build
  branches:
    main:
      - step: *build
```

### Parallel Execution
```yaml
pipelines:
  default:
    - parallel:
        - step:
            name: Unit Tests
            script:
              - npm run test:unit
        - step:
            name: Lint
            script:
              - npm run lint
        - step:
            name: Type Check
            script:
              - npm run type-check
```

### Services (Database, Docker)
```yaml
definitions:
  services:
    mongodb:
      image: mongo:7.0
      environment:
        MONGO_INITDB_DATABASE: test

pipelines:
  default:
    - step:
        name: E2E Tests
        services:
          - mongodb
        script:
          - npm run test:e2e
```

## Environment Variables

### Repository Variables
Set in Bitbucket UI: Repository Settings → Pipelines → Repository variables

### Secure Variables
Mark as "Secured" for sensitive data (API keys, passwords)

### Pipeline Variables
```yaml
definitions:
  steps:
    - step: &deploy
        name: Deploy
        script:
          - export VERSION=$(git describe --tags)
          - echo "Deploying $VERSION"
```

## Best Practices

### ✅ Do's
- Use caching for `node_modules`, build outputs
- Employ step anchors to avoid duplication
- Run fast checks (lint, type-check) in parallel
- Use services for integration tests
- Set deployment steps only for specific branches
- Use artifacts to pass files between steps

### ❌ Don'ts
- Don't commit secrets to pipeline YAML
- Don't run expensive tests on every branch
- Don't cache generated files that change frequently
- Don't use large Docker images when smaller alternatives exist
- Don't skip cache validation after dependency changes

## Performance Optimization

1. **Caching**: Cache dependencies and build outputs
2. **Parallel Steps**: Run independent tasks concurrently
3. **Image Size**: Use slim/alpine base images
4. **Conditional Execution**: Use branch/tag conditions
5. **Artifacts**: Only pass necessary files between steps

## Common Use Cases

- **[Fail-Fast Patterns](references/fail-fast-patterns.md)** - Save pipeline minutes with immediate failures (Jest, Playwright, ESLint)
- **[Basic Node.js Build](references/basic-pipeline.md#nodejs-pipeline)** - Install, build, test
- **[Docker Build & Push](references/docker.md#build-and-push)** - Build image and push to registry
- **[Multi-Environment Deploy](references/deployments.md#multi-environment)** - Dev, staging, production
- **[NestJS Complete Pipeline](references/nestjs-pipeline.md#complete-pipeline)** - Test, build, deploy NestJS apps
- **[GCP Cloud Run Deploy](references/gcp-deployment.md)** - Deploy to Google Cloud Run with Artifact Registry
- **[Sentry Release Tracking](references/sentry-integration.md)** - Create releases, upload sourcemaps
- **[React/Vite to Firebase](references/frontend-pipelines.md)** - Build and deploy React apps to Firebase Hosting
- **[Playwright E2E Tests](references/frontend-pipelines.md#playwright-e2e-testing)** - Run end-to-end tests with Playwright

## Quick Tips

**Maximum parallel steps**: 10 steps per stage
**Step timeout**: Default 120 minutes (configurable)
**Cache size limit**: 1GB per cache definition
**Artifact retention**: 14 days (configurable up to 180 days)

## Reference Documentation

**Performance & Optimization:**
- [Fail-Fast Patterns](references/fail-fast-patterns.md) - Save minutes by failing early (bail, maxFailures, timeouts)
- [Caching Strategies](references/caching.md) - Cache dependencies and build outputs

**Core Pipelines:**
- [Basic Pipeline Configuration](references/basic-pipeline.md) - Syntax, structure, Pipes, image overrides
- [Deployment Patterns](references/deployments.md) - Multi-environment deployments

**Cloud & Services:**
- [GCP Deployment](references/gcp-deployment.md) - Cloud Run, Artifact Registry, authentication
- [Sentry Integration](references/sentry-integration.md) - Release tracking, sourcemaps

**Application-Specific:**
- [Docker Workflows](references/docker.md) - Container builds and registries
- [NestJS Pipelines](references/nestjs-pipeline.md) - Backend API testing and deployment
- [Frontend Pipelines](references/frontend-pipelines.md) - React, Vite, Firebase, Playwright
