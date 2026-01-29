# Docker Workflows

Docker image building, multi-stage builds, registry authentication, and container optimization.

## Basic Docker Build

### Simple Docker Build
```yaml
image: atlassian/default-image:3

definitions:
  services:
    docker:
      memory: 2048

pipelines:
  default:
    - step:
        name: Build Docker Image
        services:
          - docker
        script:
          - docker build -t myapp:${BITBUCKET_BUILD_NUMBER} .
```

### Build and Tag
```yaml
pipelines:
  default:
    - step:
        name: Build and Tag
        services:
          - docker
        script:
          - export IMAGE_NAME=myapp
          - export IMAGE_TAG=${BITBUCKET_BUILD_NUMBER}
          - docker build -t $IMAGE_NAME:$IMAGE_TAG .
          - docker tag $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:latest
```

## Docker Registry Authentication

### Docker Hub
```yaml
pipelines:
  default:
    - step:
        name: Build and Push to Docker Hub
        services:
          - docker
        script:
          - echo $DOCKER_HUB_PASSWORD | docker login -u $DOCKER_HUB_USERNAME --password-stdin
          - docker build -t $DOCKER_HUB_USERNAME/myapp:${BITBUCKET_BUILD_NUMBER} .
          - docker push $DOCKER_HUB_USERNAME/myapp:${BITBUCKET_BUILD_NUMBER}
```

### Amazon ECR
```yaml
pipelines:
  default:
    - step:
        name: Push to ECR
        services:
          - docker
        script:
          - pipe: atlassian/aws-ecr-push-image:2.0.0
            variables:
              AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
              AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
              AWS_DEFAULT_REGION: $AWS_REGION
              IMAGE_NAME: myapp
              TAGS: ${BITBUCKET_BUILD_NUMBER} latest
```

### Google Container Registry (GCR)
```yaml
pipelines:
  default:
    - step:
        name: Push to GCR
        services:
          - docker
        script:
          - echo $GCP_SERVICE_ACCOUNT_KEY | docker login -u _json_key --password-stdin https://gcr.io
          - docker build -t gcr.io/$GCP_PROJECT_ID/myapp:${BITBUCKET_BUILD_NUMBER} .
          - docker push gcr.io/$GCP_PROJECT_ID/myapp:${BITBUCKET_BUILD_NUMBER}
```

### Azure Container Registry (ACR)
```yaml
pipelines:
  default:
    - step:
        name: Push to ACR
        services:
          - docker
        script:
          - echo $ACR_PASSWORD | docker login $ACR_REGISTRY -u $ACR_USERNAME --password-stdin
          - docker build -t $ACR_REGISTRY/myapp:${BITBUCKET_BUILD_NUMBER} .
          - docker push $ACR_REGISTRY/myapp:${BITBUCKET_BUILD_NUMBER}
```

### Private Registry
```yaml
pipelines:
  default:
    - step:
        name: Push to Private Registry
        services:
          - docker
        script:
          - echo $REGISTRY_PASSWORD | docker login $REGISTRY_URL -u $REGISTRY_USERNAME --password-stdin
          - docker build -t $REGISTRY_URL/myapp:${BITBUCKET_BUILD_NUMBER} .
          - docker push $REGISTRY_URL/myapp:${BITBUCKET_BUILD_NUMBER}
```

## Multi-Stage Builds

### Node.js Multi-Stage Build
```dockerfile
# Dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine AS production
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/main.js"]
```

```yaml
# bitbucket-pipelines.yml
pipelines:
  default:
    - step:
        name: Build Multi-Stage Image
        services:
          - docker
        script:
          - docker build -t myapp:${BITBUCKET_BUILD_NUMBER} .
          - docker push myapp:${BITBUCKET_BUILD_NUMBER}
```

### Build with Build Arguments
```yaml
pipelines:
  default:
    - step:
        name: Build with Args
        services:
          - docker
        script:
          - docker build 
            --build-arg NODE_ENV=production 
            --build-arg APP_VERSION=${BITBUCKET_BUILD_NUMBER}
            -t myapp:${BITBUCKET_BUILD_NUMBER} .
```

