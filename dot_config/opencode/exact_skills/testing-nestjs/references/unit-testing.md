# NestJS Unit Testing Patterns

Patterns for testing NestJS resolvers, controllers, and services using @suites/unit for auto-mocking.

## Jest Configuration

### jest.config.ts
```typescript
import type { Config } from 'jest';

const config: Config = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  modulePaths: ['<rootDir>/..'],
  rootDir: 'src',
  testRegex: '.*\\.spec\\.ts$',
  transform: {
    // Use SWC for fast compilation (no source maps in tests)
    '^.+\\.(t|j)s$': ['@swc/jest', { sourceMaps: false, inputSourceMap: false }],
  },
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
  testEnvironment: 'node',
  clearMocks: true,
  setupFiles: ['<rootDir>/../test/setup/jest-env.ts'],
  globalSetup: '<rootDir>/../test/setup/global-setup.ts',
  globalTeardown: '<rootDir>/../test/setup/global-teardown.ts',
};

export default config;
```

### jest-env.ts (Environment Setup)
```typescript
// test/setup/jest-env.ts

// Disable Sentry in tests
process.env.SENTRY_DSN = '';

// Set timezone for consistent date handling
process.env.TZ = 'UTC';

// Suppress NestJS logger unless debugging
process.env.LOG_LEVEL = process.env.LOG_LEVEL || 'silent';
```

### NPM Scripts
```json
{
  "test": "jest",
  "test:ci": "node --max-old-space-size=3072 node_modules/.bin/jest --ci --reporters=default --reporters=jest-junit",
  "test:watch": "jest --watch",
  "test:cov": "jest --coverage",
  "test:debug": "node --inspect-brk -r tsconfig-paths/register -r ts-node/register node_modules/.bin/jest --runInBand"
}
```

## @suites/unit Pattern

The preferred pattern for unit testing NestJS components. Automatically mocks all dependencies.

### Basic Setup
```typescript
import { Mocked, TestBed } from '@suites/unit';
import { fromPartial } from '@total-typescript/shoehorn';

describe('CarsResolver', () => {
  let resolver: CarsResolver;
  let carsService: Mocked<CarsService>;
  let usersService: Mocked<UsersService>;

  beforeEach(async () => {
    // TestBed.solitary() auto-mocks all dependencies
    const { unit, unitRef } = await TestBed.solitary(CarsResolver).compile();

    resolver = unit;
    carsService = unitRef.get(CarsService);
    usersService = unitRef.get(UsersService);
  });

  // Tests...
});
```

### Type-Safe Partial Mocks with fromPartial()
```typescript
import { fromPartial } from '@total-typescript/shoehorn';

// Create partial objects that satisfy TypeScript
const car: CarDocument = fromPartial({
  id: 'test-id',
  title: 'BMW X5',
  status: CarState.ACTIVE,
  // Only specify fields you need - no errors for missing fields
});

// Works with nested objects
const user: UserDocument = fromPartial({
  id: 'user-id',
  role: UserRole.MANAGER,
  profile: {
    name: 'John Doe',
  },
});

// Use in mock returns
carsService.findOne.mockResolvedValue(fromPartial({ id: '1', title: 'BMW' }));
```

## Resolver Testing

