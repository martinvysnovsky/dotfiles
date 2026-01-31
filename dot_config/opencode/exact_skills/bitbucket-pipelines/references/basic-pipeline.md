# Basic Pipeline Configuration

Core Bitbucket Pipelines syntax, structure, and fundamental concepts.

## Key Patterns for CI

**Essential CI Patterns:**
1. ✅ **HUSKY=0 npm ci** - Always skip git hooks in CI
2. ✅ **fail-fast: true** - Stop parallel steps on first failure
3. ✅ **max-time** - Set timeouts to prevent hanging steps
4. ✅ **lint:ci** - Use `--max-warnings=0` for linting
5. ✅ **test:ci** - Configure `bail: 1` in test configs

## Pipeline Structure

### Complete Pipeline Anatomy
```yaml
# Global default image for all steps
image: node:18

# Optional: Clone behavior
clone:
  depth: full  # or 'full', default is 50
  lfs: true    # Enable Git LFS

# Definitions for reusable components
definitions:
  # Reusable steps
  steps:
    - step: &build-step
        name: Build Application
        caches:
          - node
        script:
          - npm ci
          - npm run build
        artifacts:
          - dist/**
  
  # Custom caches
  caches:
    npm: ~/.npm
  
  # Services (databases, etc.)
  services:
    mongodb:
      image: mongo:7.0

# Pipeline configurations
pipelines:
  default:
    - step: *build-step
  
  branches:
    main:
      - step: *build-step
  
  tags:
    'v*':
      - step:
          name: Release
          script:
            - echo "Release ${BITBUCKET_TAG}"
  
  pull-requests:
    '**':
      - step: *build-step
  
  custom:
    manual-deploy:
      - step:
          name: Manual Deploy
          script:
            - echo "Manual deployment"
```

## Pipeline Types

### Default Pipeline
Runs for all branches/tags without specific configuration:
```yaml
pipelines:
  default:
    - step:
        name: Default Build
        script:
          - npm ci
          - npm test
```

### Branch-Specific Pipelines
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Production Build
          script:
            - npm run build:prod
    
    develop:
      - step:
          name: Development Build
          script:
            - npm run build:dev
    
    'feature/*':
      - step:
          name: Feature Build
          script:
            - npm run build
```

### Tag Pipelines
```yaml
pipelines:
  tags:
    'v*':
      - step:
          name: Release Build
          script:
            - npm run build
            - npm run publish
    
    'release/*':
      - step:
          name: Release Candidate
          script:
            - npm run build:rc
```

### Pull Request Pipelines
```yaml
pipelines:
  pull-requests:
    '**':  # All PRs
      - step:
          name: PR Validation
          script:
            - npm run lint
            - npm run test
    
    'feature/*':  # PRs from feature branches
      - step:
          name: Feature Validation
          script:
            - npm run test:integration
```

### Custom Pipelines
Manually triggered from Bitbucket UI:
```yaml
pipelines:
  custom:
    deploy-staging:
      - step:
          name: Deploy to Staging
          script:
            - npm run deploy:staging
    
    rollback-production:
      - step:
          name: Rollback Production
          script:
            - npm run rollback
```

## Step Configuration

### Basic Step
```yaml
- step:
    name: Step Name
    image: node:18  # Optional: override global image
    script:
      - npm ci
      - npm test
```

### Step with Caches
```yaml
- step:
    name: Build with Cache
    caches:
      - node
      - npm
    script:
      - npm ci
      - npm run build
