# Google Cloud Platform Deployment

Deploy to Google Cloud Run, Artifact Registry, and other GCP services.

## Prerequisites

### Required Environment Variables
```yaml
# Set in Bitbucket Repository Settings → Deployments → Variables
GOOGLE_SERVICE_ACCOUNT_KEY   # Base64-encoded service account JSON key
GOOGLE_PROJECT_ID             # GCP project ID
GOOGLE_REGION                 # GCP region (e.g., europe-west1)
ARTIFACT_REGISTRY_REPOSITORY  # Artifact Registry repository name
CLOUD_RUN_SERVICE_NAME        # Cloud Run service name
```

### Service Account Permissions
Required IAM roles:
- `roles/run.admin` - Deploy to Cloud Run
- `roles/iam.serviceAccountUser` - Act as service account
- `roles/artifactregistry.writer` - Push to Artifact Registry
- `roles/storage.admin` - (Optional) Cloud Storage access

## Cloud Run Deployment

### Basic Cloud Run Pipeline
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
  branches:
    main:
      - step:
          name: Deploy to Cloud Run
          deployment: production
          services:
            - docker
          caches:
            - docker
            - gcloud
          script:
            # Early validation - fail fast before expensive operations
            - |
              if [ -z "$GOOGLE_SERVICE_ACCOUNT_KEY" ]; then
                echo "Error: GOOGLE_SERVICE_ACCOUNT_KEY not set"
                exit 1
              fi
            - |
              if [ -z "$GOOGLE_PROJECT_ID" ]; then
                echo "Error: GOOGLE_PROJECT_ID not set"
                exit 1
              fi
            
            # Authenticate
            - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
            - gcloud auth activate-service-account --key-file gcloud-service-key.json
            - gcloud config set project $GOOGLE_PROJECT_ID
            - gcloud auth configure-docker $GOOGLE_REGION-docker.pkg.dev --quiet
            
            # Build and push
            - export IMAGE_NAME="$GOOGLE_REGION-docker.pkg.dev/$GOOGLE_PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY/app:$BITBUCKET_BUILD_NUMBER"
            - docker build -t $IMAGE_NAME .
            - docker push $IMAGE_NAME
            
            # Deploy
            - gcloud run deploy $CLOUD_RUN_SERVICE_NAME --image=$IMAGE_NAME --region=$GOOGLE_REGION --quiet
            
            # Cleanup
            - rm gcloud-service-key.json
```

### Production-Ready Cloud Run Pipeline
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
  branches:
    main:
      - step:
          name: Test
          image: node:18
          caches:
            - node
          services:
            - docker
          script:
            - npm ci
            - npm run test:ci
            - npm run test:e2e:ci
      
      - step:
          name: Deploy to Cloud Run
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
            - export IMAGE_LATEST="$GOOGLE_REGION-docker.pkg.dev/$GOOGLE_PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY/app:latest"
            
            # Authenticate
            - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
            - gcloud auth activate-service-account --key-file gcloud-service-key.json
            - gcloud config set project $GOOGLE_PROJECT_ID
            - gcloud auth configure-docker $GOOGLE_REGION-docker.pkg.dev --quiet
            
            # Build with BuildKit
            - export DOCKER_BUILDKIT=1
            - docker build --build-arg BUILDKIT_INLINE_CACHE=1 -t $IMAGE_VERSIONED .
            
            # Tag as latest
            - docker tag $IMAGE_VERSIONED $IMAGE_LATEST
            
            # Push images
            - docker push $IMAGE_VERSIONED
            - docker push $IMAGE_LATEST
            
            # Deploy to Cloud Run
            - gcloud run deploy $CLOUD_RUN_SERVICE_NAME --image=$IMAGE_VERSIONED --region=$GOOGLE_REGION --quiet
            
            # Cleanup
            - rm gcloud-service-key.json
            - docker system prune -f
```

## Multi-Environment Deployment

### Staging and Production
```yaml
image: google/cloud-sdk:alpine

definitions:
  services:
    docker:
      memory: 3072
  caches:
    gcloud: ~/.cache/gcloud

pipelines:
  branches:
    develop:
      - step:
          name: Deploy to Staging
          deployment: staging
          services:
            - docker
          caches:
            - gcloud
            - docker
          script:
            - export IMAGE_NAME="$GOOGLE_REGION-docker.pkg.dev/$GOOGLE_PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY/app:staging-$BITBUCKET_BUILD_NUMBER"
            - echo $GOOGLE_SERVICE_ACCOUNT_KEY_STAGING | base64 -d > gcloud-service-key.json
            - gcloud auth activate-service-account --key-file gcloud-service-key.json
            - gcloud config set project $GOOGLE_PROJECT_ID_STAGING
            - gcloud auth configure-docker $GOOGLE_REGION-docker.pkg.dev --quiet
            - docker build -t $IMAGE_NAME .
            - docker push $IMAGE_NAME
            - gcloud run deploy $CLOUD_RUN_SERVICE_NAME_STAGING --image=$IMAGE_NAME --region=$GOOGLE_REGION --quiet
            - rm gcloud-service-key.json
    
    main:
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          services:
            - docker
          caches:
            - gcloud
            - docker
          script:
            - export IMAGE_NAME="$GOOGLE_REGION-docker.pkg.dev/$GOOGLE_PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY/app:$BITBUCKET_BUILD_NUMBER"
            - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
            - gcloud auth activate-service-account --key-file gcloud-service-key.json
            - gcloud config set project $GOOGLE_PROJECT_ID
            - gcloud auth configure-docker $GOOGLE_REGION-docker.pkg.dev --quiet
            - docker build -t $IMAGE_NAME .
            - docker push $IMAGE_NAME
            - gcloud run deploy $CLOUD_RUN_SERVICE_NAME --image=$IMAGE_NAME --region=$GOOGLE_REGION --quiet
            - rm gcloud-service-key.json
```

