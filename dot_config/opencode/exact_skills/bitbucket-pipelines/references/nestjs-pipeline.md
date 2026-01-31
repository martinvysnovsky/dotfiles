# NestJS Pipeline Patterns

Complete CI/CD pipelines for NestJS applications including testing, building, Docker deployment, and environment management.

## Basic NestJS Pipeline

### Simple Build and Test
```yaml
image: node:18

pipelines:
  default:
    - step:
        name: Install and Test
        caches:
          - node
        script:
          - npm ci
          - npm run build
          - npm run test
          - npm run test:e2e
```

## Complete NestJS Pipeline

### Production-Ready Pipeline
```yaml
image: node:18

definitions:
  caches:
    npm: ~/.npm
    jest: node_modules/.cache/jest
  
  services:
    mongodb:
      image: mongo:7.0
      environment:
        MONGO_INITDB_DATABASE: test
  
  steps:
    - step: &install
        name: Install Dependencies
        caches:
          - node
          - npm
        script:
          - npm ci
        artifacts:
          - node_modules/**
    
    - step: &lint
        name: Lint
        max-time: 5
        script:
          - HUSKY=0 npm ci
          - npm run lint:ci  # --max-warnings=0
    
    - step: &type-check
        name: Type Check
        max-time: 5
        script:
          - HUSKY=0 npm ci
          - npm run typecheck  # tsc --noEmit
    
    - step: &unit-test
        name: Unit Tests
        max-time: 10
        caches:
          - jest
        script:
          - HUSKY=0 npm ci
          - npm run test:ci  # Uses bail: 1 from jest.config
        artifacts:
          - coverage/**
    
    - step: &e2e-test
        name: E2E Tests
        services:
          - mongodb
        script:
          - npm run test:e2e
        environment:
          DB_CONNECTION: mongodb://localhost:27017/test
          JWT_SECRET: test-secret-key
    
    - step: &build
        name: Build
        script:
          - npm run build
        artifacts:
          - dist/**

pipelines:
  default:
    - step: *install
    - parallel:
        fail-fast: true  # Stop all if any fails
        steps:
          - step: *lint
          - step: *type-check
          - step: *unit-test
    - step: *e2e-test
    - step: *build
  
  branches:
    develop:
      - step: *install
      - parallel:
          - step: *lint
          - step: *type-check
          - step: *unit-test
      - step: *e2e-test
      - step: *build
      - step:
          name: Deploy to Dev
          deployment: development
          script:
            - npm run deploy:dev
    
    main:
      - step: *install
      - parallel:
          - step: *lint
          - step: *type-check
          - step: *unit-test
      - step: *e2e-test
      - step: *build
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - npm run deploy:prod
  
  pull-requests:
    '**':
      - step: *install
      - parallel:
          - step: *lint
          - step: *type-check
          - step: *unit-test
```

## NestJS with Docker

### Dockerfile for NestJS
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine AS production
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --production
COPY --from=builder /app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/main"]
```

### Docker Build Pipeline
```yaml
image: atlassian/default-image:3

definitions:
  services:
    docker:
      memory: 2048
    mongodb:
      image: mongo:7.0

pipelines:
  branches:
    main:
      - step:
          name: Test
          image: node:18
          caches:
            - node
          services:
            - mongodb
          script:
            - npm ci
            - npm run test
            - npm run test:e2e
          environment:
            DB_CONNECTION: mongodb://localhost:27017/test
      
      - step:
          name: Build Docker Image
          services:
            - docker
          script:
            - export IMAGE_NAME=$DOCKER_HUB_USERNAME/nestjs-app
            - export IMAGE_TAG=${BITBUCKET_BUILD_NUMBER}
            - docker build -t $IMAGE_NAME:$IMAGE_TAG -t $IMAGE_NAME:latest .
            - echo $DOCKER_HUB_PASSWORD | docker login -u $DOCKER_HUB_USERNAME --password-stdin
            - docker push $IMAGE_NAME:$IMAGE_TAG
            - docker push $IMAGE_NAME:latest
      
      - step:
          name: Deploy
          deployment: production
          trigger: manual
          script:
            - kubectl set image deployment/nestjs-app nestjs-app=$DOCKER_HUB_USERNAME/nestjs-app:${BITBUCKET_BUILD_NUMBER}
