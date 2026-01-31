# Frontend Pipeline Patterns

CI/CD pipelines for React, Remix, Vite, Next.js and deployment to Firebase, Vercel, or static hosting.

## React with Vite

### Basic Vite Pipeline
```yaml
image: node:18

pipelines:
  default:
    - step:
        name: Build and Test
        caches:
          - node
        script:
          - npm ci
          - npm run lint
          - npm run typecheck
          - npm run test
          - npm run build
        artifacts:
          - dist/**
```

### Production Vite Pipeline
```yaml
image: node:18

definitions:
  steps:
    - step: &test-and-lint
        name: Test and Lint
        caches:
          - node
        script:
          - npm ci --ignore-scripts
          - npm run lint:ci
          - npm run typecheck
          - npm run test

pipelines:
  pull-requests:
    "**":
      - step: *test-and-lint
  
  branches:
    main:
      - step: *test-and-lint
      - step:
          name: Build
          caches:
            - node
          script:
            - npm run build
          artifacts:
            - dist/**
```

## Firebase Hosting Deployment

### Deploy to Firebase
```yaml
image: node:18

pipelines:
  branches:
    main:
      - step:
          name: Build and Deploy to Firebase
          deployment: production
          caches:
            - node
          script:
            - npm ci
            - npm run build
            - pipe: atlassian/firebase-deploy:5.1.1
              variables:
                KEY_FILE: $GOOGLE_SERVICE_ACCOUNT_KEY
                PROJECT_ID: $GOOGLE_PROJECT_ID
                DIST_FOLDER: "dist"
                EXTRA_ARGS: "--only hosting"
```

### Multi-Site Firebase Deployment
```yaml
pipelines:
  branches:
    develop:
      - step:
          name: Deploy to Staging
          deployment: staging
          caches:
            - node
          script:
            - npm ci
            - npm run build
            - pipe: atlassian/firebase-deploy:5.1.1
              variables:
                KEY_FILE: $GOOGLE_SERVICE_ACCOUNT_KEY
                PROJECT_ID: $GOOGLE_PROJECT_ID
                DIST_FOLDER: "build/client"
                EXTRA_ARGS: "--only hosting"
                MULTI_SITES_CONFIG: >
                  [{
                    "TARGET": "app",
                    "RESOURCE": "myapp-staging"
                  }]
    
    main:
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          caches:
            - node
          script:
            - npm ci
            - npm run build
            - pipe: atlassian/firebase-deploy:5.1.1
              variables:
                KEY_FILE: $GOOGLE_SERVICE_ACCOUNT_KEY
                PROJECT_ID: $GOOGLE_PROJECT_ID
                DIST_FOLDER: "build/client"
                EXTRA_ARGS: "--only hosting"
                MULTI_SITES_CONFIG: >
                  [{
                    "TARGET": "app",
                    "RESOURCE": "myapp-production"
                  }]
```

## Playwright E2E Testing

### Playwright Configuration (Gold Standard)

**From edenbazar - Production-proven fail-fast configuration:**