## Docker Compose

### Testing with Docker Compose
```yaml
# docker-compose.test.yml
version: '3.8'
services:
  app:
    build: .
    environment:
      - NODE_ENV=test
      - DB_HOST=mongodb
    depends_on:
      - mongodb
  
  mongodb:
    image: mongo:7.0
    environment:
      - MONGO_INITDB_DATABASE=test
```

```yaml
# bitbucket-pipelines.yml
pipelines:
  default:
    - step:
        name: Test with Docker Compose
        services:
          - docker
        script:
          - docker-compose -f docker-compose.test.yml up --abort-on-container-exit
          - docker-compose -f docker-compose.test.yml down
```

## Docker Layer Caching

### Enable Docker Caching
```yaml
definitions:
  services:
    docker:
      memory: 2048

pipelines:
  default:
    - step:
        name: Build with Cache
        services:
          - docker
        caches:
          - docker
        script:
          - docker build -t myapp:${BITBUCKET_BUILD_NUMBER} .
```

### BuildKit for Advanced Caching
```yaml
pipelines:
  default:
    - step:
        name: Build with BuildKit
        services:
          - docker
        script:
          - export DOCKER_BUILDKIT=1
          - docker build 
            --cache-from myapp:latest 
            --build-arg BUILDKIT_INLINE_CACHE=1 
            -t myapp:${BITBUCKET_BUILD_NUMBER} .
```

## Optimization Patterns

### Build Context Optimization
```dockerfile
# .dockerignore
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.DS_Store
coverage
.next
dist
```

```yaml
pipelines:
  default:
    - step:
        name: Optimized Build
        services:
          - docker
        script:
          - docker build -t myapp:${BITBUCKET_BUILD_NUMBER} .
```

### Parallel Build and Test
```yaml
pipelines:
  default:
    - parallel:
        - step:
            name: Build Docker Image
            services:
              - docker
            caches:
              - docker
            script:
              - docker build -t myapp:${BITBUCKET_BUILD_NUMBER} .
              - docker save myapp:${BITBUCKET_BUILD_NUMBER} -o myapp.tar
            artifacts:
              - myapp.tar
        
        - step:
            name: Run Tests
            caches:
              - node
            script:
              - npm ci
              - npm run test
    
    - step:
        name: Push Image
        services:
          - docker
        script:
          - docker load -i myapp.tar
          - docker push myapp:${BITBUCKET_BUILD_NUMBER}
```

## Security Scanning

### Trivy Security Scan
```yaml
pipelines:
  default:
    - step:
        name: Build and Scan
        services:
          - docker
        script:
          - docker build -t myapp:${BITBUCKET_BUILD_NUMBER} .
          - pipe: aquasecurity/trivy-pipe:1.0.0
            variables:
              IMAGE_NAME: myapp:${BITBUCKET_BUILD_NUMBER}
              SEVERITY: HIGH,CRITICAL
              EXIT_CODE: '1'
```

### Snyk Container Scan
```yaml
pipelines:
  default:
    - step:
        name: Security Scan
        services:
          - docker
        script:
          - docker build -t myapp:${BITBUCKET_BUILD_NUMBER} .
          - pipe: snyk/snyk-scan:1.0.0
            variables:
              SNYK_TOKEN: $SNYK_TOKEN
              LANGUAGE: docker
              IMAGE_NAME: myapp:${BITBUCKET_BUILD_NUMBER}
              SEVERITY_THRESHOLD: high
              DONT_BREAK_BUILD: 'false'
```

## Complete Docker Workflow