```

## Testing Strategies

### Unit Tests Only
```yaml
pipelines:
  default:
    - step:
        name: Unit Tests
        caches:
          - node
        script:
          - npm ci
          - npm run test:cov
        artifacts:
          - coverage/lcov.info
      
      after-script:
        - pipe: atlassian/codecov-pipe:0.1.0
          variables:
            CODECOV_TOKEN: $CODECOV_TOKEN
```

### Unit + E2E Tests
```yaml
definitions:
  services:
    mongodb:
      image: mongo:7.0
    redis:
      image: redis:7-alpine

pipelines:
  default:
    - step:
        name: Install
        caches:
          - node
        script:
          - npm ci
        artifacts:
          - node_modules/**
    
    - parallel:
        - step:
            name: Unit Tests
            script:
              - npm run test:cov
        
        - step:
            name: E2E Tests
            services:
              - mongodb
              - redis
            script:
              - npm run test:e2e
            environment:
              DB_CONNECTION: mongodb://localhost:27017/test
              REDIS_URL: redis://localhost:6379
```

### E2E with Testcontainers
```yaml
pipelines:
  default:
    - step:
        name: E2E Tests with Testcontainers
        services:
          - docker
        caches:
          - node
        script:
          - npm ci
          - npm run test:e2e
```

## Database Migrations

### Run Migrations Before Deploy
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build
          caches:
            - node
          script:
            - npm ci
            - npm run build
          artifacts:
            - dist/**
      
      - step:
          name: Run Migrations
          deployment: production
          script:
            - npm run migration:run
      
      - step:
          name: Deploy
          deployment: production
          script:
            - npm run deploy:prod
```

### Migration Rollback
```yaml
pipelines:
  custom:
    rollback-migration:
      - step:
          name: Rollback Last Migration
          deployment: production
          script:
            - npm run migration:revert
```

## Environment-Specific Configurations

### Multi-Environment NestJS
```yaml
pipelines:
  branches:
    develop:
      - step:
          name: Build Development
          caches:
            - node
          script:
            - npm ci
            - npm run build
          artifacts:
            - dist/**
      
      - step:
          name: Deploy to Dev
          deployment: development
          script:
            - export NODE_ENV=development
            - npm run start:prod
    
    staging:
      - step:
          name: Build Staging
          caches:
            - node
          script:
            - npm ci
            - npm run build
          artifacts:
            - dist/**
      
      - step:
          name: Deploy to Staging
          deployment: staging
          script:
            - export NODE_ENV=staging
            - npm run deploy:staging
    
    main:
      - step:
          name: Build Production
          caches:
            - node
          script:
            - npm ci
            - npm run build:prod
          artifacts:
            - dist/**
      
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - export NODE_ENV=production
            - npm run deploy:prod
```

## Microservices Pattern

### Multiple NestJS Services
```yaml
pipelines:
  branches:
    main:
      - parallel:
          - step:
              name: Build Auth Service
              caches:
                - node
              script:
                - cd services/auth
                - npm ci
                - npm run build
              artifacts:
                - services/auth/dist/**
          
          - step:
              name: Build User Service
              caches:
                - node
              script:
                - cd services/user
                - npm ci
                - npm run build
              artifacts:
                - services/user/dist/**
          
          - step:
              name: Build API Gateway
              caches:
                - node
              script:
                - cd services/gateway
                - npm ci
                - npm run build
              artifacts:
                - services/gateway/dist/**
      
      - parallel:
          - step:
              name: Deploy Auth Service
              deployment: production
              script:
                - cd services/auth
                - npm run deploy
          
          - step:
              name: Deploy User Service
              deployment: production
              script:
                - cd services/user
                - npm run deploy
          
          - step:
              name: Deploy Gateway
              deployment: production
              script:
                - cd services/gateway
                - npm run deploy
```

## GraphQL-Specific Patterns

### GraphQL Linting and Validation
```yaml
pipelines:
  default:
    - step:
        name: Validate GraphQL Schema
        caches:
          - node
        script:
          - npm ci
          - npm run build
          - npm run gql:lint  # Lint GraphQL schema
          - npm run graphql:generate
          - npm run graphql:validate
```

### Schema Generation
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Generate Schema
          caches:
            - node
          script:
            - npm ci
            - npm run build
            - npm run graphql:generate-schema
          artifacts:
            - schema.gql
      
      - step:
          name: Upload Schema to Registry
          script:
            - npm run graphql:publish-schema
```

## Performance Testing

### Load Testing with Artillery
```yaml
pipelines:
  branches:
    staging:
      - step:
          name: Deploy to Staging
          deployment: staging
          script:
            - npm run deploy:staging
      
      - step:
          name: Load Test
          script:
            - npm install -g artillery
            - artillery run load-test.yml
```

## Monorepo with Nx

### Nx Monorepo Pipeline
```yaml
image: node:18

definitions:
  caches:
    npm: ~/.npm
    nx: node_modules/.cache/nx

pipelines:
  default:
    - step:
        name: Install
        caches:
          - node
          - npm
        script:
          - npm ci
        artifacts:
          - node_modules/**
    
    - step:
        name: Affected Tests
        caches:
          - nx
        script:
          - npx nx affected --target=test --base=origin/main
    
    - step:
        name: Affected Build
        caches:
          - nx
        script:
          - npx nx affected --target=build --base=origin/main
        artifacts:
          - dist/**
```

## Real-World GCP + Sentry Example

### Production NestJS API with Cloud Run and Sentry
```yaml
image: google/cloud-sdk:alpine

definitions:
  services:
    docker:
      memory: 3072
  caches:
    gcloud: ~/.cache/gcloud
    docker-layers: /var/lib/docker

pipelines:
  pull-requests:
    '**':
      - parallel:
          fail-fast: true
          steps:
            - step:
                name: Lint and Typecheck
                image: node:18
                caches:
                  - node
                script:
                  - HUSKY=0 npm ci
                  - npm run lint:ci
                  - npm run typecheck
                  - npm run gql:lint
            
            - step:
                name: Test
                image: node:18
                size: 2x
                caches:
                  - node
                  - docker
                services:
                  - docker
                script:
                  - HUSKY=0 npm ci
                  - npm run test:ci
                  - npm run test:e2e:ci
  
  branches:
    main:
      - parallel:
          fail-fast: true
          steps:
            - step:
                name: Lint and Typecheck
                image: node:18
                caches:
                  - node
                script:
                  - HUSKY=0 npm ci
                  - npm run lint:ci
                  - npm run typecheck
                  - npm run gql:lint
            
            - step:
                name: Test
                image: node:18
                size: 2x
                caches:
                  - node
                  - docker
                services:
                  - docker
                script:
                  - HUSKY=0 npm ci
                  - npm run test:ci
                  - npm run test:e2e:ci
      
      - step:
          name: Deploy to Staging with Sentry
          deployment: staging
          size: 4x
          services:
            - docker
          caches:
            - docker
            - gcloud
            - docker-layers
          script:
            # Set up variables
            - export IMAGE_VERSIONED="$DOCKER_REGISTRY_URL/$DOCKER_IMAGE_NAME:$BITBUCKET_BUILD_NUMBER"
            
            # Calculate Sentry release version
            - |
              export PKG_VERSION=$(grep "version" package.json | sed 's/.*"version": *"\([^"]*\)".*/\1/')
              if [ -n "$BITBUCKET_BUILD_NUMBER" ]; then
                export SENTRY_RELEASE="$PKG_VERSION-$BITBUCKET_BUILD_NUMBER"
              else
                export SENTRY_RELEASE="$PKG_VERSION"
              fi
            
            # Authenticate with Google Cloud
            - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
            - gcloud auth activate-service-account --key-file gcloud-service-key.json
            - gcloud config set project $GOOGLE_PROJECT_ID
            - gcloud auth configure-docker $GOOGLE_REGION-docker.pkg.dev --quiet
            
            # Build with BuildKit and Sentry integration
            - export DOCKER_BUILDKIT=1
            - >-
              docker build
              --build-arg BUILDKIT_INLINE_CACHE=1
              --build-arg SENTRY_AUTH_TOKEN=$SENTRY_AUTH_TOKEN
              --build-arg SENTRY_ORG=$SENTRY_ORG
              --build-arg SENTRY_PROJECT=$SENTRY_PROJECT
              --build-arg ENVIRONMENT=staging
              --build-arg SENTRY_RELEASE=$SENTRY_RELEASE
              -t $IMAGE_VERSIONED .
            
            # Push image
            - docker push $IMAGE_VERSIONED
            
            # Deploy to Cloud Run
            - gcloud run deploy $CLOUD_RUN_SERVICE_NAME --image=$IMAGE_VERSIONED --region=$GOOGLE_REGION --quiet
            
            # Cleanup
            - rm gcloud-service-key.json
            - docker system prune -f
      
      - step:
          name: Deploy to Production with Sentry
          deployment: production
          trigger: manual
          size: 4x
          services:
            - docker
          caches:
            - docker
            - gcloud
            - docker-layers
          script:
            # Set up variables
            - export IMAGE_VERSIONED="$DOCKER_REGISTRY_URL/$DOCKER_IMAGE_NAME:$BITBUCKET_BUILD_NUMBER"
            
            # Calculate Sentry release version
            - |
              export PKG_VERSION=$(grep "version" package.json | sed 's/.*"version": *"\([^"]*\)".*/\1/')
              if [ -n "$BITBUCKET_BUILD_NUMBER" ]; then
                export SENTRY_RELEASE="$PKG_VERSION-$BITBUCKET_BUILD_NUMBER"
              else
                export SENTRY_RELEASE="$PKG_VERSION"
              fi
            
            # Authenticate with Google Cloud
            - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
            - gcloud auth activate-service-account --key-file gcloud-service-key.json
            - gcloud config set project $GOOGLE_PROJECT_ID
            - gcloud auth configure-docker $GOOGLE_REGION-docker.pkg.dev --quiet
            
            # Build with BuildKit and Sentry integration
            - export DOCKER_BUILDKIT=1
            - >-
              docker build
              --build-arg BUILDKIT_INLINE_CACHE=1
              --build-arg SENTRY_AUTH_TOKEN=$SENTRY_AUTH_TOKEN
              --build-arg SENTRY_ORG=$SENTRY_ORG
              --build-arg SENTRY_PROJECT=$SENTRY_PROJECT
              --build-arg ENVIRONMENT=production
              --build-arg SENTRY_RELEASE=$SENTRY_RELEASE
              -t $IMAGE_VERSIONED .
            
            # Push image
            - docker push $IMAGE_VERSIONED
            
            # Deploy to Cloud Run
            - gcloud run deploy $CLOUD_RUN_SERVICE_NAME --image=$IMAGE_VERSIONED --region=$GOOGLE_REGION --quiet
            
            # Cleanup
            - rm gcloud-service-key.json
