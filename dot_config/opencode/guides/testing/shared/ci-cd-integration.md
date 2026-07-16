# CI/CD Integration Guides

Configuration guides for running tests in continuous integration environments.

## GitHub Actions

### Unit Tests Workflow
```yaml
name: Unit Tests
on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run unit tests
        run: npm run test:ci
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info
          fail_ci_if_error: true
```

### E2E Tests with Services
```yaml
name: E2E Tests
on: [push, pull_request]

jobs:
  e2e-tests:
    runs-on: ubuntu-latest
    
    services:
      mongodb:
        image: mongo:7.0
        ports:
          - 27017:27017
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Wait for MongoDB
        run: |
          until nc -z localhost 27017; do
            echo "Waiting for MongoDB..."
            sleep 1
          done
      
      - name: Run E2E tests
        run: npm run test:e2e:ci
        env:
          DB_CONNECTION: mongodb://localhost:27017/test
          JWT_SECRET: test-secret-key
      
      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: e2e-test-results
          path: test-results/
```

### Combined Workflow
```yaml
name: Tests
on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Run unit tests
        run: npm run test:units
  
  e2e-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    services:
      mongodb:
        image: mongo:7.0
        ports:
          - 27017:27017
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Run E2E tests
        run: npm run test:e2e:ci
        env:
          DB_CONNECTION: mongodb://localhost:27017/test
```

## GitLab CI

### Basic Pipeline
```yaml
stages:
  - test
  - integration

variables:
  NODE_VERSION: "18"

unit-tests:
  stage: test
  image: node:$NODE_VERSION
  cache:
    paths:
      - node_modules/
  script:
    - npm ci
    - npm run test:ci
  artifacts:
    reports:
      coverage: coverage/lcov.info
    paths:
      - coverage/

e2e-tests:
  stage: integration
  image: node:$NODE_VERSION
  services:
    - mongo:7.0
  variables:
    DB_CONNECTION: mongodb://mongo:27017/test
  script:
    - npm ci
    - npm run test:e2e:ci
  artifacts:
    when: on_failure
    paths:
      - test-results/
```

## Docker Compose for Local Testing

### Test Environment
```yaml
# docker-compose.test.yml
version: '3.8'

services:
  app:
    build: .
    environment:
      - NODE_ENV=test
      - DB_CONNECTION=mongodb://mongodb:27017/test
    depends_on:
      - mongodb
    command: npm run test:e2e
  
  mongodb:
    image: mongo:7.0
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_DATABASE=test
```

## Test Reporting

### Jest Configuration for CI
```javascript
// jest.config.ci.js
module.exports = {
  ...require('./jest.config.js'),
  collectCoverage: true,
  coverageReporters: ['text', 'lcov', 'html'],
  reporters: [
    'default',
    ['jest-junit', {
      outputDirectory: 'test-results',
      outputName: 'junit.xml',
    }],
  ],
  testResultsProcessor: 'jest-sonar-reporter',
};
```

### Package.json Scripts
```json
{
  "scripts": {
    "test:ci": "jest --config jest.config.ci.js --ci --coverage --watchAll=false",
    "test:e2e:ci": "jest --config test/jest-e2e.config.js --ci --watchAll=false --maxWorkers=1"
  }
}
```

## Best Practices

### ✅ Do's
- Run unit tests before integration tests
- Use appropriate timeouts for container startup
- Cache dependencies between runs
- Generate test reports and coverage
- Use environment-specific configurations

### ❌ Don'ts
- Don't run tests in parallel without proper isolation
- Don't ignore test failures in CI
- Don't use production databases for testing
- Don't commit sensitive test credentials
- Don't skip cleanup in CI environments