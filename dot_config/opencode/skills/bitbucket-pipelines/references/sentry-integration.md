# Sentry Integration

Integrate Sentry error tracking with release management, sourcemap uploads, and deployment tracking.

## Prerequisites

### Required Environment Variables
```yaml
# Set in Bitbucket Repository Settings → Deployments → Variables
SENTRY_AUTH_TOKEN      # Sentry authentication token
SENTRY_ORG             # Sentry organization slug
SENTRY_PROJECT         # Sentry project slug
SENTRY_DSN             # (Optional) Sentry DSN for the application
```

### Generate Sentry Auth Token
1. Go to Sentry → Settings → Account → API → Auth Tokens
2. Create new token with scopes: `project:releases`, `org:read`
3. Copy token to Bitbucket variables as `SENTRY_AUTH_TOKEN`

## Basic Release Management

### Simple Release Creation
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build and Create Sentry Release
          caches:
            - node
          script:
            # Calculate release version
            - export PKG_VERSION=$(grep "version" package.json | sed 's/.*"version": *"\([^"]*\)".*/\1/')
            - export SENTRY_RELEASE="$PKG_VERSION-$BITBUCKET_BUILD_NUMBER"
            
            # Install Sentry CLI
            - npm install -g @sentry/cli
            
            # Create release
            - sentry-cli releases new "$SENTRY_RELEASE"
            
            # Associate commits
            - sentry-cli releases set-commits "$SENTRY_RELEASE" --auto
            
            # Build application
            - npm run build
            
            # Finalize release
            - sentry-cli releases finalize "$SENTRY_RELEASE"
```

## Frontend Integration

### React/Vite with Sentry
```yaml
image: node:18

pipelines:
  branches:
    main:
      - step:
          name: Build and Deploy with Sentry
          deployment: production
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
            
            # Early validation - fail fast before expensive build
            - |
              if [ -z "$VITE_SENTRY_AUTH_TOKEN" ]; then
                echo "Error: VITE_SENTRY_AUTH_TOKEN not set"
                exit 1
              fi
            
            # Set up Sentry environment variables for build
            - export SENTRY_AUTH_TOKEN="$VITE_SENTRY_AUTH_TOKEN"
            - export SENTRY_ORG="$VITE_SENTRY_ORGANIZATION"
            - export SENTRY_PROJECT="$VITE_SENTRY_PROJECT"
            
            # Install Sentry CLI
            - npm install -g @sentry/cli
            
            # Create Sentry release
            - sentry-cli releases new "$VITE_SENTRY_RELEASE"
            - sentry-cli releases set-commits "$VITE_SENTRY_RELEASE" --auto || true
            
            # Build application (with sourcemaps)
            - npm run build
            
            # Upload sourcemaps
            - sentry-cli releases files "$VITE_SENTRY_RELEASE" upload-sourcemaps ./dist --url-prefix '~/' --rewrite
            
            # Finalize release
            - sentry-cli releases finalize "$VITE_SENTRY_RELEASE"
            
            # Mark deployment
            - sentry-cli releases deploys new --release "$VITE_SENTRY_RELEASE" -e production
```

### Next.js with Sentry
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build Next.js with Sentry
          caches:
            - node
          script:
            - export SENTRY_RELEASE="$NEXT_PUBLIC_APP_VERSION-$BITBUCKET_BUILD_NUMBER"
            
            # Install dependencies
            - npm ci
            
            # Build (Sentry plugin handles sourcemaps automatically)
            - npm run build
            
            # Or manually if not using plugin
            - npm install -g @sentry/cli
            - sentry-cli releases new "$SENTRY_RELEASE"
            - sentry-cli releases set-commits "$SENTRY_RELEASE" --auto
            - sentry-cli releases files "$SENTRY_RELEASE" upload-sourcemaps .next --url-prefix '~/_next' --rewrite
            - sentry-cli releases finalize "$SENTRY_RELEASE"
```

## Backend Integration

