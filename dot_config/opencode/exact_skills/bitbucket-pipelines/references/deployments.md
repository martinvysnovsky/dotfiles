# Deployment Patterns

Environment-specific deployments, deployment variables, and release strategies.

## Deployment Environments

Bitbucket provides named deployment environments that track deployment history.

### Basic Deployment
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy to Production
          deployment: production
          script:
            - npm run deploy
```

### Available Environment Names
- `test`
- `staging`
- `production`

Custom environment names are also supported.

## Multi-Environment Deployment

### Development, Staging, Production
```yaml
pipelines:
  branches:
    develop:
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
          name: Deploy to Development
          deployment: development
          script:
            - npm run deploy:dev
    
    staging:
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
          name: Deploy to Staging
          deployment: staging
          script:
            - npm run deploy:staging
    
    main:
      - step:
          name: Build
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
          trigger: manual  # Requires manual approval
          script:
            - npm run deploy:prod
```

## Deployment Variables

### Environment-Specific Variables
Set in Bitbucket UI: Repository Settings → Deployments → [Environment] → Variables

```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy to Production
          deployment: production
          script:
            - echo "Deploying to $API_URL"
            - echo "Region: $AWS_REGION"
            - npm run deploy
```

Variables are scoped to specific deployment environments.

### Secured Deployment Variables
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy
          deployment: production
          script:
            # These variables are only available in production deployment
            - echo "Using production API_KEY (value hidden)"
            - echo "Database: $DB_CONNECTION_STRING"
            - npm run deploy
```

## Manual vs Automatic Deployments

### Automatic Deployment
```yaml
pipelines:
  branches:
    develop:
      - step:
          name: Deploy to Dev
          deployment: development
          trigger: automatic  # Default behavior
          script:
            - npm run deploy:dev
```

### Manual Deployment (Requires Approval)
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build
          script:
            - npm run build
      
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual  # Manual approval required
          script:
            - npm run deploy:prod
```

### Conditional Manual Deployment
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy to Staging
          deployment: staging
          trigger: automatic
          script:
            - npm run deploy:staging
      
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - npm run deploy:prod
```

## Deployment Strategies