```typescript
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  // Stop after first failure in CI to save time and provide fast feedback
  maxFailures: process.env.CI ? 1 : undefined,
  
  // Fail the build on CI if you accidentally left test.only in the source code
  forbidOnly: !!process.env.CI,
  
  // Run tests in files in parallel
  fullyParallel: true,
  
  // Retry only in CI
  retries: process.env.CI ? 2 : 0,
  
  // Configure projects for major browsers
  projects: [
    // API tests - only run on chromium (no browser-specific behavior)
    {
      name: "api",
      testMatch: "**/api/**/*.spec.ts",
      use: { ...devices["Desktop Chrome"] },
    },
    
    // UI tests - Desktop browsers
    {
      name: "chromium",
      testIgnore: process.env.CI
        ? ["**/api/**/*.spec.ts", "**/visual/**"]
        : "**/api/**/*.spec.ts",
      use: { ...devices["Desktop Chrome"] },
    },
    
    // Mobile viewports
    {
      name: "Mobile Chrome",
      testIgnore: process.env.CI
        ? ["**/api/**/*.spec.ts", "**/visual/**"]
        : "**/api/**/*.spec.ts",
      use: { ...devices["Pixel 5"] },
    },
  ],
  
  // Reporter for CI
  reporter: process.env.CI
    ? [
        ["list"],   // Shows test progress line by line
        ["github"], // Adds error annotations
      ]
    : undefined,
  
  testDir: "./tests/e2e",
  
  // Global test timeout
  timeout: 30000,
  
  // Expect timeout
  expect: {
    timeout: 15000,
  },
  
  use: {
    actionTimeout: 10000,
    baseURL: "http://localhost:5177",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
    trace: "on-first-retry",
  },
  
  // Run 8 parallel workers on CI to utilize 4x pipeline (8 CPUs)
  workers: process.env.CI ? 16 : undefined,
  
  // Run mock GraphQL server and dev server before tests
  webServer: [
    {
      command: "npx tsx tests/mocks/mock-server.ts",
      port: 4444,
      reuseExistingServer: !process.env.CI,
    },
    {
      command: "npm run dev -- --port=5177",
      port: 5177,
      reuseExistingServer: !process.env.CI,
      timeout: 120 * 1000,
    },
  ],
});
```

**Key fail-fast features:**
- ✅ `maxFailures: 1` - Stop after first failure (saves 5-15 min)
- ✅ `forbidOnly` - Prevent accidental test.only commits
- ✅ `fullyParallel: true` - Max speed for test execution
- ✅ `workers: 16` - Utilize 4x pipeline (8 CPUs) fully
- ✅ Separate API tests (faster, browser-agnostic)
- ✅ Skip visual tests in CI (prevent flakiness)

### Basic Playwright Tests
```yaml
image: mcr.microsoft.com/playwright:v1.56.1-noble

pipelines:
  default:
    - step:
        name: E2E Tests
        size: 2x
        caches:
          - node
        script:
          - npm ci --ignore-scripts
          - npm run test:e2e
        artifacts:
          - playwright-report/**
          - test-results/**
```

### Production Playwright Pipeline (edenbazar pattern)

```yaml
image: node:18

definitions:
  steps:
    - step: &lint
        name: Lint Code
        max-time: 5
        caches:
          - node
        script:
          - HUSKY=0 npm ci
          - npm run lint:ci  # --max-warnings=0
    
    - step: &typecheck
        name: TypeScript Check
        max-time: 5
        caches:
          - node
        script:
          - HUSKY=0 npm ci
          - npm run typecheck
    
    - step: &test
        name: Run Unit Tests
        max-time: 10
        caches:
          - node
        script:
          - HUSKY=0 npm ci
          - npm run test:ci  # Vitest with bail: 1
    
    - step: &build
        name: Build
        max-time: 10
        caches:
          - node
        script:
          - HUSKY=0 npm ci
          - npm run build
        artifacts:
          - dist/**
    
    - step: &test-e2e
        name: E2E Tests (Playwright)
        image: mcr.microsoft.com/playwright:v1.55.0-noble
        size: 4x  # 8 CPUs for 16 parallel workers
        max-time: 30
        caches:
          - node
        script:
          - HUSKY=0 npm ci
          - npm run test:e2e  # Uses maxFailures: 1 from config
        artifacts:
          - playwright-report/**
          - test-results/**

pipelines:
  pull-requests:
    "**":
      - parallel:
          fail-fast: true  # Stop all if any fails
          steps:
            - step: *lint
            - step: *typecheck
            - step: *test
      - step: *build
      - step: *test-e2e
  
  branches:
    main:
      - parallel:
          fail-fast: true
          steps:
            - step: *lint
            - step: *typecheck
            - step: *test
      - step: *build
      - step: *test-e2e
      - step:
          name: Deploy to Firebase
          deployment: production
          script:
            - pipe: atlassian/firebase-deploy:5.1.1
              variables:
                KEY_FILE: $GOOGLE_SERVICE_ACCOUNT_KEY
                PROJECT_ID: $GOOGLE_PROJECT_ID
                DIST_FOLDER: "dist"
                EXTRA_ARGS: "--only hosting"
```