### NestJS with Sentry
```yaml
image: google/cloud-sdk:alpine

definitions:
  services:
    docker:
      memory: 3072

pipelines:
  branches:
    main:
      - step:
          name: Deploy with Sentry Tracking
          deployment: production
          services:
            - docker
          script:
            # Calculate Sentry release version
            - |
              export PKG_VERSION=$(grep "version" package.json | sed 's/.*"version": *"\([^"]*\)".*/\1/')
              if [ -n "$BITBUCKET_BUILD_NUMBER" ]; then
                export SENTRY_RELEASE="$PKG_VERSION-$BITBUCKET_BUILD_NUMBER"
              else
                export SENTRY_RELEASE="$PKG_VERSION"
              fi
            
            # Install Sentry CLI (Alpine)
            - apk add --no-cache curl
            - curl -sL https://sentry.io/get-cli/ | SENTRY_CLI_VERSION="2.28.6" sh
            - export PATH="$HOME/.local/bin/sentry-cli:$PATH"
            
            # Create Sentry release
            - sentry-cli releases new "$SENTRY_RELEASE" --org "$SENTRY_ORG" --project "$SENTRY_PROJECT"
            - sentry-cli releases set-commits "$SENTRY_RELEASE" --auto --org "$SENTRY_ORG" --project "$SENTRY_PROJECT"
            
            # Build Docker image with Sentry release info
            - export DOCKER_BUILDKIT=1
            - >-
              docker build
              --build-arg SENTRY_AUTH_TOKEN=$SENTRY_AUTH_TOKEN
              --build-arg SENTRY_ORG=$SENTRY_ORG
              --build-arg SENTRY_PROJECT=$SENTRY_PROJECT
              --build-arg SENTRY_RELEASE=$SENTRY_RELEASE
              --build-arg ENVIRONMENT=production
              -t myapp:$BITBUCKET_BUILD_NUMBER .
            
            # Deploy (Cloud Run, Kubernetes, etc.)
            - gcloud run deploy myapp --image=myapp:$BITBUCKET_BUILD_NUMBER --region=$GOOGLE_REGION
            
            # Finalize Sentry release after successful deployment
            - sentry-cli releases finalize "$SENTRY_RELEASE" --org "$SENTRY_ORG" --project "$SENTRY_PROJECT"
            - sentry-cli releases deploys new --release "$SENTRY_RELEASE" -e production --org "$SENTRY_ORG" --project "$SENTRY_PROJECT"
```

## Sourcemap Upload Patterns

### Upload Sourcemaps from Build Output
```yaml
- step:
    name: Upload Sourcemaps
    script:
      - export SENTRY_RELEASE="$APP_VERSION-$BITBUCKET_BUILD_NUMBER"
      - npm install -g @sentry/cli
      
      # Create release
      - sentry-cli releases new "$SENTRY_RELEASE"
      
      # Upload sourcemaps
      - sentry-cli releases files "$SENTRY_RELEASE" upload-sourcemaps ./dist --url-prefix '~/' --rewrite
      
      # Delete sourcemaps from dist (don't serve them)
      - find ./dist -name "*.map" -type f -delete
      
      # Finalize
      - sentry-cli releases finalize "$SENTRY_RELEASE"
```

### Upload Specific Directories
```yaml
- step:
    script:
      - export SENTRY_RELEASE="$VERSION-$BITBUCKET_BUILD_NUMBER"
      - npm install -g @sentry/cli
      
      # Upload JS sourcemaps
      - sentry-cli releases files "$SENTRY_RELEASE" upload-sourcemaps ./dist/js --url-prefix '~/js' --rewrite
      
      # Upload CSS sourcemaps
      - sentry-cli releases files "$SENTRY_RELEASE" upload-sourcemaps ./dist/css --url-prefix '~/css' --rewrite
```

## Multi-Environment Deployment Tracking

### Track Deployments to Different Environments
```yaml
pipelines:
  branches:
    develop:
      - step:
          name: Deploy to Staging
          deployment: staging
          script:
            - export SENTRY_RELEASE="$VERSION-$BITBUCKET_BUILD_NUMBER"
            - npm install -g @sentry/cli
            - sentry-cli releases new "$SENTRY_RELEASE"
            - sentry-cli releases set-commits "$SENTRY_RELEASE" --auto
            - npm run build
            - sentry-cli releases finalize "$SENTRY_RELEASE"
            - sentry-cli releases deploys new --release "$SENTRY_RELEASE" -e staging
            - npm run deploy:staging
    
    main:
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - export SENTRY_RELEASE="$VERSION-$BITBUCKET_BUILD_NUMBER"
            - npm install -g @sentry/cli
            - sentry-cli releases new "$SENTRY_RELEASE"
            - sentry-cli releases set-commits "$SENTRY_RELEASE" --auto
            - npm run build
            - sentry-cli releases finalize "$SENTRY_RELEASE"
            - sentry-cli releases deploys new --release "$SENTRY_RELEASE" -e production
            - npm run deploy:prod
```

## Docker Build Integration

### Pass Sentry Info to Docker Build
```dockerfile
# Dockerfile
ARG SENTRY_AUTH_TOKEN
ARG SENTRY_ORG
ARG SENTRY_PROJECT
ARG SENTRY_RELEASE
ARG ENVIRONMENT

FROM node:18-alpine AS builder
WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci

# Copy source
COPY . .

# Build with Sentry release info
ARG SENTRY_AUTH_TOKEN
ARG SENTRY_ORG
ARG SENTRY_PROJECT
ARG SENTRY_RELEASE
ARG ENVIRONMENT

ENV SENTRY_AUTH_TOKEN=$SENTRY_AUTH_TOKEN \
    SENTRY_ORG=$SENTRY_ORG \
    SENTRY_PROJECT=$SENTRY_PROJECT \
    SENTRY_RELEASE=$SENTRY_RELEASE \
    ENVIRONMENT=$ENVIRONMENT

# Build application (Sentry SDK will use these env vars)
RUN npm run build

FROM node:18-alpine AS production
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./
RUN npm ci --production
ENV SENTRY_RELEASE=$SENTRY_RELEASE
CMD ["node", "dist/main.js"]
```

