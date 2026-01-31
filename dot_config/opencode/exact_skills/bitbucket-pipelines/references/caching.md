# Caching Strategies

Optimize pipeline performance with effective caching strategies.

## Built-in Caches

Bitbucket provides predefined caches for common dependencies.

### Node.js Caches
```yaml
definitions:
  caches:
    npm: ~/.npm  # npm cache directory

pipelines:
  default:
    - step:
        name: Build
        caches:
          - node  # Caches node_modules directory
          - npm   # Caches npm cache
        script:
          - npm ci
          - npm run build
```

### Available Built-in Caches
- `node` - `node_modules/`
- `npm` - `~/.npm`
- `pip` - `~/.cache/pip`
- `docker` - `/var/lib/docker`
- `maven` - `~/.m2/repository`
- `gradle` - `~/.gradle/caches`
- `composer` - `~/.composer/cache`
- `dotnetcore` - `~/.nuget/packages`

## Custom Caches

Define custom cache locations for project-specific needs.

### Basic Custom Cache
```yaml
definitions:
  caches:
    myapp-build: dist/
    cypress: ~/.cache/Cypress

pipelines:
  default:
    - step:
        name: Build and Test
        caches:
          - node
          - myapp-build
          - cypress
        script:
          - npm ci
          - npm run build
          - npm run test:e2e
```

### Multiple Custom Caches
```yaml
definitions:
  caches:
    sonar: ~/.sonar/cache
    playwright: ~/.cache/ms-playwright
    esbuild: node_modules/.cache/esbuild

pipelines:
  default:
    - step:
        caches:
          - node
          - sonar
          - playwright
          - esbuild
        script:
          - npm ci
          - npm run build
          - npm run test
```

## Cache Keys

Caches are automatically keyed by the cache definition. Manual invalidation is done by clearing cache in Bitbucket UI.

### Automatic Invalidation
Caches expire after 1 week of no use.

### Manual Cache Clearing
1. Go to Repository Settings → Pipelines → Caches
2. Select caches to clear
3. Click "Clear cache"

## Performance Patterns

### Layered Caching Strategy
```yaml
definitions:
  caches:
    npm: ~/.npm           # Layer 1: Package manager cache
    cypress: ~/.cache/Cypress  # Layer 2: Tool cache
    nextjs: .next/cache   # Layer 3: Build cache

pipelines:
  default:
    - step:
        name: Build Next.js App
        caches:
          - node
          - npm
          - nextjs
          - cypress
        script:
          - npm ci
          - npm run build
          - npm run test:e2e
```

### Monorepo Caching
```yaml
definitions:
  caches:
    npm: ~/.npm
    turbo: node_modules/.cache/turbo
    
pipelines:
  default:
    - step:
        name: Build Monorepo
        caches:
          - node
          - npm
          - turbo
        script:
          - npm ci
          - npm run build  # Turborepo with cache
```

### Docker Layer Caching
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
        caches:
          - docker
        script:
          - docker build -t myapp:${BITBUCKET_BUILD_NUMBER} .
          - docker push myapp:${BITBUCKET_BUILD_NUMBER}
```

## Cache Size Limits

- **Maximum cache size**: 1GB per cache definition
- **Total cache size**: 5GB per repository
- **Cache retention**: 1 week of inactivity

### Optimize Cache Size
```yaml
definitions:
  caches:
    # Bad: Caches entire directory including build outputs
    # node: ./
    
    # Good: Only caches dependencies
    node: node_modules/
    npm: ~/.npm

pipelines:
  default:
    - step:
        caches:
          - node
          - npm
        script:
          - npm ci
          - npm run build  # Build outputs NOT cached
```

## Advanced Patterns

### Conditional Caching
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Production Build
          caches:
            - node
            - npm
          script:
            - npm ci --production  # Production deps only
            - npm run build
    
    develop:
      - step:
          name: Development Build
          caches:
            - node  # All deps including devDependencies
          script:
            - npm ci
            - npm run build
```

### Cache Warming
```yaml
pipelines:
  custom:
    warm-cache:
      - step:
          name: Warm Caches
          caches:
            - node
            - npm
            - cypress
          script:
            - npm ci
            - npx cypress install
            - echo "Caches warmed"
```