### Query Resolver
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

  describe('cars', () => {
    it('returns all cars', async () => {
      const cars = [
        fromPartial<Car>({ id: '1', title: 'BMW X5' }),
        fromPartial<Car>({ id: '2', title: 'Audi A6' }),
      ];
      carsService.findAll.mockResolvedValue(cars);

      const result = await resolver.cars();

      expect(result).toEqual(cars);
      expect(carsService.findAll).toHaveBeenCalled();
    });

    it('applies filters', async () => {
      const filters = { manufacturer: 'BMW', status: CarState.ACTIVE };
      carsService.findAll.mockResolvedValue([]);

      await resolver.cars(filters);

      expect(carsService.findAll).toHaveBeenCalledWith(filters);
    });
  });

  describe('car', () => {
    it('returns car by id', async () => {
      const car = fromPartial<Car>({ id: '1', title: 'BMW X5' });
      carsService.findOne.mockResolvedValue(car);

      const result = await resolver.car('1');

      expect(result).toEqual(car);
      expect(carsService.findOne).toHaveBeenCalledWith('1');
    });

    it('returns null when not found', async () => {
      carsService.findOne.mockResolvedValue(null);

      const result = await resolver.car('nonexistent');

      expect(result).toBeNull();
    });
  });
});
```

### Mutation Resolver
```typescript
describe('Mutations', () => {
  describe('createCar', () => {
    it('creates car with input', async () => {
      const input: CreateCarInput = {
        title: 'BMW X5',
        price: 50000,
        manufacturer: 'BMW',
      };
      const car = fromPartial<Car>({ id: '1', ...input });
      carsService.create.mockResolvedValue(car);

      const result = await resolver.createCar(input);

      expect(result).toEqual(car);
      expect(carsService.create).toHaveBeenCalledWith(input);
    });

    it('throws on validation error', async () => {
      const input: CreateCarInput = { title: '', price: -1 };
      carsService.create.mockRejectedValue(new BadRequestException('Invalid input'));

      await expect(resolver.createCar(input)).rejects.toThrow(BadRequestException);
    });
  });

  describe('updateCar', () => {
    it('updates existing car', async () => {
      const input: UpdateCarInput = { title: 'Updated Title' };
      const car = fromPartial<Car>({ id: '1', title: 'Updated Title' });
      carsService.update.mockResolvedValue(car);

      const result = await resolver.updateCar('1', input);

      expect(result).toEqual(car);
      expect(carsService.update).toHaveBeenCalledWith('1', input);
    });
  });

  describe('deleteCar', () => {
    it('deletes car and returns true', async () => {
      carsService.remove.mockResolvedValue(true);

      const result = await resolver.deleteCar('1');

      expect(result).toBe(true);
      expect(carsService.remove).toHaveBeenCalledWith('1');
    });
  });
});
```

### Field Resolver Testing
```typescript
describe('Field Resolvers', () => {
  let amortizationsService: Mocked<AmortizationsService>;

  beforeEach(async () => {
    const { unit, unitRef } = await TestBed.solitary(CarsResolver).compile();
    resolver = unit;
    amortizationsService = unitRef.get(AmortizationsService);
  });

  describe('amortizationExpected', () => {
    it('calculates expected amortization', async () => {
      const car: CarDocument = fromPartial({
        id: 'test-id',
        type: 'car-type-id',
        amortizationSnapshots: [],
      });
      const user: UserDocument = fromPartial({ role: UserRole.MANAGER });

      amortizationsService.getAmortizationExpectedTotal.mockResolvedValue(6000);

      const result = await resolver.amortizationExpected(car, user);

      expect(result).toBe(6000);
      expect(amortizationsService.getAmortizationExpectedTotal).toHaveBeenCalledWith(car);
    });

    it('returns null for non-manager users', async () => {
      const car: CarDocument = fromPartial({ id: 'test-id' });
      const user: UserDocument = fromPartial({ role: UserRole.EMPLOYEE });

      const result = await resolver.amortizationExpected(car, user);

      expect(result).toBeNull();
      expect(amortizationsService.getAmortizationExpectedTotal).not.toHaveBeenCalled();
    });
  });

  describe('owner (ResolveField)', () => {
    it('returns owner from parent car', async () => {
      const owner = fromPartial<User>({ id: 'owner-1', name: 'John' });
      const car: CarDocument = fromPartial({ id: '1', owner });

      const result = await resolver.owner(car);

      expect(result).toEqual(owner);
    });

    it('fetches owner when not populated', async () => {
      const car: CarDocument = fromPartial({ id: '1', ownerId: 'owner-1' });
      const owner = fromPartial<User>({ id: 'owner-1', name: 'John' });
      usersService.findOne.mockResolvedValue(owner);

      const result = await resolver.owner(car);

      expect(result).toEqual(owner);
      expect(usersService.findOne).toHaveBeenCalledWith('owner-1');
    });
  });
});
```

### Testing with CurrentUser Decorator
```typescript
describe('Authorization', () => {
  it('uses current user from context', async () => {
    const currentUser = fromPartial<UserDocument>({
      id: 'user-1',
      role: UserRole.MANAGER,
    });

    // Pass user as parameter (simulating @CurrentUser decorator)
    const result = await resolver.myProfile(currentUser);

    expect(result.id).toBe('user-1');
  });

  it('restricts access for non-admin users', async () => {
    const currentUser = fromPartial<UserDocument>({
      id: 'user-1',
      role: UserRole.EMPLOYEE,
    });

    await expect(resolver.adminOnlyAction(currentUser)).rejects.toThrow(
      ForbiddenException,
    );
  });
});
```

## Controller Testing

### Basic Controller Test
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

  describe('findAll', () => {
    it('returns all cars', async () => {
      const cars = [fromPartial<Car>({ id: '1', title: 'BMW' })];
      carsService.findAll.mockResolvedValue(cars);

      const result = await controller.findAll();

      expect(result).toEqual(cars);
    });
  });

  describe('findOne', () => {
    it('returns car by id', async () => {
      const car = fromPartial<Car>({ id: '1', title: 'BMW' });
      carsService.findOne.mockResolvedValue(car);

      const result = await controller.findOne('1');

      expect(result).toEqual(car);
    });

    it('throws NotFoundException when not found', async () => {
      carsService.findOne.mockResolvedValue(null);

      await expect(controller.findOne('999')).rejects.toThrow(NotFoundException);
    });
  });
});
```

