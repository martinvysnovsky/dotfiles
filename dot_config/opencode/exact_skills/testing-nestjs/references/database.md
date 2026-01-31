# Database Cleanup Patterns

Strategies for cleaning up test data between tests to ensure isolation.

## MongoDB Cleanup

### Simple Collection Cleanup

```typescript
afterEach(async () => {
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany({});
  }
});
```

### Factory-Based Cleanup (Preferred)

Use the `clean()` method from `TestDataFactory` base class:

```typescript
// In test setup
beforeEach(async () => {
  await carsFactory.clean();
  await usersFactory.clean();
});

// Or clean all at once
afterEach(async () => {
  await Promise.all([
    carsFactory.clean(),
    contractsFactory.clean(),
    usersFactory.clean(),
  ]);
});
```

## Test Isolation Strategies

### Independent Tests

Each test should be independent and not rely on data from other tests:

```typescript
describe('CarsService', () => {
  beforeEach(async () => {
    // Clean slate for each test
    await carsFactory.clean();
  });

  it('should create car', async () => {
    // Create fresh data for this test
    const car = await carsFactory.create({ vin: 'TEST123' });
    // ... assertions
  });

  it('should find car by VIN', async () => {
    // Different data for this test
    const car = await carsFactory.create({ vin: 'FIND456' });
    // ... assertions
  });
});
```

### Shared Setup with Cleanup

For complex scenarios requiring shared data:

```typescript
describe('Car History', () => {
  let baseCar: Car;

  beforeAll(async () => {
    // Shared setup - created once
    baseCar = await carsFactory.create();
  });

  afterAll(async () => {
    // Cleanup after all tests in this suite
    await carsFactory.clean();
  });

  beforeEach(async () => {
    // Clean only related data between tests
    await historyFactory.clean();
  });

  it('should add history event', async () => {
    // Uses shared baseCar, fresh history
  });
});
```

## Best Practices

### Do's

- Clean database state between tests
- Use factory `clean()` methods for type-safe cleanup
- Clean in reverse dependency order when needed
- Use `beforeEach` for most cleanup scenarios

### Don'ts

- Don't rely on test execution order
- Don't leave test data in database
- Don't use `afterAll` cleanup alone (tests may fail mid-suite)
- Don't clean production databases (use test environment checks)
