---
name: testing-nestjs
description: NestJS testing patterns with Jest, @suites/unit, and Testcontainers. Use when (1) writing unit tests for services/resolvers/controllers, (2) setting up Jest configuration, (3) creating test factories and builders, (4) writing E2E tests with real database, (5) mocking dependencies with @suites/unit, (6) using Testcontainers for integration tests, (7) implementing test data patterns, (8) cleaning up test databases.
---

# NestJS Testing Patterns

Reference implementation: `~/www/edencars/edencars-infosystem-api`

## Quick Reference

**Unit Testing:**
- **[unit-testing.md](references/unit-testing.md)** - Service, resolver, controller testing with @suites/unit and TestBed.solitary()

**Test Data:**
- **[factories.md](references/factories.md)** - Injectable factories, builders, fixtures, TestDataFactory base class

**E2E Testing:**
- **[e2e-testing.md](references/e2e-testing.md)** - Testcontainers setup, GraphQL test helpers, E2E module configuration

**Database:**
- **[database.md](references/database.md)** - Database cleanup patterns, test isolation

## Jest Configuration Essentials

### jest.config.ts
```typescript
import type { Config } from 'jest';

const config: Config = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  modulePaths: ['<rootDir>/..'],
  rootDir: 'src',
  testRegex: '.*\\.spec\\.ts$',
  transform: {
    '^.+\\.(t|j)s$': ['@swc/jest', { sourceMaps: false }],
  },
  coverageThreshold: {
    global: { branches: 80, functions: 80, lines: 80, statements: 80 },
  },
  testEnvironment: 'node',
  clearMocks: true,
  setupFiles: ['<rootDir>/../test/setup/jest-env.ts'],
  globalSetup: '<rootDir>/../test/setup/global-setup.ts',
  globalTeardown: '<rootDir>/../test/setup/global-teardown.ts',
};

export default config;
```

### Key Dependencies
```json
{
  "@faker-js/faker": "^10.x",
  "@suites/di.nestjs": "^3.x",
  "@suites/doubles.jest": "^3.x",
  "@suites/unit": "^3.x",
  "@swc/jest": "*",
  "@total-typescript/shoehorn": "^0.1.x",
  "testcontainers": "^11.x",
  "supertest": "^7.x"
}
```

## @suites/unit Pattern (Preferred)

### TestBed.solitary() for Auto-Mocking
```typescript
import { Mocked, TestBed } from '@suites/unit';
import { fromPartial } from '@total-typescript/shoehorn';

describe('CarsResolver', () => {
  let resolver: CarsResolver;
  let carsService: Mocked<CarsService>;

  beforeEach(async () => {
    const { unit, unitRef } = await TestBed.solitary(CarsResolver).compile();

    resolver = unit;
    carsService = unitRef.get(CarsService);
  });

  it('returns cars from service', async () => {
    const cars = [fromPartial<Car>({ id: '1', title: 'BMW X5' })];
    carsService.findAll.mockResolvedValue(cars);

    const result = await resolver.cars();

    expect(result).toEqual(cars);
  });
});
```

### fromPartial() for Type-Safe Partial Mocks
```typescript
import { fromPartial } from '@total-typescript/shoehorn';

// Only specify fields you need - fully typed
const car: CarDocument = fromPartial({
  id: 'test-id',
  numbers: ['ABC123'],
  status: CarState.ACTIVE,
});

// Works with complex nested objects
const user: UserDocument = fromPartial({
  id: 'user-id',
  role: UserRole.MANAGER,
  permissions: ['read', 'write'],
});
```

## Basic Unit Test Structure

