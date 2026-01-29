# Fail-Fast Patterns: Save Pipeline Minutes

## Core Principle

**Fail soon to save run minutes.** Configure all pipeline steps, tests, and checks to fail immediately when issues are detected. Don't waste time and resources on remaining steps when early failures occur.

**Key Benefits:**
- ⚡ Save 3-10 minutes per failed pipeline
- 💰 Reduce pipeline minute costs
- 🚀 Faster feedback for developers
- ✅ Earlier detection of issues

## Pipeline-Level Fail-Fast

### Parallel Steps with fail-fast

**Always use `fail-fast: true`** in parallel execution (this is the default behavior):

```yaml
pipelines:
  default:
    - parallel:
        fail-fast: true  # Stop all parallel steps if any fails
        steps:
          - step:
              name: Unit Tests
              script:
                - npm run test:ci
          - step:
              name: Lint
              script:
                - npm run lint:ci
          - step:
              name: Type Check
              script:
                - npm run typecheck
```

**What happens:**
- If Lint fails → Unit Tests and Type Check are immediately stopped
- Saves 2-5 minutes per failure
- No wasted pipeline minutes on doomed builds

### Step Timeouts

Configure reasonable timeouts to prevent hanging steps:

```yaml
- step:
    name: Build
    max-time: 10  # Fail after 10 minutes
    script:
      - npm run build
```

**Common timeout values:**
- Linting: 2-5 minutes
- Unit tests: 5-10 minutes
- E2E tests: 10-30 minutes
- Builds: 5-15 minutes
- Deployments: 5-10 minutes

## Test-Level Fail-Fast

### Jest (Backend Testing)

#### Configuration Method (Recommended)

Add to `jest.config.ts`:

```typescript
import type { Config } from 'jest';

const config: Config = {
  // ... other config
  
  // Fail fast in CI to save pipeline minutes
  bail: process.env.CI ? 1 : undefined,
  
  // OR use maxFailures for slightly more tolerance
  // maxFailures: process.env.CI ? 3 : undefined,
};

export default config;
```

**Real-world example from peppermill-api:**
```typescript
const config: Config = {
  testEnvironment: 'node',
  clearMocks: true,
  // Testcontainers support
  testTimeout: 60000,
  maxWorkers: 1, // Sequential for Testcontainers
  detectOpenHandles: true,
  forceExit: true,
  // Fail fast in CI to save pipeline minutes
  bail: process.env.CI ? 1 : undefined,
};
```

#### CLI Flag Method

Add to package.json scripts:

```json
{
  "scripts": {
    "test": "jest",
    "test:ci": "jest --ci --bail"
  }
}
```

**Pipeline usage:**
```yaml
- step:
    name: Test
    script:
      - HUSKY=0 npm ci
      - npm run test:ci
```

#### Options Explained

**`bail: 1`** (Recommended for CI)
- Stops after **first** test failure
- Maximum time savings
- Best for quick feedback

**`maxFailures: 3`** (Alternative)
- Stops after **N** failures
- Useful if you want to see multiple failures
- Balance between feedback and speed

**Local vs CI:**
- Local: `undefined` (see all failures for debugging)
- CI: `1` (fail fast to save minutes)

### Playwright (E2E Testing)

#### Gold Standard Configuration

**Real-world example from edenbazar (excellent!):**

```typescript
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  // Stop after first failure in CI to save time
  maxFailures: process.env.CI ? 1 : undefined,
  
  // Fail the build if test.only is left in code
  forbidOnly: !!process.env.CI,
  
  // Run tests in files in parallel
  fullyParallel: true,
  
  // Retry only in CI
  retries: process.env.CI ? 2 : 0,
  
  // Optimize worker count for CI (4x pipeline = 8 CPUs)
  workers: process.env.CI ? 16 : undefined,
  
  // Fast feedback on failure
  expect: {
    timeout: 15000,
  },
  
  timeout: 30000,
  
  use: {
    actionTimeout: 10000,
    screenshot: "only-on-failure",
    video: "retain-on-failure",
    trace: "on-first-retry",
  },
  
  // Separate API tests (faster, browser-agnostic)
  projects: [
    {
      name: "api",
      testMatch: "**/api/**/*.spec.ts",
    },
    {
      name: "chromium",
      testIgnore: process.env.CI 
        ? ["**/api/**/*.spec.ts", "**/visual/**"]
        : "**/api/**/*.spec.ts",
    },
  ],
});
```