```

## Complete Production Pipeline

### Enterprise NestJS Pipeline
```yaml
image: node:18

definitions:
  caches:
    npm: ~/.npm
    jest: node_modules/.cache/jest
  
  services:
    docker:
      memory: 4096
    mongodb:
      image: mongo:7.0
      environment:
        MONGO_INITDB_DATABASE: test
    redis:
      image: redis:7-alpine
    postgres:
      image: postgres:15
      environment:
        POSTGRES_DB: test
        POSTGRES_USER: test
        POSTGRES_PASSWORD: test

pipelines:
  branches:
    develop:
      - step:
          name: Install
          caches:
            - node
            - npm
          script:
            - npm ci
          artifacts:
            - node_modules/**
      
      - parallel:
          - step:
              name: Lint
              script:
                - npm run lint
          
          - step:
              name: Type Check
              script:
                - npm run type-check
          
          - step:
              name: Unit Tests
              caches:
                - jest
              script:
                - npm run test:cov
              artifacts:
                - coverage/**
      
      - step:
          name: E2E Tests
          services:
            - mongodb
            - redis
            - postgres
          script:
            - npm run test:e2e
          environment:
            DB_CONNECTION: mongodb://localhost:27017/test
            REDIS_URL: redis://localhost:6379
            DATABASE_URL: postgresql://test:test@localhost:5432/test
      
      - step:
          name: Build
          script:
            - npm run build
          artifacts:
            - dist/**
      
      - step:
          name: Deploy to Development
          deployment: development
          script:
            - npm run deploy:dev
    
    main:
      - step:
          name: Install
          caches:
            - node
            - npm
          script:
            - npm ci
          artifacts:
            - node_modules/**
      
      - parallel:
          - step:
              name: Lint
              script:
                - npm run lint
          
          - step:
              name: Unit Tests
              caches:
                - jest
              script:
                - npm run test:cov
              artifacts:
                - coverage/**
      
      - step:
          name: E2E Tests
          services:
            - mongodb
            - redis
            - postgres
          script:
            - npm run test:e2e
      
      - step:
          name: Build Production
          script:
            - npm run build:prod
          artifacts:
            - dist/**
      
      - step:
          name: Build Docker Image
          services:
            - docker
          script:
            - export IMAGE_NAME=$DOCKER_HUB_USERNAME/nestjs-app
            - export IMAGE_TAG=${BITBUCKET_BUILD_NUMBER}
            - docker build -t $IMAGE_NAME:$IMAGE_TAG -t $IMAGE_NAME:latest .
            - echo $DOCKER_HUB_PASSWORD | docker login -u $DOCKER_HUB_USERNAME --password-stdin
            - docker push $IMAGE_NAME:$IMAGE_TAG
            - docker push $IMAGE_NAME:latest
      
      - step:
          name: Security Scan
          services:
            - docker
          script:
            - pipe: aquasecurity/trivy-pipe:1.0.0
              variables:
                IMAGE_NAME: $DOCKER_HUB_USERNAME/nestjs-app:${BITBUCKET_BUILD_NUMBER}
                SEVERITY: HIGH,CRITICAL
      
      - step:
          name: Run Migrations
          deployment: production
          trigger: manual
          script:
            - npm run migration:run
      
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - kubectl set image deployment/nestjs-app nestjs-app=$DOCKER_HUB_USERNAME/nestjs-app:${BITBUCKET_BUILD_NUMBER}
            - kubectl rollout status deployment/nestjs-app
      
      - step:
          name: Health Check
          script:
            - sleep 10
            - curl -f https://api.production.com/health || exit 1
            - npm run smoke-test:prod

  tags:
    'v*.*.*':
      - step:
          name: Install
          caches:
            - node
          script:
            - npm ci
          artifacts:
            - node_modules/**
      
      - step:
          name: Build Release
          script:
            - npm run build:prod
          artifacts:
            - dist/**
      
      - step:
          name: Build and Tag Release Image
          services:
            - docker
          script:
            - export IMAGE_NAME=$DOCKER_HUB_USERNAME/nestjs-app
            - docker build -t $IMAGE_NAME:${BITBUCKET_TAG} -t $IMAGE_NAME:latest .
            - echo $DOCKER_HUB_PASSWORD | docker login -u $DOCKER_HUB_USERNAME --password-stdin
            - docker push $IMAGE_NAME:${BITBUCKET_TAG}
            - docker push $IMAGE_NAME:latest
      
      - step:
          name: Create GitHub Release
          script:
            - npm run release:github
```

## Best Practices

### ✅ Do's - Fail Fast & Performance
- **Always** use `HUSKY=0 npm ci` in CI (skip git hooks)
- **Always** use `fail-fast: true` in parallel blocks
- **Always** add `bail: 1` to jest.config for CI
- **Always** use `--max-warnings=0` for ESLint in CI
- Cache `node_modules`, npm cache, and Jest cache
- Run lint, type-check, and tests in parallel
- Use `max-time` on steps to prevent hanging
- Configure timeouts: lint (5min), tests (10min), build (10min)

### ✅ Do's - Testing & Deployment
- Use services for integration tests (MongoDB, Redis, etc.)
- Build only after tests pass
- Use manual triggers for production deployments
- Run migrations before deployment
- Implement health checks after deployment
- Use Docker for consistent environments
- Tag Docker images with build numbers
- Scan images for security vulnerabilities

### ❌ Don'ts - Anti-Patterns
- Don't run all tests after first failure (configure bail)
- Don't skip `HUSKY=0` prefix on `npm ci`
- Don't allow warnings in CI (use `--max-warnings=0`)
- Don't use parallel steps without `fail-fast: true`
- Don't skip E2E tests before production
- Don't run migrations without backups
- Don't deploy without health checks
- Don't use `latest` tag in production
- Don't commit environment secrets
- Don't skip type checking

## Jest Configuration for Fail-Fast

Add to `jest.config.ts` to stop tests immediately on first failure in CI:

```typescript
import type { Config } from 'jest';

const config: Config = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'src',
  testRegex: '.*\\.spec\\.ts$',
  transform: {
    '^.+\\.(t|j)s$': ['@swc/jest'],
  },
  collectCoverageFrom: ['**/*.(t|j)s'],
  coverageDirectory: '../coverage',
  testEnvironment: 'node',
  clearMocks: true,
  
  // Fail fast in CI to save pipeline minutes
  bail: process.env.CI ? 1 : undefined,
  
  // For Testcontainers - run sequentially
  // maxWorkers: 1,
  // testTimeout: 60000,
};