### Resolver Test
```typescript
import { Mocked, TestBed } from '@suites/unit';
import { fromPartial } from '@total-typescript/shoehorn';

describe('CarsResolver', () => {
  let resolver: CarsResolver;
  let carsService: Mocked<CarsService>;

  beforeEach(async () => {
    const { unit, unitRef } = await TestBed.solitary(CarsResolver).compile();
    resolver = unit;
    carsService = unitRef.get(CarsService);
  });

  describe('car', () => {
    it('returns car by id', async () => {
      const car = fromPartial<Car>({ id: '1', title: 'BMW' });
      carsService.findOne.mockResolvedValue(car);

      const result = await resolver.car('1');

      expect(result).toEqual(car);
      expect(carsService.findOne).toHaveBeenCalledWith('1');
    });
  });

  describe('createCar', () => {
    it('creates car with input', async () => {
      const input = { title: 'BMW X5', price: 50000 };
      const car = fromPartial<Car>({ id: '1', ...input });
      carsService.create.mockResolvedValue(car);

      const result = await resolver.createCar(input);

      expect(result).toEqual(car);
    });
  });
});
```

### Service Test (with Database)
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import mongoose from 'mongoose';
import { CarsFactory } from 'test/factories/cars.factory';
import { getMongoUri } from 'test/setup/mongodb-container';

describe('CarsService', () => {
  let service: CarsService;
  let carsFactory: CarsFactory;

  beforeAll(async () => {
    const mongoUri = await getMongoUri();

    const module: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.register({
          isGlobal: true,
          ignoreEnvFile: true,
          load: [() => ({ DB_CONNECTION: mongoUri })],
        }),
        DatabaseModule.forRoot(),
        CarsModule,
      ],
      providers: [CarsFactory],
    }).compile();

    service = module.get(CarsService);
    carsFactory = module.get(CarsFactory);
  }, 60000);

  beforeEach(async () => {
    await carsFactory.clean();
  });

  afterAll(async () => {
    await mongoose.disconnect();
  });

  it('finds car by number', async () => {
    const car = await carsFactory.create({ numbers: ['AA123BB'] });

    const result = await service.findOneByNumber('AA123BB');

    expect(result?.id).toEqual(car.id);
  });
});
```

### Controller Test
```typescript
import { Mocked, TestBed } from '@suites/unit';
import { fromPartial } from '@total-typescript/shoehorn';

describe('CarsController', () => {
  let controller: CarsController;
  let carsService: Mocked<CarsService>;

  beforeEach(async () => {
    const { unit, unitRef } = await TestBed.solitary(CarsController).compile();
    controller = unit;
    carsService = unitRef.get(CarsService);
  });

  describe('csv', () => {
    it('returns CSV with car numbers', async () => {
      const cars = [
        fromPartial<CarDocument>({ numbers: ['BA123CD', 'BA456EF'] }),
      ];
      carsService.findAll.mockResolvedValue(cars);

      const result = await controller.csv();

      expect(result).toEqual('number\nBA123CD\nBA456EF');
    });
  });
});
```

## Naming Conventions

### File Naming
| Pattern | Type | Location |
|---------|------|----------|
| `*.spec.ts` | Unit tests | `src/` (co-located) |
| `*.e2e-spec.ts` | E2E tests | `test/` |
| `*.factory.ts` | Factories | `test/factories/` |
| `*.builder.ts` | Builders | `test/builders/` |
| `*.fixtures.ts` | Fixtures | `test/fixtures/` |

### Test Descriptions
```typescript
// Use present tense, no "should"
it('returns car by id', ...);        // Good
it('should return car by id', ...);  // Avoid

// Use descriptive names
it('throws when car not found', ...);
it('filters by manufacturer', ...);
```

### Variable Naming
```typescript
// Use direct names, not "mock" prefix
const car = fromPartial<Car>({ ... });     // Good
const mockCar = fromPartial<Car>({ ... }); // Avoid
```

## When to Load Reference Files

**Load unit-testing.md when:**
- Writing resolver, controller, or service unit tests
- Need @suites/unit TestBed patterns
- Testing field resolvers or computed fields
- Testing authorization/guards in resolvers

**Load factories.md when:**
- Creating test data factories
- Implementing builder pattern for complex entities
- Setting up fixtures for parameterized tests
- Need TestDataFactory base class

**Load e2e-testing.md when:**
- Setting up Testcontainers
- Writing GraphQL E2E tests
- Configuring test module with real database
- Need global setup/teardown patterns

**Load database.md when:**
- Implementing test database cleanup
- Need isolation between tests
- Handling database connections in tests