## Advanced Cloud Run Configuration

### Deploy with Environment Variables
```yaml
- step:
    name: Deploy with Config
    deployment: production
    script:
      - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
      - gcloud auth activate-service-account --key-file gcloud-service-key.json
      - gcloud config set project $GOOGLE_PROJECT_ID
      - gcloud auth configure-docker $GOOGLE_REGION-docker.pkg.dev --quiet
      - export IMAGE_NAME="$GOOGLE_REGION-docker.pkg.dev/$GOOGLE_PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY/app:$BITBUCKET_BUILD_NUMBER"
      - docker build -t $IMAGE_NAME .
      - docker push $IMAGE_NAME
      - >
        gcloud run deploy $CLOUD_RUN_SERVICE_NAME
        --image=$IMAGE_NAME
        --region=$GOOGLE_REGION
        --platform=managed
        --allow-unauthenticated
        --set-env-vars="NODE_ENV=production,LOG_LEVEL=info"
        --memory=512Mi
        --cpu=1
        --min-instances=0
        --max-instances=10
        --timeout=300
        --quiet
      - rm gcloud-service-key.json
```

### Deploy with Secrets from Secret Manager
```yaml
- step:
    name: Deploy with Secrets
    deployment: production
    script:
      - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
      - gcloud auth activate-service-account --key-file gcloud-service-key.json
      - gcloud config set project $GOOGLE_PROJECT_ID
      - gcloud auth configure-docker $GOOGLE_REGION-docker.pkg.dev --quiet
      - export IMAGE_NAME="$GOOGLE_REGION-docker.pkg.dev/$GOOGLE_PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY/app:$BITBUCKET_BUILD_NUMBER"
      - docker build -t $IMAGE_NAME .
      - docker push $IMAGE_NAME
      - >
        gcloud run deploy $CLOUD_RUN_SERVICE_NAME
        --image=$IMAGE_NAME
        --region=$GOOGLE_REGION
        --set-secrets="DATABASE_URL=database-url:latest,API_KEY=api-key:latest"
        --quiet
      - rm gcloud-service-key.json
```

## Artifact Registry

### Push to Artifact Registry
```yaml
- step:
    name: Push to Artifact Registry
    services:
      - docker
    script:
      - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
      - gcloud auth activate-service-account --key-file gcloud-service-key.json
      - gcloud config set project $GOOGLE_PROJECT_ID
      - gcloud auth configure-docker $GOOGLE_REGION-docker.pkg.dev --quiet
      
      # Build and push
      - export IMAGE_NAME="$GOOGLE_REGION-docker.pkg.dev/$GOOGLE_PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY/app"
      - docker build -t $IMAGE_NAME:$BITBUCKET_BUILD_NUMBER -t $IMAGE_NAME:latest .
      - docker push $IMAGE_NAME:$BITBUCKET_BUILD_NUMBER
      - docker push $IMAGE_NAME:latest
      
      - rm gcloud-service-key.json
```

### Multi-Region Push
```yaml
- step:
    name: Push to Multiple Regions
    services:
      - docker
    script:
      - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
      - gcloud auth activate-service-account --key-file gcloud-service-key.json
      - gcloud config set project $GOOGLE_PROJECT_ID
      
      # Configure Docker for multiple regions
      - gcloud auth configure-docker europe-west1-docker.pkg.dev --quiet
      - gcloud auth configure-docker us-central1-docker.pkg.dev --quiet
      
      # Build once
      - docker build -t myapp:$BITBUCKET_BUILD_NUMBER .
      
      # Tag and push to EU
      - docker tag myapp:$BITBUCKET_BUILD_NUMBER europe-west1-docker.pkg.dev/$GOOGLE_PROJECT_ID/repo/app:$BITBUCKET_BUILD_NUMBER
      - docker push europe-west1-docker.pkg.dev/$GOOGLE_PROJECT_ID/repo/app:$BITBUCKET_BUILD_NUMBER
      
      # Tag and push to US
      - docker tag myapp:$BITBUCKET_BUILD_NUMBER us-central1-docker.pkg.dev/$GOOGLE_PROJECT_ID/repo/app:$BITBUCKET_BUILD_NUMBER
      - docker push us-central1-docker.pkg.dev/$GOOGLE_PROJECT_ID/repo/app:$BITBUCKET_BUILD_NUMBER
      
      - rm gcloud-service-key.json
```