**Key patterns:**
- `maxFailures: 1` → Stop after first E2E failure
- `forbidOnly` → Prevent accidental test.only commits
- `fullyParallel` → Max speed for test execution
- `workers: 16` → Utilize 4x pipeline (8 CPUs) fully

**Pipeline step:**
```yaml
- step:
    name: E2E Tests
    size: 4x  # 8 CPUs for parallel execution
    image: mcr.microsoft.com/playwright:v1.55.0-noble
    script:
      - HUSKY=0 npm ci
      - npx playwright install  # Already in image
      - npm run test:e2e
```

### Vitest (Frontend Unit Testing)

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Fail fast in CI
    bail: process.env.CI ? 1 : undefined,
    
    // OR
    // maxFailures: process.env.CI ? 3 : undefined,
  },
});
```

## Linting Fail-Fast

### ESLint

#### Gold Standard Pattern

**Real-world example from peppermill-api (perfect!):**

```json
{
  "scripts": {
    "lint": "eslint \"{src,apps,libs,test}/**/*.ts\" --fix",
    "lint:ci": "eslint \"{src,apps,libs,test}/**/*.ts\" --max-warnings=0"
  }
}
```

**What `--max-warnings=0` does:**
- Treats **all warnings as errors** in CI
- Fails immediately on first warning
- Prevents warning accumulation
- Enforces clean code standards

**Pipeline usage:**
```yaml
- step:
    name: Lint
    script:
      - HUSKY=0 npm ci
      - npm run lint:ci
```

**Why this is excellent:**
- ✅ Development: Warnings allowed (auto-fix with `--fix`)
- ✅ CI: Zero tolerance for warnings
- ✅ Fast feedback: Fails on first issue
- ✅ Prevents tech debt accumulation

### GraphQL Schema Linting

```json
{
  "scripts": {
    "gql:lint": "graphql-schema-linter src/**/*.graphql --rules-dir ./graphql-rules"
  }
}
```

**Pipeline:**
```yaml
- step:
    name: GraphQL Lint
    script:
      - npm run gql:lint
```

### TypeScript Type Checking

```json
{
  "scripts": {
    "typecheck": "tsc --noEmit"
  }
}
```

**Pipeline:**
```yaml
- step:
    name: Type Check
    script:
      - npm run typecheck  # Fails on first type error
```

## Build-Level Fail-Fast

### Dependency Installation

**HUSKY=0 Pattern** (Essential):

```yaml
- step:
    name: Build
    script:
      - HUSKY=0 npm ci  # Skip git hooks in CI
      - npm run build
```

**Why HUSKY=0:**
- Git hooks don't work in CI (no git repo)
- Prevents hook execution errors
- Faster installation (skips hook setup)
- **Always use in CI pipelines**

### Docker Builds

#### Multi-Stage with Early Failure

```dockerfile
# Stage 1: Dependencies (fails early if package-lock.json invalid)
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Build (fails early if TypeScript errors)
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 3: Production (only runs if above succeed)
FROM node:18-alpine AS runner
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/main"]
```

**Pipeline:**
```yaml
- step:
    name: Build Docker Image
    services:
      - docker
    script:
      - docker build -t myapp:$BITBUCKET_BUILD_NUMBER .
      # Fails immediately if any stage fails
```

## Complete Real-World Examples

### Example 1: NestJS API with Fail-Fast

```yaml
image: node:18