### Blue-Green Deployment
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build
          script:
            - npm run build
          artifacts:
            - dist/**
      
      - step:
          name: Deploy to Green Environment
          deployment: production-green
          script:
            - npm run deploy:green
            - npm run health-check:green
      
      - step:
          name: Switch Traffic to Green
          deployment: production
          trigger: manual
          script:
            - npm run switch-traffic:green
            - npm run health-check:production
      
      - step:
          name: Decommission Blue
          trigger: manual
          script:
            - npm run cleanup:blue
```

### Canary Deployment
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build
          script:
            - npm run build
          artifacts:
            - dist/**
      
      - step:
          name: Deploy Canary (5%)
          deployment: production-canary
          script:
            - npm run deploy:canary --percent=5
      
      - step:
          name: Monitor Canary
          trigger: manual
          script:
            - npm run monitor:canary
      
      - step:
          name: Roll Out to 50%
          deployment: production-canary
          trigger: manual
          script:
            - npm run deploy:canary --percent=50
      
      - step:
          name: Complete Rollout
          deployment: production
          trigger: manual
          script:
            - npm run deploy:production --percent=100
```

### Rolling Deployment
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build
          script:
            - npm run build
          artifacts:
            - dist/**
      
      - step:
          name: Deploy Rolling Update
          deployment: production
          script:
            - for i in 1 2 3 4; do
            -   npm run deploy:instance-$i
            -   npm run health-check:instance-$i
            -   sleep 30
            - done
```

## Rollback Strategies

### Automated Rollback on Failure
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy
          deployment: production
          script:
            - npm run deploy:prod || npm run rollback:prod
            - npm run health-check || npm run rollback:prod
```

### Manual Rollback Pipeline
```yaml
pipelines:
  custom:
    rollback-production:
      - variables:
          - name: VERSION
      - step:
          name: Rollback to Version
          deployment: production
          script:
            - echo "Rolling back to version $VERSION"
            - npm run rollback:prod --version=$VERSION
            - npm run health-check:prod
```

### Quick Rollback
```yaml
pipelines:
  custom:
    emergency-rollback:
      - step:
          name: Emergency Rollback
          deployment: production
          script:
            - npm run rollback:last-stable
            - npm run health-check:prod
            - npm run notify:team "Emergency rollback executed"
```

## Health Checks and Validation

### Post-Deployment Validation
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy
          deployment: production
          script:
            - npm run deploy:prod
      
      - step:
          name: Validate Deployment
          script:
            - npm run health-check:prod
            - npm run smoke-test:prod
            - npm run integration-test:prod
```

### Health Check with Retry
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy and Verify
          deployment: production
          script:
            - npm run deploy:prod
            - |
              for i in {1..10}; do
                if npm run health-check:prod; then
                  echo "Health check passed"
                  exit 0
                fi
                echo "Attempt $i failed, retrying..."
                sleep 10
              done
              echo "Health check failed after 10 attempts"
              npm run rollback:prod
              exit 1
```

## Multi-Region Deployment

### Sequential Regional Deployment
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build
          script:
            - npm run build
          artifacts:
            - dist/**
      
      - step:
          name: Deploy to EU
          deployment: production-eu
          script:
            - npm run deploy:eu
            - npm run health-check:eu
      
      - step:
          name: Deploy to US
          deployment: production-us
          trigger: manual
          script:
            - npm run deploy:us
            - npm run health-check:us
      
      - step:
          name: Deploy to APAC
          deployment: production-apac
          trigger: manual
          script:
            - npm run deploy:apac
            - npm run health-check:apac
```

### Parallel Regional Deployment
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build
          script:
            - npm run build
          artifacts:
            - dist/**
      
      - parallel:
          - step:
              name: Deploy to EU
              deployment: production-eu
              script:
                - npm run deploy:eu
                - npm run health-check:eu
          
          - step:
              name: Deploy to US
              deployment: production-us
              script:
                - npm run deploy:us
                - npm run health-check:us
          
          - step:
              name: Deploy to APAC
              deployment: production-apac
              script:
                - npm run deploy:apac
                - npm run health-check:apac
```

## Deployment with Notifications

### Slack Notifications
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy to Production
          deployment: production
          script:
            - npm run deploy:prod
            - |
              curl -X POST $SLACK_WEBHOOK_URL \
                -H 'Content-Type: application/json' \
                -d "{\"text\":\"🚀 Deployed to production: Build #${BITBUCKET_BUILD_NUMBER}\"}"
      
      after-script:
        - |
          if [ $BITBUCKET_EXIT_CODE -ne 0 ]; then
            curl -X POST $SLACK_WEBHOOK_URL \
              -H 'Content-Type: application/json' \
              -d "{\"text\":\"❌ Production deployment failed: Build #${BITBUCKET_BUILD_NUMBER}\"}"
          fi
```

### Email Notifications
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy
          deployment: production
          script:
            - npm run deploy:prod
            - npm run notify:email "Deployment successful"
      
      after-script:
        - if [ $BITBUCKET_EXIT_CODE -ne 0 ]; then npm run notify:email "Deployment failed"; fi
```

## Tag-Based Releases

### Semantic Versioning Releases
```yaml
pipelines:
  tags:
    'v*.*.*':
      - step:
          name: Build Release
          script:
            - npm ci
            - npm run build
            - npm run test
          artifacts:
            - dist/**
      
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - echo "Deploying version ${BITBUCKET_TAG}"
            - npm run deploy:prod --version=${BITBUCKET_TAG}
```

### Release Candidates
```yaml
pipelines:
  tags:
    'v*.*.*-rc*':
      - step:
          name: Build RC
          script:
            - npm run build
          artifacts:
            - dist/**
      
      - step:
          name: Deploy to Staging
          deployment: staging
          script:
            - npm run deploy:staging --version=${BITBUCKET_TAG}
    
    'v*.*.*':
      - step:
          name: Build Release
          script:
            - npm run build
          artifacts:
            - dist/**
      
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - npm run deploy:prod --version=${BITBUCKET_TAG}
```

## Custom Deployment Pipelines

### Deploy Specific Commit
```yaml
pipelines:
  custom:
    deploy-commit:
      - variables:
          - name: COMMIT_SHA
          - name: ENVIRONMENT
            default: staging
            allowed-values:
              - staging
              - production
      
      - step:
          name: Deploy Commit
          deployment: $ENVIRONMENT
          script:
            - git checkout $COMMIT_SHA
            - npm ci
            - npm run build
            - npm run deploy:$ENVIRONMENT
```

### Hotfix Deployment
```yaml
pipelines:
  custom:
    hotfix-deploy:
      - step:
          name: Build Hotfix
          script:
            - npm ci
            - npm run build
            - npm run test
          artifacts:
            - dist/**
      
      - step:
          name: Deploy Hotfix to Production
          deployment: production
          script:
            - echo "Deploying hotfix from ${BITBUCKET_BRANCH}"
            - npm run deploy:prod:hotfix
            - npm run health-check:prod
```

## Best Practices

### ✅ Do's
- Use manual triggers for production deployments
- Implement health checks after deployment
- Use deployment-specific environment variables
- Track deployments with named environments
- Implement rollback strategies
- Add post-deployment validation
- Use notifications for deployment status

### ❌ Don'ts
- Don't auto-deploy to production without validation
- Don't skip health checks
- Don't use same variables across all environments
- Don't deploy without build artifacts
- Don't forget rollback procedures
- Don't ignore deployment failures

## Deployment Checklist

Before deploying to production:
- [ ] All tests passing
- [ ] Build artifacts created
- [ ] Environment variables configured
- [ ] Health check endpoints ready
- [ ] Rollback plan in place
- [ ] Team notified
- [ ] Monitoring enabled
- [ ] Database migrations tested