## Cloud Storage Deployment

### Deploy Static Site to Cloud Storage
```yaml
- step:
    name: Deploy to Cloud Storage
    deployment: production
    script:
      - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
      - gcloud auth activate-service-account --key-file gcloud-service-key.json
      - gcloud config set project $GOOGLE_PROJECT_ID
      
      # Build static site
      - npm ci
      - npm run build
      
      # Upload to Cloud Storage
      - gsutil -m rsync -r -d ./dist gs://$GCS_BUCKET_NAME
      
      # Set cache control
      - gsutil -m setmeta -h "Cache-Control:public, max-age=3600" gs://$GCS_BUCKET_NAME/**/*.html
      - gsutil -m setmeta -h "Cache-Control:public, max-age=31536000" gs://$GCS_BUCKET_NAME/**/*.{js,css,png,jpg,svg}
      
      - rm gcloud-service-key.json
```

## Complete NestJS + GCP Pipeline

### Real-World Example
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
  branches:
    main:
      # Test first with Node image
      - parallel:
          fail-fast: true
          steps:
            - step:
                name: Lint and Typecheck
                image: node:18
                caches:
                  - node
                script:
                  - npm ci
                  - npm run lint:ci
                  - npm run typecheck
            
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
                  - npm ci
                  - npm run test:ci
                  - npm run test:e2e:ci
      
      # Deploy to staging automatically
      - step:
          name: Deploy to Staging
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
            - export IMAGE_VERSIONED="$GOOGLE_REGION-docker.pkg.dev/$GOOGLE_PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY/app:$BITBUCKET_BUILD_NUMBER"
            
            # Authenticate
            - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
            - gcloud auth activate-service-account --key-file gcloud-service-key.json
            - gcloud config set project $GOOGLE_PROJECT_ID
            - gcloud auth configure-docker $GOOGLE_REGION-docker.pkg.dev --quiet
            
            # Build with BuildKit
            - export DOCKER_BUILDKIT=1
            - docker build --build-arg BUILDKIT_INLINE_CACHE=1 --build-arg ENVIRONMENT=staging -t $IMAGE_VERSIONED .
            
            # Push image
            - docker push $IMAGE_VERSIONED
            
            # Deploy to Cloud Run
            - gcloud run deploy $CLOUD_RUN_SERVICE_NAME --image=$IMAGE_VERSIONED --region=$GOOGLE_REGION --quiet
            
            # Cleanup
            - rm gcloud-service-key.json
            - docker system prune -f
      
      # Deploy to production manually
      - step:
          name: Deploy to Production
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
            - export IMAGE_VERSIONED="$GOOGLE_REGION-docker.pkg.dev/$GOOGLE_PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY/app:$BITBUCKET_BUILD_NUMBER"
            
            # Authenticate
            - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
            - gcloud auth activate-service-account --key-file gcloud-service-key.json
            - gcloud config set project $GOOGLE_PROJECT_ID
            - gcloud auth configure-docker $GOOGLE_REGION-docker.pkg.dev --quiet
            
            # Build with BuildKit
            - export DOCKER_BUILDKIT=1
            - docker build --build-arg BUILDKIT_INLINE_CACHE=1 --build-arg ENVIRONMENT=production -t $IMAGE_VERSIONED .
            
            # Push image
            - docker push $IMAGE_VERSIONED
            
            # Deploy to Cloud Run
            - gcloud run deploy $CLOUD_RUN_SERVICE_NAME --image=$IMAGE_VERSIONED --region=$GOOGLE_REGION --quiet
            
            # Cleanup
            - rm gcloud-service-key.json
```

## Best Practices

### ✅ Do's
- Use base64-encoded service account keys
- Always clean up service account key files
- Use BuildKit for faster builds
- Tag images with build numbers
- Use `--quiet` flag for non-interactive deployments
- Cache gcloud and Docker layers
- Set appropriate memory for Docker service (3GB+)
- Use manual triggers for production

### ❌ Don'ts
- Don't commit service account keys
- Don't use `latest` tag for production
- Don't skip authentication cleanup
- Don't deploy without tests passing
- Don't use small Docker service memory (<2GB)
- Don't forget to configure Docker authentication

## Troubleshooting

### Authentication Issues
```yaml
- step:
    script:
      # Debug authentication
      - echo $GOOGLE_SERVICE_ACCOUNT_KEY | base64 -d > gcloud-service-key.json
      - gcloud auth activate-service-account --key-file gcloud-service-key.json
      - gcloud config set project $GOOGLE_PROJECT_ID
      - gcloud auth list
      - gcloud config list
```

### Docker Push Failures
```yaml
- step:
    script:
      # Verify Docker configuration
      - gcloud auth configure-docker $GOOGLE_REGION-docker.pkg.dev --quiet
      - docker info
      - docker push $IMAGE_NAME -v
```

### Service Account Key Issues
```bash
# Generate base64-encoded key locally
base64 -w 0 service-account-key.json > encoded-key.txt

# Or on macOS
base64 -i service-account-key.json -o encoded-key.txt
```