```

### Step with Artifacts
```yaml
- step:
    name: Build
    script:
      - npm run build
    artifacts:
      - dist/**
      - build/**

- step:
    name: Deploy
    script:
      - ls dist/  # Artifacts available here
```

### Step with Services
```yaml
- step:
    name: Integration Tests
    services:
      - mongodb
      - redis
    script:
      - npm run test:integration
```

### Step with Size
```yaml
- step:
    name: Heavy Build
    size: 2x  # 8GB memory, 2x build minutes
    script:
      - npm run build
```

Available sizes:
- `1x` (default): 4GB memory
- `2x`: 8GB memory (2x build minutes)
- `4x`: 16GB memory (4x build minutes)
- `8x`: 32GB memory (8x build minutes)

### Step with Image Override
```yaml
# Override global image for specific steps
image: node:18  # Global default

pipelines:
  default:
    - step:
        name: Lint with Alpine
        image: node:18-alpine  # Override for this step only
        script:
          - npm run lint
    
    - step:
        name: E2E Tests with Playwright
        image: mcr.microsoft.com/playwright:v1.56.1-noble  # Playwright image
        size: 8x
        script:
          - npm run test:e2e
    
    - step:
        name: Deploy with gcloud
        image: google/cloud-sdk:alpine  # GCP tools
        script:
          - gcloud run deploy myapp
```

### Step with Max Time
```yaml
- step:
    name: Long Running Task
    max-time: 60  # Maximum 60 minutes
    script:
      - npm run long-task
```

### Conditional Steps
```yaml
- step:
    name: Deploy
    condition:
      changesets:
        includePaths:
          - "src/**"
          - "package.json"
    script:
      - npm run deploy
```

## Parallel Steps

### Basic Parallel Execution with Fail-Fast

**ALWAYS use `fail-fast: true`** to stop all parallel steps if any fails:

```yaml
pipelines:
  default:
    - parallel:
        fail-fast: true  # Stop all steps if any fails (saves minutes!)
        steps:
          - step:
              name: Unit Tests
              max-time: 10
              script:
                - HUSKY=0 npm ci
                - npm run test:ci
          - step:
              name: Lint
              max-time: 5
              script:
                - HUSKY=0 npm ci
                - npm run lint:ci
          - step:
              name: Type Check
              max-time: 5
              script:
                - HUSKY=0 npm ci
                - npm run typecheck
```

**Why fail-fast is critical:**
- ✅ Saves 3-8 minutes per failed pipeline
- ✅ Faster feedback for developers
- ✅ Reduces pipeline minute costs
- ✅ Prevents wasted resources on doomed builds

### Mixed Parallel and Sequential
```yaml
pipelines:
  default:
    - step:
        name: Install
        caches:
          - node
        script:
          - HUSKY=0 npm ci
        artifacts:
          - node_modules/**
    
    - parallel:
        fail-fast: true  # Always include fail-fast
        steps:
          - step:
              name: Unit Tests
              max-time: 10
              script:
                - npm run test:ci
          - step:
              name: E2E Tests
              max-time: 30
              script:
                - npm run test:e2e:ci
    
    - step:
        name: Deploy
        max-time: 10
        script:
          - npm run deploy
```

## Variables

### Built-in Variables
```yaml
- step:
    name: Show Variables
    script:
      - echo "Branch: $BITBUCKET_BRANCH"
      - echo "Commit: $BITBUCKET_COMMIT"
      - echo "Repo: $BITBUCKET_REPO_SLUG"
      - echo "Tag: $BITBUCKET_TAG"
      - echo "PR ID: $BITBUCKET_PR_ID"
      - echo "Build Number: $BITBUCKET_BUILD_NUMBER"
```

Common built-in variables:
- `BITBUCKET_BRANCH` - Current branch name
- `BITBUCKET_COMMIT` - Commit hash
- `BITBUCKET_REPO_SLUG` - Repository name
- `BITBUCKET_REPO_FULL_NAME` - workspace/repo-name
- `BITBUCKET_TAG` - Tag name (if triggered by tag)
- `BITBUCKET_BUILD_NUMBER` - Build number
- `BITBUCKET_CLONE_DIR` - Clone directory path
- `BITBUCKET_PR_ID` - Pull request ID

### Custom Variables
Set in step:
```yaml
- step:
    name: Use Variables
    script:
      - export APP_VERSION="1.0.0"
      - echo "Version: $APP_VERSION"
```

### Repository Variables
Set in Bitbucket UI (Repository Settings → Pipelines → Repository variables):
```yaml
- step:
    name: Use Repo Variables
    script:
      - echo "API URL: $API_URL"
      - echo "Environment: $ENVIRONMENT"
```

### Secured Variables
For sensitive data (marked as "Secured" in UI):
```yaml
- step:
    name: Deploy
    script:
      - echo "Using API_KEY (value hidden)"
      - curl -H "Authorization: Bearer $API_KEY" $API_URL
```

## Services

### MongoDB
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
        services:
          - mongodb
        script:
          - npm run test:e2e
        environment:
          DB_CONNECTION: mongodb://localhost:27017/test
```

### PostgreSQL
```yaml
definitions:
  services:
    postgres:
      image: postgres:15
      environment:
        POSTGRES_DB: test
        POSTGRES_USER: testuser
        POSTGRES_PASSWORD: testpass

pipelines:
  default:
    - step:
        services:
          - postgres
        script:
          - npm run test:e2e
        environment:
          DATABASE_URL: postgresql://testuser:testpass@localhost:5432/test
```

### Redis
```yaml
definitions:
  services:
    redis:
      image: redis:7-alpine

pipelines:
  default:
    - step:
        services:
          - redis
        script:
          - npm run test:integration
        environment:
          REDIS_URL: redis://localhost:6379
```

### Docker (Docker-in-Docker)
```yaml
definitions:
  services:
    docker:
      memory: 2048

pipelines:
  default:
    - step:
        services:
          - docker
        script:
          - docker build -t myapp .
          - docker push myapp
```

## Node.js Pipeline

### Complete Example
```yaml
image: node:18

definitions:
  caches:
    npm: ~/.npm
  
  steps:
    - step: &install
        name: Install Dependencies
        caches:
          - node
        script:
          - npm ci
        artifacts:
          - node_modules/**
    
    - step: &test
        name: Run Tests
        script:
          - npm run test:ci
        artifacts:
          - coverage/**
    
    - step: &build
        name: Build Application
        script:
          - npm run build
        artifacts:
          - dist/**

pipelines:
  default:
    - step: *install
    - parallel:
        - step: *test
        - step:
            name: Lint
            script:
              - npm run lint
    - step: *build
  
  branches:
    main:
      - step: *install
      - step: *test
      - step: *build
      - step:
          name: Deploy Production
          deployment: production
          script:
            - npm run deploy:prod
  
  pull-requests:
    '**':
      - step: *install
      - parallel:
          - step: *test
          - step:
              name: Lint
              script:
                - npm run lint
          - step:
              name: Type Check
              script:
                - npm run type-check
```

## Triggers

### Automatic Triggers
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Auto Deploy
          trigger: automatic  # default
          script:
            - npm run deploy
```

### Manual Triggers
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build
          script:
            - npm run build
      
      - step:
          name: Deploy
          trigger: manual  # Requires manual approval
          script:
            - npm run deploy
```

## Clone Behavior

### Depth Control
```yaml
clone:
  depth: 50  # Last 50 commits (default)
  # depth: full  # Full history
```

### Git LFS
```yaml
clone:
  lfs: true
```

### Disable Clone
```yaml
pipelines:
  default:
    - step:
        name: No Clone Needed
        clone:
          enabled: false
        script:
          - echo "No repository clone"
```

## Bitbucket Pipes

Pipes are pre-built integrations that simplify common CI/CD tasks.

### Available Pipes

**Deployment Pipes:**
- `atlassian/firebase-deploy` - Deploy to Firebase Hosting
- `atlassian/aws-s3-deploy` - Deploy to AWS S3
- `atlassian/aws-ecr-push-image` - Push to AWS ECR
- `atlassian/heroku-deploy` - Deploy to Heroku

**Testing & Security:**
- `aquasecurity/trivy-pipe` - Security scanning
- `snyk/snyk-scan` - Vulnerability scanning
- `atlassian/sonarqube-scan` - Code quality analysis

**Utilities:**
- `atlassian/slack-notify` - Send Slack notifications
- `atlassian/email-notify` - Send email notifications

### Using Pipes

#### Firebase Deploy Pipe
```yaml
- step:
    name: Deploy to Firebase
    script:
      - npm run build
      - pipe: atlassian/firebase-deploy:5.1.1
        variables:
          KEY_FILE: $GOOGLE_SERVICE_ACCOUNT_KEY
          PROJECT_ID: $GOOGLE_PROJECT_ID
          DIST_FOLDER: "dist"
          EXTRA_ARGS: "--only hosting"
```

#### AWS S3 Deploy Pipe
```yaml
- step:
    name: Deploy to S3
    script:
      - npm run build
      - pipe: atlassian/aws-s3-deploy:1.1.0
        variables:
          AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
          AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
          AWS_DEFAULT_REGION: $AWS_REGION
          S3_BUCKET: $S3_BUCKET_NAME
          LOCAL_PATH: "dist"
```

#### Trivy Security Scan Pipe
```yaml
- step:
    name: Security Scan
    services:
      - docker
    script:
      - docker build -t myapp:latest .
      - pipe: aquasecurity/trivy-pipe:1.0.0
        variables:
          IMAGE_NAME: myapp:latest
          SEVERITY: HIGH,CRITICAL
          EXIT_CODE: '1'  # Fail build on vulnerabilities
```

#### Slack Notification Pipe
```yaml
- step:
    name: Deploy
    script:
      - npm run deploy
      - pipe: atlassian/slack-notify:2.1.0
        variables:
          WEBHOOK_URL: $SLACK_WEBHOOK_URL
          MESSAGE: "Deployment completed: Build #${BITBUCKET_BUILD_NUMBER}"
```

#### Multi-Site Firebase Deploy
```yaml
- step:
    name: Deploy Multiple Sites
    script:
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

## Common CI Patterns

### HUSKY Git Hooks
Disable Husky git hooks in CI environments:
```yaml
- step:
    script:
      # Disable Husky to skip git hooks
      - HUSKY=0 npm ci
      - npm run build
```

### Install Without Scripts
Skip postinstall scripts when not needed:
```yaml
- step:
    script:
      # Faster install when postinstall not needed
      - npm ci --ignore-scripts
      - npm run lint
```

### Fail-Fast Parallel Steps
Stop all parallel steps if one fails:
```yaml
- parallel:
    fail-fast: true
    steps:
      - step:
          name: Lint
          script:
            - npm run lint
      - step:
          name: Test
          script:
            - npm run test
```

## Best Practices

### ✅ Do's
- Use step anchors to avoid duplication
- Cache dependencies (`node_modules`, `.npm`)
- Use parallel steps for independent tasks
- Set appropriate step sizes for resource-intensive tasks
- Use artifacts to pass files between steps
- Leverage built-in variables

### ❌ Don'ts
- Don't commit secrets to YAML files
- Don't run all tests on every branch
- Don't use overly broad branch patterns
- Don't skip CI on main/production branches
- Don't use heavy base images when lighter alternatives exist

## Debugging

### Enable Debug Logging
```yaml
- step:
    name: Debug Step
    script:
      - set -x  # Enable verbose output
      - npm run build
```

### List Environment
```yaml
- step:
    name: Show Environment
    script:
      - env | sort
      - pwd
      - ls -la
```

### Check Service Connectivity
```yaml
- step:
    name: Test Database
    services:
      - mongodb
    script:
      - apt-get update && apt-get install -y netcat
      - nc -zv localhost 27017
```