definitions:
  caches:
    npm: ~/.npm
  
  steps:
    - step: &quality-checks
        name: Quality Checks
        caches:
          - npm
        script:
          - HUSKY=0 npm ci
          - npm run lint:ci          # Fails on first warning
          - npm run typecheck         # Fails on first type error
          - npm run gql:lint          # Fails on schema issues
    
    - step: &test
        name: Unit Tests
        caches:
          - npm
        script:
          - HUSKY=0 npm ci
          - npm run test:ci           # Fails on first test failure (bail: 1)
    
    - step: &build
        name: Build
        caches:
          - npm
        script:
          - HUSKY=0 npm ci
          - npm run build

pipelines:
  default:
    - parallel:
        fail-fast: true              # Stop all if any fails
        steps:
          - step: *quality-checks
          - step: *test
    - step: *build
  
  branches:
    main:
      - parallel:
        fail-fast: true
        steps:
          - step: *quality-checks
          - step: *test
      - step: *build
      - step:
          name: Deploy to Cloud Run
          script:
            - # ... deployment
```

**Time savings:**
- Lint fails → Save 5 min (test + build skipped)
- First test fails → Save 3 min (remaining tests + build skipped)
- Type check fails → Save 6 min (test + build skipped)

### Example 2: Frontend with Playwright (edenbazar pattern)

```yaml
image: node:18