### CSV Export Controller
```typescript
describe('csv', () => {
  it('returns CSV with all car numbers', async () => {
    const cars = [
      fromPartial<CarDocument>({ numbers: ['BA123CD', 'BA456EF'] }),
      fromPartial<CarDocument>({ numbers: ['KE789GH'] }),
    ];
    carsService.findAll.mockResolvedValue(cars);

    const result = await controller.csv();

    expect(result).toEqual('number\nBA123CD\nBA456EF\nKE789GH');
  });

  it('returns header only when no cars', async () => {
    carsService.findAll.mockResolvedValue([]);

    const result = await controller.csv();

    expect(result).toEqual('number');
  });
});
```

### Controller with Request/Response
```typescript
describe('upload', () => {
  it('handles file upload', async () => {
    const file = {
      originalname: 'car.jpg',
      buffer: Buffer.from('image data'),
      mimetype: 'image/jpeg',
    } as Express.Multer.File;

    carsService.uploadImage.mockResolvedValue({ url: 'https://example.com/car.jpg' });

    const result = await controller.upload('1', file);

    expect(result.url).toBe('https://example.com/car.jpg');
    expect(carsService.uploadImage).toHaveBeenCalledWith('1', file);
  });
});

describe('download', () => {
  it('streams file to response', async () => {
    const mockResponse = {
      setHeader: jest.fn(),
      pipe: jest.fn(),
    };
    const mockStream = { pipe: jest.fn() };
    carsService.getFileStream.mockResolvedValue(mockStream);

    await controller.download('1', mockResponse as any);

    expect(mockResponse.setHeader).toHaveBeenCalledWith(
      'Content-Type',
      'application/octet-stream',
    );
    expect(mockStream.pipe).toHaveBeenCalledWith(mockResponse);
  });
});
```

## Service Testing