### Selective Cache Usage
```yaml
pipelines:
  default:
    - step:
        name: Install Dependencies
        caches:
          - node
          - npm
        script:
          - npm ci
        artifacts:
          - node_modules/**
    
    - parallel:
        - step:
            name: Unit Tests
            # Uses artifacts, no cache needed
            script:
              - npm run test:unit
        
        - step:
            name: Build
            # Uses artifacts, no cache needed
            script:
              - npm run build
```

## Debugging Cache Issues

### Verify Cache Usage
```yaml
- step:
    name: Debug Cache
    caches:
      - node
    script:
      - echo "Before npm ci:"
      - ls -la node_modules/ || echo "No node_modules"
      - npm ci
      - echo "After npm ci:"
      - ls -la node_modules/
      - echo "Cache should be updated"
```

### Check Cache Directories
```yaml
- step:
    name: Inspect Caches
    caches:
      - node
      - npm
    script:
      - echo "Node modules:"
      - du -sh node_modules/ || echo "Not found"
      - echo "NPM cache:"
      - du -sh ~/.npm || echo "Not found"
```

### Force Cache Invalidation
```yaml
- step:
    name: Clean Install
    script:
      - rm -rf node_modules/
      - rm -rf ~/.npm
      - npm ci
```

## Common Cache Scenarios

### Next.js Application
```yaml
definitions:
  caches:
    npm: ~/.npm
    nextjs: .next/cache

pipelines:
  default:
    - step:
        caches:
          - node
          - npm
          - nextjs
        script:
          - npm ci
          - npm run build
```

### NestJS Application
```yaml
definitions:
  caches:
    npm: ~/.npm
    jest: node_modules/.cache/jest

pipelines:
  default:
    - step:
        caches:
          - node
          - npm
          - jest
        script:
          - npm ci
          - npm run test
          - npm run build
```

### React Application with Cypress
```yaml
definitions:
  caches:
    npm: ~/.npm
    cypress: ~/.cache/Cypress
    vite: node_modules/.vite

pipelines:
  default:
    - step:
        caches:
          - node
          - npm
          - cypress
          - vite
        script:
          - npm ci
          - npm run build
          - npm run test:e2e
```

### Monorepo with pnpm
```yaml
definitions:
  caches:
    pnpm: ~/.pnpm-store
    turbo: node_modules/.cache/turbo

pipelines:
  default:
    - step:
        caches:
          - pnpm
          - turbo
        script:
          - corepack enable
          - pnpm install --frozen-lockfile
          - pnpm run build
```

## Best Practices

### ✅ Do's
- Cache package manager stores (`~/.npm`, `~/.pnpm-store`)
- Cache tool directories (`~/.cache/Cypress`, `~/.cache/ms-playwright`)
- Cache build tool outputs (`.next/cache`, `node_modules/.cache`)
- Use multiple specific caches instead of one large cache
- Monitor cache hit rates in pipeline logs

### ❌ Don'ts
- Don't cache build outputs that should be fresh every build
- Don't cache entire project directory
- Don't exceed 1GB per cache definition
- Don't cache generated files that change on every build
- Don't cache credentials or secrets

## Cache Strategy Decision Tree

```
Is it a dependency?
├─ Yes → Use node, npm, or equivalent
└─ No
   └─ Is it downloaded by a tool?
      ├─ Yes → Cache tool directory (e.g., ~/.cache/Cypress)
      └─ No
         └─ Does it speed up builds?
            ├─ Yes → Create custom cache
            └─ No → Don't cache
```

## Troubleshooting

### Cache Not Being Used
1. Verify cache definition name matches usage
2. Check cache size (must be under 1GB)
3. Ensure cache directory exists in step
4. Review pipeline logs for cache messages

### Cache Too Large
1. Identify large cached directories
2. Exclude unnecessary files
3. Split into multiple caches
4. Clear old cache and rebuild

### Stale Cache Issues
1. Clear cache manually in Bitbucket UI
2. Verify cache invalidation triggers
3. Check if dependencies changed but cache didn't update
4. Consider shorter cache retention for frequently changing projects