**Key patterns from edenbazar:**
- ✅ `HUSKY=0 npm ci` - Skip git hooks in CI
- ✅ `fail-fast: true` - Stop parallel steps on failure
- ✅ `max-time` - Prevent hanging steps
- ✅ `size: 4x` - 8 CPUs for 16 Playwright workers
- ✅ Separate build step with artifacts
- ✅ E2E only after build succeeds

## Remix Application

### Remix with Firebase
```yaml
image: node:18

pipelines:
  branches:
    main:
      - step:
          name: Test
          caches:
            - node
          script:
            - npm ci
            - npm run lint
            - npm run typecheck
            - npm run test
      
      - step:
          name: Build and Deploy
          deployment: production
          caches:
            - node
          script:
            - npm ci
            - npm run build
            - pipe: atlassian/firebase-deploy:5.1.1
              variables:
                KEY_FILE: $GOOGLE_SERVICE_ACCOUNT_KEY
                PROJECT_ID: $GOOGLE_PROJECT_ID
                DIST_FOLDER: "build/client"
                EXTRA_ARGS: "--only hosting"
```

## Next.js Application

### Next.js with Vercel
```yaml
image: node:18

pipelines:
  branches:
    main:
      - step:
          name: Build and Deploy to Vercel
          deployment: production
          caches:
            - node
          script:
            - npm ci
            - npm run build
            - npm install -g vercel
            - vercel --prod --token=$VERCEL_TOKEN
```

### Next.js with Static Export
```yaml
image: node:18

pipelines:
  branches:
    main:
      - step:
          name: Build Static Export
          caches:
            - node
          script:
            - npm ci
            - npm run build
          artifacts:
            - out/**
      
      - step:
          name: Deploy to Hosting
          deployment: production
          script:
            # Deploy to your static hosting
            - npm run deploy
```

## Complete Frontend Pipeline with Sentry

### Production-Ready React/Vite Pipeline
```yaml
image: node:18

definitions:
  steps:
    - step: &test-and-lint
        name: Test and Lint
        caches:
          - node
        script:
          - npm ci --ignore-scripts
          - npm run lint:ci
          - npm run typecheck
          - npm run test

pipelines:
  pull-requests:
    "**":
      - step: *test-and-lint
  
  branches:
    develop:
      - step: *test-and-lint
      - step:
          name: Build and Deploy to Staging
          deployment: staging
          caches:
            - node
          script:
            # Calculate Sentry release version
            - |
              export PKG_VERSION=$(grep "version" package.json | sed 's/.*"version": *"\([^"]*\)".*/\1/')
              if [ -n "$BITBUCKET_BUILD_NUMBER" ]; then
                export VITE_SENTRY_RELEASE="$PKG_VERSION-$BITBUCKET_BUILD_NUMBER"
              else
                export VITE_SENTRY_RELEASE="$PKG_VERSION"
              fi
            - echo "Using Sentry release $VITE_SENTRY_RELEASE"
            
            # Install Sentry CLI
            - npm install -g @sentry/cli
            
            # Create Sentry release
            - sentry-cli releases new "$VITE_SENTRY_RELEASE"
            - sentry-cli releases set-commits "$VITE_SENTRY_RELEASE" --auto || true
            
            # Build
            - npm run build
            
            # Upload sourcemaps
            - sentry-cli releases files "$VITE_SENTRY_RELEASE" upload-sourcemaps ./dist --url-prefix '~/' --rewrite
            
            # Finalize release
            - sentry-cli releases finalize "$VITE_SENTRY_RELEASE"
            - sentry-cli releases deploys new --release "$VITE_SENTRY_RELEASE" -e staging
            
            # Deploy
            - pipe: atlassian/firebase-deploy:5.1.1
              variables:
                KEY_FILE: $GOOGLE_SERVICE_ACCOUNT_KEY
                PROJECT_ID: $GOOGLE_PROJECT_ID
                DIST_FOLDER: "dist"
                EXTRA_ARGS: "--only hosting"
    
    main:
      - step: *test-and-lint
      - step:
          name: Build and Deploy to Production
          deployment: production
          trigger: manual
          caches:
            - node
          script:
            # Calculate Sentry release version
            - |
              export PKG_VERSION=$(grep "version" package.json | sed 's/.*"version": *"\([^"]*\)".*/\1/')
              if [ -n "$BITBUCKET_BUILD_NUMBER" ]; then
                export VITE_SENTRY_RELEASE="$PKG_VERSION-$BITBUCKET_BUILD_NUMBER"
              else
                export VITE_SENTRY_RELEASE="$PKG_VERSION"
              fi
            - echo "Using Sentry release $VITE_SENTRY_RELEASE"
            
            # Install Sentry CLI
            - npm install -g @sentry/cli
            
            # Create Sentry release
            - sentry-cli releases new "$VITE_SENTRY_RELEASE"
            - sentry-cli releases set-commits "$VITE_SENTRY_RELEASE" --auto || true
            
            # Build
            - npm run build
            
            # Upload sourcemaps
            - sentry-cli releases files "$VITE_SENTRY_RELEASE" upload-sourcemaps ./dist --url-prefix '~/' --rewrite
            
            # Finalize release
            - sentry-cli releases finalize "$VITE_SENTRY_RELEASE"
            - sentry-cli releases deploys new --release "$VITE_SENTRY_RELEASE" -e production
            
            # Deploy
            - pipe: atlassian/firebase-deploy:5.1.1
              variables:
                KEY_FILE: $GOOGLE_SERVICE_ACCOUNT_KEY
                PROJECT_ID: $GOOGLE_PROJECT_ID
                DIST_FOLDER: "dist"
                EXTRA_ARGS: "--only hosting"
```