```yaml
# bitbucket-pipelines.yml
- step:
    services:
      - docker
    script:
      - export SENTRY_RELEASE="$VERSION-$BITBUCKET_BUILD_NUMBER"
      - >-
        docker build
        --build-arg SENTRY_AUTH_TOKEN=$SENTRY_AUTH_TOKEN
        --build-arg SENTRY_ORG=$SENTRY_ORG
        --build-arg SENTRY_PROJECT=$SENTRY_PROJECT
        --build-arg SENTRY_RELEASE=$SENTRY_RELEASE
        --build-arg ENVIRONMENT=production
        -t myapp:$BITBUCKET_BUILD_NUMBER .
```

## Version Calculation Patterns

### Package.json Version
```yaml
- script:
    - export PKG_VERSION=$(grep "version" package.json | sed 's/.*"version": *"\([^"]*\)".*/\1/')
    - export SENTRY_RELEASE="$PKG_VERSION-$BITBUCKET_BUILD_NUMBER"
```

### Git Tag Version
```yaml
- script:
    - export GIT_VERSION=$(git describe --tags --always)
    - export SENTRY_RELEASE="$GIT_VERSION"
```

### Semantic Version with Build Number
```yaml
- script:
    - export VERSION="1.0.0"
    - export SENTRY_RELEASE="$VERSION-build.$BITBUCKET_BUILD_NUMBER"
```

### Date-based Version
```yaml
- script:
    - export DATE_VERSION=$(date +%Y.%m.%d)
    - export SENTRY_RELEASE="$DATE_VERSION-$BITBUCKET_BUILD_NUMBER"
```

## Complete Real-World Example

### Production-Ready Pipeline with Sentry
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
            - HUSKY=0 npm ci
            - npm run test:ci
      
      - step:
          name: Build and Deploy with Sentry
          deployment: production
          trigger: manual
          caches:
            - node
          script:
            # Calculate release version
            - |
              export PKG_VERSION=$(grep "version" package.json | sed 's/.*"version": *"\([^"]*\)".*/\1/')
              if [ -n "$BITBUCKET_BUILD_NUMBER" ]; then
                export VITE_SENTRY_RELEASE="$PKG_VERSION-$BITBUCKET_BUILD_NUMBER"
              else
                export VITE_SENTRY_RELEASE="$PKG_VERSION"
              fi
            - echo "Deploying Sentry release $VITE_SENTRY_RELEASE"
            
            # Set up Sentry CLI
            - |
              export SENTRY_AUTH_TOKEN="$VITE_SENTRY_AUTH_TOKEN"
              export SENTRY_ORG="$VITE_SENTRY_ORGANIZATION"
              export SENTRY_PROJECT="$VITE_SENTRY_PROJECT"
            - npm install -g @sentry/cli
            
            # Create Sentry release
            - sentry-cli releases new "$VITE_SENTRY_RELEASE"
            - sentry-cli releases set-commits "$VITE_SENTRY_RELEASE" --auto || true
            
            # Build application
            - npm run build
            
            # Upload sourcemaps
            - sentry-cli releases files "$VITE_SENTRY_RELEASE" upload-sourcemaps ./dist --url-prefix '~/' --rewrite
            
            # Finalize release
            - sentry-cli releases finalize "$VITE_SENTRY_RELEASE"
            
            # Deploy to production
            - npm run deploy:prod
            
            # Mark deployment in Sentry
            - sentry-cli releases deploys new --release "$VITE_SENTRY_RELEASE" -e production
```

## Best Practices

### ✅ Do's
- Use consistent release naming (version-buildnumber)
- Associate commits with releases
- Upload sourcemaps before finalization
- Track deployments per environment
- Delete sourcemaps from production bundles
- Use Sentry CLI for automation
- Finalize releases after successful deployment

### ❌ Don'ts
- Don't commit Sentry auth tokens
- Don't skip sourcemap uploads
- Don't serve sourcemaps in production
- Don't use same release for multiple environments
- Don't forget to finalize releases
- Don't expose SENTRY_AUTH_TOKEN in logs

## Troubleshooting

### Sentry CLI Installation Issues
```yaml
# Alpine Linux (google/cloud-sdk:alpine)
- apk add --no-cache curl
- curl -sL https://sentry.io/get-cli/ | SENTRY_CLI_VERSION="2.28.6" sh

# Debian/Ubuntu (node:18)
- npm install -g @sentry/cli
```

### Debug Release Creation
```yaml
- script:
    - sentry-cli releases list --org "$SENTRY_ORG" --project "$SENTRY_PROJECT"
    - sentry-cli releases info "$SENTRY_RELEASE" --org "$SENTRY_ORG" --project "$SENTRY_PROJECT"
```

### Verify Sourcemap Upload
```yaml
- script:
    - sentry-cli releases files "$SENTRY_RELEASE" list --org "$SENTRY_ORG" --project "$SENTRY_PROJECT"
```