### Service with Database (Integration)
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
          validationSchema: undefined,
          load: [() => ({ DB_CONNECTION: mongoUri })],
        }),
        DatabaseModule.forRoot(),
        CarsModule,
      ],
      providers: [CarsFactory],
    }).compile();

    service = module.get(CarsService);
    carsFactory = module.get(CarsFactory);
  }, 60000); // 60s timeout for container startup

  beforeEach(async () => {
    await carsFactory.clean();
  });

  afterAll(async () => {
    await mongoose.disconnect();
  });

  describe('findOneByNumber', () => {
    it('finds car by exact number match', async () => {
      const car = await carsFactory.create({ numbers: ['AA123BB', 'AA234CC'] });

      const result = await service.findOneByNumber('AA234CC');

      expect(result?.id).toEqual(car.id);
    });

    it('returns null when number not found', async () => {
      await carsFactory.create({ numbers: ['AA123BB'] });

      const result = await service.findOneByNumber('XX999ZZ');

      expect(result).toBeNull();
    });
  });

  describe('create', () => {
    it('creates car with all fields', async () => {
      const input = {
        title: 'BMW X5',
        price: 50000,
        manufacturer: 'BMW',
        year: 2023,
      };

      const result = await service.create(input);

      expect(result.id).toBeDefined();
      expect(result.title).toBe('BMW X5');
      expect(result.price).toBe(50000);
    });
  });
});
```

### Service Unit Test (Mocked Dependencies)
```typescript
import { Mocked, TestBed } from '@suites/unit';

describe('CarsService (Unit)', () => {
  let service: CarsService;
  let carsRepository: Mocked<CarsRepository>;
  let eventEmitter: Mocked<EventEmitter2>;

  beforeEach(async () => {
    const { unit, unitRef } = await TestBed.solitary(CarsService).compile();
    service = unit;
    carsRepository = unitRef.get(CarsRepository);
    eventEmitter = unitRef.get(EventEmitter2);
  });

  describe('updateStatus', () => {
    it('updates status and emits event', async () => {
      const car = fromPartial<CarDocument>({ id: '1', status: CarState.ACTIVE });
      carsRepository.findById.mockResolvedValue(car);
      carsRepository.save.mockResolvedValue({ ...car, status: CarState.SOLD });

      await service.updateStatus('1', CarState.SOLD);

      expect(carsRepository.save).toHaveBeenCalled();
      expect(eventEmitter.emit).toHaveBeenCalledWith(
        'car.status.changed',
        expect.objectContaining({ carId: '1', newStatus: CarState.SOLD }),
      );
    });
  });
});
```

## Mocking External Services

### Mock Builder Pattern
```typescript
// test/factories/rshop.factory.ts
export class RshopContractMockBuilder {
  private orders: OrderDocument[] = [];
  private contracts: ContractDocument[] = [];

  withOrder(overrides?: Partial<OrderDocument>): this {
    this.orders.push(RshopFactory.createOrder(overrides));
    return this;
  }

  withContract(overrides?: Partial<ContractDocument>): this {
    this.contracts.push(RshopFactory.createContract(overrides));
    return this;
  }

  applyTo(rshopService: Mocked<RshopService>): void {
    rshopService.findOrders.mockResolvedValue(this.orders);
    rshopService.findContracts.mockResolvedValue(this.contracts);
  }
}