### Production-Ready Pipeline
```yaml
image: atlassian/default-image:3

definitions:
  services:
    docker:
      memory: 2048
  
  caches:
    docker-layers: /var/lib/docker

pipelines:
  branches:
    develop:
      - step:
          name: Build Development Image
          services:
            - docker
          caches:
            - docker
          script:
            - export IMAGE_NAME=$DOCKER_HUB_USERNAME/myapp
            - export IMAGE_TAG=dev-${BITBUCKET_BUILD_NUMBER}
            - docker build -t $IMAGE_NAME:$IMAGE_TAG .
            - echo $DOCKER_HUB_PASSWORD | docker login -u $DOCKER_HUB_USERNAME --password-stdin
            - docker push $IMAGE_NAME:$IMAGE_TAG
      
      - step:
          name: Deploy to Dev
          deployment: development
          script:
            - kubectl set image deployment/myapp myapp=$DOCKER_HUB_USERNAME/myapp:dev-${BITBUCKET_BUILD_NUMBER}
    
    main:
      - step:
          name: Build Production Image
          services:
            - docker
          caches:
            - docker
          script:
            - export IMAGE_NAME=$DOCKER_HUB_USERNAME/myapp
            - export IMAGE_TAG=${BITBUCKET_BUILD_NUMBER}
            - docker build 
              --build-arg NODE_ENV=production 
              --build-arg VERSION=${BITBUCKET_BUILD_NUMBER} 
              -t $IMAGE_NAME:$IMAGE_TAG 
              -t $IMAGE_NAME:latest .
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
                IMAGE_NAME: $DOCKER_HUB_USERNAME/myapp:${BITBUCKET_BUILD_NUMBER}
                SEVERITY: HIGH,CRITICAL
      
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - kubectl set image deployment/myapp myapp=$DOCKER_HUB_USERNAME/myapp:${BITBUCKET_BUILD_NUMBER}
            - kubectl rollout status deployment/myapp
```

## Docker-in-Docker (DinD) Advanced

### Custom Docker Service
```yaml
definitions:
  services:
    docker-custom:
      image: docker:20-dind
      memory: 4096
      environment:
        DOCKER_OPTS: "--storage-driver=overlay2"

pipelines:
  default:
    - step:
        name: Build with Custom Docker
        services:
          - docker-custom
        script:
          - docker build -t myapp .
```

### Docker with Specific Version
```yaml
definitions:
  services:
    docker-24:
      image: docker:24-dind
      memory: 2048

pipelines:
  default:
    - step:
        services:
          - docker-24
        script:
          - docker version
          - docker build -t myapp .
```

## Image Size Optimization

### Check Image Size
```yaml
pipelines:
  default:
    - step:
        name: Build and Analyze
        services:
          - docker
        script:
          - docker build -t myapp:${BITBUCKET_BUILD_NUMBER} .
          - docker images myapp:${BITBUCKET_BUILD_NUMBER}
          - docker history myapp:${BITBUCKET_BUILD_NUMBER}
```

### Multi-Arch Builds
```yaml
pipelines:
  default:
    - step:
        name: Multi-Architecture Build
        services:
          - docker
        script:
          - docker buildx create --use
          - docker buildx build 
            --platform linux/amd64,linux/arm64 
            -t myapp:${BITBUCKET_BUILD_NUMBER} 
            --push .
```

## Best Practices

### ✅ Do's
- Use multi-stage builds to reduce image size
- Implement .dockerignore to exclude unnecessary files
- Use specific base image tags (not `latest`)
- Enable Docker layer caching
- Scan images for vulnerabilities
- Use BuildKit for better caching
- Authenticate to registries securely
- Tag images with build numbers and semantic versions

### ❌ Don'ts
- Don't use `latest` tag in production
- Don't include secrets in Docker images
- Don't run containers as root user
- Don't build large images (aim for < 500MB)
- Don't skip security scanning
- Don't commit registry credentials
- Don't use outdated base images

## Troubleshooting

### Docker Service Not Starting
```yaml
- step:
    name: Debug Docker
    services:
      - docker
    script:
      - docker version
      - docker info
      - docker ps
```

### Image Build Failures
```yaml
- step:
    name: Debug Build
    services:
      - docker
    script:
      - docker build --no-cache -t myapp:debug .
      - docker images
      - docker inspect myapp:debug
```

### Registry Push Issues
```yaml
- step:
    name: Debug Push
    services:
      - docker
    script:
      - docker login $REGISTRY_URL -u $USERNAME --password-stdin <<< "$PASSWORD"
      - docker tag myapp:latest $REGISTRY_URL/myapp:latest
      - docker push $REGISTRY_URL/myapp:latest -v
```