pipelines:
  default:
    - parallel:
        fail-fast: true
        steps:
          - step:
              name: Lint
              caches: [npm]
              script:
                - HUSKY=0 npm ci
                - npm run lint:ci    # --max-warnings=0
          
          - step:
              name: Type Check
              caches: [npm]
              script:
                - HUSKY=0 npm ci
                - npm run typecheck
          
          - step:
              name: Unit Tests
              caches: [npm]
              script:
                - HUSKY=0 npm ci
                - npm run test:ci    # Vitest with bail: 1
    
    - step:
        name: Build
        caches: [npm]
        script:
          - HUSKY=0 npm ci
          - npm run build
        artifacts:
          - dist/**
    
    - step:
        name: E2E Tests
        size: 4x                     # 8 CPUs for parallel tests
        image: mcr.microsoft.com/playwright:v1.55.0-noble
        script:
          - HUSKY=0 npm ci
          - npm run test:e2e         # maxFailures: 1 in config
```

**Configuration (playwright.config.ts):**
```typescript
export default defineConfig({
  maxFailures: process.env.CI ? 1 : undefined,  // Gold standard!
  forbidOnly: !!process.env.CI,
  fullyParallel: true,
  workers: process.env.CI ? 16 : undefined,
});
```

### Example 3: Complete Pipeline with GCP + Sentry

```yaml
image: node:18

definitions:
  caches:
    npm: ~/.npm
  
  steps:
    - step: &validate
        name: Validate
        max-time: 5
        caches: [npm]
        script:
          - HUSKY=0 npm ci
          - npm run lint:ci
          - npm run typecheck
    
    - step: &test
        name: Test
        max-time: 10
        caches: [npm]
        script:
          - HUSKY=0 npm ci
          - npm run test:ci
    
    - step: &build
        name: Build
        max-time: 10
        caches: [npm]
        script:
          - HUSKY=0 npm ci
          - npm run build
        artifacts:
          - dist/**
          - package*.json

pipelines:
  branches:
    main:
      - parallel:
          fail-fast: true           # Critical: stop all on failure
          steps:
            - step: *validate
            - step: *test
      
      - step: *build
      
      - step:
          name: Deploy to Cloud Run
          image: google/cloud-sdk:alpine
          max-time: 10
          script:
            # Early validation before expensive operations
            - |
              if [ -z "$GCP_SERVICE_ACCOUNT_KEY" ]; then
                echo "Error: GCP_SERVICE_ACCOUNT_KEY not set"
                exit 1
              fi
            
            # Authenticate
            - echo $GCP_SERVICE_ACCOUNT_KEY | base64 -d > gcp-key.json
            - gcloud auth activate-service-account --key-file gcp-key.json
            
            # Deploy (fails fast if any command fails)
            - gcloud run deploy api \
                --image gcr.io/project/api:$BITBUCKET_BUILD_NUMBER \
                --region europe-west1 \
                --platform managed
      
      - step:
          name: Create Sentry Release
          image: getsentry/sentry-cli:latest
          script:
            # Validate Sentry config early
            - |
              if [ -z "$SENTRY_AUTH_TOKEN" ]; then
                echo "Error: SENTRY_AUTH_TOKEN not set"
                exit 1
              fi
            
            - export SENTRY_RELEASE=$(sentry-cli releases propose-version)
            - sentry-cli releases new $SENTRY_RELEASE
            - sentry-cli releases set-commits $SENTRY_RELEASE --auto
            - sentry-cli releases finalize $SENTRY_RELEASE
```

## Anti-Patterns to Avoid

### ❌ Don't: Run all tests after failure

```yaml
# BAD: No bail configuration
- step:
    name: Test
    script:
      - npm run test  # Runs all 500 tests even if first one fails
```

**Problem:** Wastes 5-10 minutes on doomed builds

### ❌ Don't: Parallel without fail-fast

```yaml
# BAD: Missing fail-fast
- parallel:
    steps:
      - step:
          name: Lint
          script: npm run lint
      - step:
          name: Test  # Continues even if lint fails
          script: npm run test
```

**Problem:** Wastes pipeline minutes on failing builds

### ❌ Don't: Allow warnings in CI

```yaml
# BAD: Warnings allowed
- step:
    name: Lint
    script:
      - npm run lint  # No --max-warnings=0
```

**Problem:** Warnings accumulate, become errors later

### ❌ Don't: No timeouts on long steps

```yaml
# BAD: No timeout
- step:
    name: E2E Tests
    script:
      - npm run test:e2e  # Could hang for 2 hours
```

**Problem:** Wastes 2 hours if tests hang

### ❌ Don't: Run git hooks in CI

```yaml
# BAD: Git hooks run in CI
- step:
    script:
      - npm ci  # Tries to run Husky hooks, fails
```

**Problem:** Hook execution errors, slower installation

## Quick Reference: Fail-Fast Checklist

**Pipeline Level:**
- [ ] `fail-fast: true` in all parallel blocks
- [ ] `max-time` on all steps (especially long ones)
- [ ] Early validation before expensive operations

**Test Level:**
- [ ] Jest: `bail: process.env.CI ? 1 : undefined`
- [ ] Playwright: `maxFailures: process.env.CI ? 1 : undefined`
- [ ] Vitest: `bail: process.env.CI ? 1 : undefined`

**Lint Level:**
- [ ] ESLint: `--max-warnings=0` in CI script
- [ ] TypeScript: `tsc --noEmit` fails on errors
- [ ] GraphQL: Schema linter configured

**Build Level:**
- [ ] `HUSKY=0` on all `npm ci` commands
- [ ] Docker multi-stage builds (early failures)
- [ ] Dependency validation before builds

**Deployment Level:**
- [ ] Early validation of environment variables
- [ ] Authentication checks before deployments
- [ ] Reasonable timeouts on cloud operations

## Estimated Time Savings

**Per Pipeline (with failures):**
- Lint failure: Save 3-8 minutes
- Test failure: Save 2-6 minutes
- Build failure: Save 5-10 minutes
- Type check failure: Save 4-9 minutes

**Per Week (10 pipelines with failures):**
- Conservative: 50-80 minutes saved
- Typical: 80-150 minutes saved
- Heavy usage: 150-300 minutes saved

**Per Month:**
- Conservative: 200-320 minutes (3-5 hours)
- Typical: 320-600 minutes (5-10 hours)
- Heavy usage: 600-1200 minutes (10-20 hours)