## Docker-based Frontend

### Containerized React App to Cloud Run
```yaml
image: google/cloud-sdk:alpine

definitions:
  services:
    docker:
      memory: 7168
  caches:
    gcloud: ~/.cache/gcloud
    docker-layers: /var/lib/docker

pipelines:
  branches:
    master:
      - parallel:
          fail-fast: true
          steps:
            - step:
                name: Lint
                image: node:18-alpine
                caches:
                  - node
                script:
                  - npm ci --ignore-scripts
                  - npm run lint:ci
            
            - step:
                name: TypeScript Check
                image: node:18-alpine
                caches:
                  - node
                script:
                  - npm ci --ignore-scripts
                  - npm run typecheck
            
            - step:
                name: Unit Tests
                image: node:18-alpine
                caches:
                  - node
                script:
                  - npm ci --ignore-scripts
                  - npm run test
            
            - step:
                name: E2E Tests
                image: mcr.microsoft.com/playwright:v1.56.1-noble
                size: 8x
                caches:
                  - node
                script:
                  - npm ci --ignore-scripts
                  - npm run test:e2e
                artifacts:
                  - playwright-report/**
      
      - step:
          name: Build and Deploy to Cloud Run
          deployment: production
          size: 4x
          services:
            - docker
          caches:
            - docker
            - gcloud
            - docker-layers
          script:
            # Set up variables
            - export IMAGE_VERSIONED="$GOOGLE_REGION-docker.pkg.dev/$GOOGLE_PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY/app:$BITBUCKET_BUILD_NUMBER"
            - export VITE_BUILD_NUMBER=$BITBUCKET_BUILD_NUMBER
            
            # Authenticate
            - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
            - gcloud auth activate-service-account --key-file gcloud-service-key.json
            - gcloud config set project $GOOGLE_PROJECT_ID
            - gcloud auth configure-docker $GOOGLE_REGION-docker.pkg.dev --quiet
            
            # Build with BuildKit
            - export DOCKER_BUILDKIT=1
            - >
              docker build
              --build-arg BUILDKIT_INLINE_CACHE=1
              --build-arg VITE_API_URL="$VITE_API_URL"
              --build-arg VITE_BUILD_NUMBER="$VITE_BUILD_NUMBER"
              -t $IMAGE_VERSIONED .
            
            # Push image
            - docker push $IMAGE_VERSIONED
            
            # Deploy to Cloud Run
            - gcloud run deploy $CLOUD_RUN_SERVICE_NAME --image=$IMAGE_VERSIONED --region=$GOOGLE_REGION --quiet
            
            # Cleanup
            - rm gcloud-service-key.json
            - docker system prune -f
```