// Usage in tests
describe('ContractResolver', () => {
  it('calculates totals from external orders', async () => {
    new RshopContractMockBuilder()
      .withOrder({ rshopId: 401, amount: 1000 })
      .withOrder({ rshopId: 402, amount: 2000 })
      .applyTo(rshopService);

    const result = await resolver.totalAmount(contract);

    expect(result).toBe(3000);
  });
});
```

### Spying on Methods
```typescript
describe('Logging', () => {
  it('logs errors on failure', async () => {
    const logSpy = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => {});
    carsService.findOne.mockRejectedValue(new Error('Database error'));

    await expect(resolver.car('1')).rejects.toThrow();

    expect(logSpy).toHaveBeenCalledWith(
      expect.stringContaining('Database error'),
      expect.any(String),
    );
    logSpy.mockRestore();
  });
});
```

## Parameterized Tests

### Using test.each
```typescript
describe('validation', () => {
  const validCases = [
    { input: { price: 0 }, description: 'zero price' },
    { input: { price: 100000 }, description: 'high price' },
    { input: { year: 2000 }, description: 'old year' },
  ];

  test.each(validCases)('accepts $description', async ({ input }) => {
    carsService.create.mockResolvedValue(fromPartial({ ...input }));

    await expect(resolver.createCar(input as any)).resolves.toBeDefined();
  });

  const invalidCases = [
    { input: { price: -1 }, error: 'Price must be positive' },
    { input: { year: 1800 }, error: 'Year must be after 1900' },
  ];

  test.each(invalidCases)('rejects when $error', async ({ input }) => {
    await expect(resolver.createCar(input as any)).rejects.toThrow();
  });
});
```

### Using Fixtures
```typescript
// test/fixtures/car-history.fixtures.ts
export const validCarHistories = {
  fullLifecycle: [
    { name: HistoryEventType.REGISTRATION, date: '2024-01-01' },
    { name: HistoryEventType.START_OF_RENTING, date: '2024-02-01' },
    { name: HistoryEventType.END_OF_RENTING, date: '2024-12-01' },
    { name: HistoryEventType.SALE, date: '2025-01-01' },
  ],
  onlyRegistration: [
    { name: HistoryEventType.REGISTRATION, date: '2024-01-01' },
  ],
};

export const invalidCarHistories = {
  rentingBeforeRegistration: [
    { name: HistoryEventType.START_OF_RENTING, date: '2024-01-01' },
    { name: HistoryEventType.REGISTRATION, date: '2024-02-01' },
  ],
};

// Usage
import { validCarHistories, invalidCarHistories } from 'test/fixtures/car-history.fixtures';

describe('history validation', () => {
  test.each(Object.entries(validCarHistories))(
    'accepts %s history',
    async (name, history) => {
      const car = await carsFactory.create({ history });
      await expect(service.validateHistory(car)).resolves.toBe(true);
    },
  );

  test.each(Object.entries(invalidCarHistories))(
    'rejects %s',
    async (name, history) => {
      const car = await carsFactory.create({ history });
      await expect(service.validateHistory(car)).rejects.toThrow();
    },
  );
});
```

## Error Testing

### Testing Exceptions
```typescript
describe('error handling', () => {
  it('throws NotFoundException for missing car', async () => {
    carsService.findOne.mockResolvedValue(null);

    await expect(resolver.car('nonexistent')).rejects.toThrow(NotFoundException);
    await expect(resolver.car('nonexistent')).rejects.toThrow('Car not found');
  });

  it('throws BadRequestException for invalid input', async () => {
    carsService.create.mockRejectedValue(
      new BadRequestException('Title is required'),
    );

    await expect(resolver.createCar({} as any)).rejects.toThrow(BadRequestException);
  });

  it('wraps unexpected errors', async () => {
    carsService.findAll.mockRejectedValue(new Error('Database connection lost'));

    await expect(resolver.cars()).rejects.toThrow(InternalServerErrorException);
  });
});
```

### Testing GraphQL Errors
```typescript
describe('GraphQL errors', () => {
  it('returns user-friendly message', async () => {
    carsService.findOne.mockRejectedValue(
      new GraphQLError('Car not found', {
        extensions: { code: 'NOT_FOUND' },
      }),
    );

    try {
      await resolver.car('1');
    } catch (error) {
      expect(error.extensions.code).toBe('NOT_FOUND');
    }
  });
});
```

## Best Practices

### Do's
- Use `TestBed.solitary()` for auto-mocking dependencies
- Use `fromPartial()` for type-safe partial objects
- Clean database between tests with `factory.clean()`
- Use descriptive test names without "should"
- Test edge cases and error conditions
- Keep tests focused on one behavior

### Don'ts
- Don't mock what you don't own (test with real implementations where possible)
- Don't use `mockCar` naming - use `car` directly
- Don't test implementation details
- Don't share state between tests
- Don't ignore async/await in tests