export default config;
```

**Alternative:** Use `maxFailures` for slightly more tolerance:
```typescript
  // Stop after 3 failures instead of 1
  maxFailures: process.env.CI ? 3 : undefined,
```

## Package.json Scripts

Recommended scripts for CI/CD with fail-fast patterns:
```json
{
  "scripts": {
    "build": "nest build",
    "build:prod": "nest build --webpack",
    "test": "jest",
    "test:cov": "jest --coverage",
    "test:e2e": "jest --config ./test/jest-e2e.json",
    "test:ci": "jest --ci --coverage --watchAll=false",
    "test:e2e:ci": "jest --ci --config ./test/jest-e2e.json",
    "lint": "eslint \"{src,apps,libs,test}/**/*.ts\" --fix",
    "lint:ci": "eslint \"{src,apps,libs,test}/**/*.ts\" --max-warnings=0",
    "typecheck": "tsc --noEmit",
    "gql:lint": "graphql-schema-linter src/**/*.graphql",
    "migration:run": "npm run typeorm migration:run",
    "migration:revert": "npm run typeorm migration:revert"
  }
}
```

**Key CI patterns:**
- `test:ci` - Uses `--ci` flag for Jest CI mode (uses jest.config bail setting)
- `lint:ci` - Uses `--max-warnings=0` to treat warnings as errors
- `typecheck` - Uses `tsc --noEmit` which fails on first type error
- `gql:lint` - GraphQL schema linting fails immediately on violations
