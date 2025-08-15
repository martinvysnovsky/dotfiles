# Jest Configuration for Unit Testing

Configuration guides for Jest in NestJS unit testing environments.

## Basic Jest Configuration

### jest.config.js
```javascript
module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'src',
  testRegex: '.*\\.spec\\.ts$',
  transform: {
    '^.+\\.(t|j)s$': '@swc/jest',
  },
  collectCoverageFrom: [
    '**/*.(t|j)s',
    '!**/*.spec.ts',
    '!**/*.interface.ts',
    '!**/*.dto.ts',
    '!**/*.entity.ts',
  ],
  coverageDirectory: '../coverage',
  testEnvironment: 'node',
  setupFilesAfterEnv: ['<rootDir>/../test/setup.ts'],
  moduleNameMapping: {
    '^src/(.*)$': '<rootDir>/$1',
  },
};
```

### Test Setup File
```typescript
// test/setup.ts
import 'reflect-metadata';

// Global test configuration
jest.setTimeout(30000);

// Mock external services
jest.mock('aws-sdk', () => ({
  S3: jest.fn(() => ({
    upload: jest.fn().mockReturnThis(),
    promise: jest.fn(),
  })),
}));

// Global test utilities
global.mockDate = (date: string) => {
  jest.useFakeTimers();
  jest.setSystemTime(new Date(date));
};

global.restoreDate = () => {
  jest.useRealTimers();
};
```

## Package.json Scripts

### Testing Scripts
```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:cov": "jest --coverage",
    "test:debug": "node --inspect-brk -r tsconfig-paths/register -r ts-node/register node_modules/.bin/jest --runInBand",
    "test:ci": "node --max-old-space-size=3072 node_modules/.bin/jest --ci --reporters=default --reporters=jest-junit"
  },
  "devDependencies": {
    "@nestjs/testing": "^10.0.0",
    "@swc/jest": "^0.2.0",
    "@types/jest": "^29.0.0",
    "jest": "^29.0.0",
    "jest-junit": "^16.0.0"
  }
}
```

## Advanced Configuration

### TypeScript Path Mapping
```javascript
// jest.config.js
const { pathsToModuleNameMapper } = require('ts-jest');
const { compilerOptions } = require('./tsconfig.json');

module.exports = {
  // ... other config
  moduleNameMapper: pathsToModuleNameMapper(compilerOptions.paths, {
    prefix: '<rootDir>/',
  }),
};
```

### Coverage Configuration
```javascript
module.exports = {
  // ... other config
  collectCoverageFrom: [
    'src/**/*.(t|j)s',
    '!src/**/*.spec.ts',
    '!src/**/*.interface.ts',
    '!src/**/*.dto.ts',
    '!src/**/*.entity.ts',
    '!src/**/*.module.ts',
    '!src/main.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
  coverageReporters: ['text', 'lcov', 'html'],
};
```

### Environment-Specific Configs

#### Development Config
```javascript
// jest.config.dev.js
module.exports = {
  ...require('./jest.config.js'),
  verbose: true,
  collectCoverage: false,
  watchPathIgnorePatterns: ['node_modules'],
};
```

#### CI Config
```javascript
// jest.config.ci.js
module.exports = {
  ...require('./jest.config.js'),
  ci: true,
  collectCoverage: true,
  coverageReporters: ['text', 'lcov'],
  reporters: [
    'default',
    ['jest-junit', {
      outputDirectory: 'test-results',
      outputName: 'junit.xml',
    }],
  ],
  maxWorkers: '50%',
};
```

## Mock Configuration

### Global Mocks
```typescript
// test/mocks/global.ts
export const mockConfigService = {
  get: jest.fn(),
  getOrThrow: jest.fn(),
};

export const mockLogger = {
  log: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
  debug: jest.fn(),
};

export const mockRepository = {
  find: jest.fn(),
  findOne: jest.fn(),
  create: jest.fn(),
  save: jest.fn(),
  update: jest.fn(),
  delete: jest.fn(),
  remove: jest.fn(),
};
```

### Module Mocking
```typescript
// test/setup.ts
import { mockConfigService, mockLogger } from './mocks/global';

// Auto-mock common modules
jest.mock('@nestjs/config', () => ({
  ConfigService: jest.fn(() => mockConfigService),
}));

jest.mock('@nestjs/common', () => ({
  ...jest.requireActual('@nestjs/common'),
  Logger: jest.fn(() => mockLogger),
}));
```

## Best Practices

### ✅ Do's
- Use SWC for faster compilation
- Configure path mapping for clean imports
- Set appropriate coverage thresholds
- Use separate configs for different environments
- Mock external dependencies globally

### ❌ Don'ts
- Don't include test files in coverage
- Don't set unrealistic coverage thresholds
- Don't ignore TypeScript configuration
- Don't run tests without proper setup
- Don't commit coverage files to git