## Static Site Deployment

### Deploy to S3
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build and Deploy to S3
          deployment: production
          caches:
            - node
          script:
            - npm ci
            - npm run build
            - pipe: atlassian/aws-s3-deploy:1.1.0
              variables:
                AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
                AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
                AWS_DEFAULT_REGION: $AWS_REGION
                S3_BUCKET: $S3_BUCKET_NAME
                LOCAL_PATH: "dist"
```

### Deploy to Netlify
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build and Deploy to Netlify
          deployment: production
          caches:
            - node
          script:
            - npm ci
            - npm run build
            - npm install -g netlify-cli
            - netlify deploy --prod --dir=dist --auth=$NETLIFY_AUTH_TOKEN --site=$NETLIFY_SITE_ID
```

## Environment Variable Management

### Build with Environment Variables
```yaml
- step:
    name: Build with Env Vars
    script:
      # Set build-time environment variables
      - export VITE_API_URL=$VITE_API_URL
      - export VITE_FIREBASE_CONFIG=$VITE_FIREBASE_CONFIG
      - export VITE_SENTRY_DSN=$VITE_SENTRY_DSN
      
      # Build
      - npm run build
```

### Multi-line Environment Variables
```yaml
- step:
    script:
      # For JSON configs (like Firebase)
      - export VITE_FIREBASE_CONFIG="$VITE_FIREBASE_CONFIG"
      - npm run build
```

## HUSKY Git Hooks Pattern

### Disable Husky in CI
```yaml
pipelines:
  default:
    - step:
        script:
          # Disable Husky git hooks in CI
          - HUSKY=0 npm ci
          - npm run build
```

## Best Practices

### ✅ Do's
- Use `npm ci` instead of `npm install` for reproducible builds
- Disable Husky with `HUSKY=0 npm ci` in CI
- Use `--ignore-scripts` when you don't need postinstall scripts
- Cache node_modules with `- node` cache
- Run lint, typecheck, and tests in parallel
- Use appropriate Playwright image size (8x for heavy tests)
- Upload sourcemaps to Sentry before deployment
- Delete sourcemaps from production bundles
- Use manual triggers for production deployments

### ❌ Don'ts
- Don't use `npm install` in CI (use `npm ci`)
- Don't run Husky hooks in CI
- Don't skip testing before deployment
- Don't expose secrets in build output
- Don't serve sourcemaps in production
- Don't use small step sizes for Playwright (< 2x)
- Don't commit environment variables

## Common Patterns

### Package.json Scripts for CI
```json
{
  "scripts": {
    "build": "vite build",
    "test": "vitest run",
    "test:e2e": "playwright test",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "lint:ci": "eslint . --ext ts,tsx --max-warnings 0",
    "typecheck": "tsc --noEmit"
  }
}
```

### Dockerfile for React/Vite App
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app

ARG VITE_API_URL
ARG VITE_BUILD_NUMBER

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage with nginx
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## Troubleshooting

### Playwright Installation Issues
```yaml
# Use official Playwright image
image: mcr.microsoft.com/playwright:v1.56.1-noble

# Or install in Node image
image: node:18
script:
  - npx playwright install --with-deps chromium
```

### Build Memory Issues
```yaml
# Increase step size for large builds
- step:
    name: Build Large App
    size: 4x  # 8GB memory
    script:
      - npm run build
```

### Firebase Deploy Debugging
```yaml
- step:
    script:
      # Debug Firebase deployment
      - pipe: atlassian/firebase-deploy:5.1.1
        variables:
          KEY_FILE: $GOOGLE_SERVICE_ACCOUNT_KEY
          PROJECT_ID: $GOOGLE_PROJECT_ID
          DIST_FOLDER: "dist"
          EXTRA_ARGS: "--only hosting --debug"
```
