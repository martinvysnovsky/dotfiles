# Test Data Factories

Patterns for creating realistic test data using factories, builders, and fixtures.

## TestDataFactory Base Class

Injectable base class for database-backed factories with cleanup support.

```typescript
// test/factories/test-data.factory.ts
import { Injectable } from '@nestjs/common';
import { Model, HydratedDocument, UpdateQuery, Types } from 'mongoose';
import { DeepPartial } from 'utility-types';

export interface TestDataFactoryInterface<E> {
  create(data?: DeepPartial<E>): Promise<HydratedDocument<E>>;
  createMany(count: number, data?: DeepPartial<E>): Promise<HydratedDocument<E>[]>;
  update(_id: Types.ObjectId, data: UpdateQuery<E>): Promise<void>;
  findAll(): Promise<HydratedDocument<E>[]>;
  clean(): Promise<void>;
}

@Injectable()
export abstract class TestDataFactory<E> implements TestDataFactoryInterface<E> {
  protected abstract readonly model: Model<E>;

  abstract create(data?: DeepPartial<E>): Promise<HydratedDocument<E>>;

  async createMany(count: number, data?: DeepPartial<E>): Promise<HydratedDocument<E>[]> {
    const items: HydratedDocument<E>[] = [];
    for (let i = 0; i < count; i++) {
      items.push(await this.create(data));
    }
    return items;
  }

  update(_id: Types.ObjectId, data: UpdateQuery<E>) {
    return this.model.updateOne({ _id }, data).exec().then(() => {});
  }

  findAll(): Promise<HydratedDocument<E>[]> {
    return this.model.find().exec();
  }

  async clean(): Promise<void> {
    await this.model.deleteMany({});
  }
}
```

## Entity Factory

### Cars Factory Example
```typescript
// test/factories/cars.factory.ts
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, HydratedDocument } from 'mongoose';
import { faker } from '@faker-js/faker';
import { DeepPartial } from 'utility-types';

import { Car, CarDocument, CarState } from 'src/cars/schemas/car.schema';
import { TestDataFactory } from './test-data.factory';

@Injectable()
export class CarsFactory extends TestDataFactory<Car> {
  constructor(
    @InjectModel(Car.name)
    protected readonly model: Model<Car>,
  ) {
    super();
  }

  async create(data?: DeepPartial<Car>): Promise<HydratedDocument<Car>> {
    const carData: DeepPartial<Car> = {
      title: faker.vehicle.vehicle(),
      manufacturer: faker.vehicle.manufacturer(),
      model: faker.vehicle.model(),
      price: faker.number.int({ min: 5000, max: 100000 }),
      purchasePrice: faker.number.int({ min: 4000, max: 90000 }),
      year: faker.number.int({ min: 2015, max: 2024 }),
      mileage: faker.number.int({ min: 0, max: 300000 }),
      fuel: faker.helpers.arrayElement(['petrol', 'diesel', 'electric', 'hybrid']),
      bodyType: faker.helpers.arrayElement(['sedan', 'suv', 'hatchback', 'wagon']),
      color: faker.vehicle.color(),
      vin: faker.vehicle.vin(),
      numbers: [faker.string.alphanumeric(7).toUpperCase()],
      status: CarState.ACTIVE,
      history: [],
      ...data,
    };

    const car = new this.model(carData);
    return car.save();
  }

  // Convenience methods for common scenarios
  async createActive(data?: DeepPartial<Car>): Promise<HydratedDocument<Car>> {
    return this.create({ ...data, status: CarState.ACTIVE });
  }

  async createSold(data?: DeepPartial<Car>): Promise<HydratedDocument<Car>> {
    return this.create({ ...data, status: CarState.SOLD });
  }

  async createWithHistory(
    events: Array<{ name: string; date: Date | string }>,
    data?: DeepPartial<Car>,
  ): Promise<HydratedDocument<Car>> {
    return this.create({
      ...data,
      history: events.map((e) => ({
        name: e.name,
        date: typeof e.date === 'string' ? new Date(e.date) : e.date,
      })),
    });
  }
}
```

### Contracts Factory Example
```typescript
// test/factories/contracts.factory.ts
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, HydratedDocument, Types } from 'mongoose';
import { faker } from '@faker-js/faker';
import { DeepPartial } from 'utility-types';

import { Contract, ContractDocument } from 'src/contracts/schemas/contract.schema';
import { TestDataFactory } from './test-data.factory';

@Injectable()
export class ContractsFactory extends TestDataFactory<Contract> {
  constructor(
    @InjectModel(Contract.name)
    protected readonly model: Model<Contract>,
  ) {
    super();
  }

  async create(data?: DeepPartial<Contract>): Promise<HydratedDocument<Contract>> {
    const contractData: DeepPartial<Contract> = {
      contractNumber: faker.string.alphanumeric(10).toUpperCase(),
      startDate: faker.date.past(),
      endDate: faker.date.future(),
      dailyRate: faker.number.int({ min: 20, max: 200 }),
      totalAmount: faker.number.int({ min: 500, max: 10000 }),
      status: 'active',
      ...data,
    };

    const contract = new this.model(contractData);
    return contract.save();
  }

  async createForCar(
    carId: string | Types.ObjectId,
    data?: DeepPartial<Contract>,
  ): Promise<HydratedDocument<Contract>> {
    return this.create({
      ...data,
      car: new Types.ObjectId(carId),
    });
  }
}
```

## Builder Pattern

For complex entities with many relationships or lifecycle states.

### Car Builder
```typescript
// test/builders/car.builder.ts
import { DeepPartial } from 'utility-types';
import { Car, CarState, HistoryEventType } from 'src/cars/schemas/car.schema';
import { CarsFactory } from 'test/factories/cars.factory';

export class CarBuilder {
  private data: DeepPartial<Car> = {
    status: CarState.ACTIVE,
    history: [],
  };

  constructor(private readonly factory: CarsFactory) {}

  // Status methods
  withActiveStatus(): this {
    this.data.status = CarState.ACTIVE;
    return this;
  }

  withSoldStatus(): this {
    this.data.status = CarState.SOLD;
    return this;
  }

  withInServiceStatus(): this {
    this.data.status = CarState.IN_SERVICE;
    return this;
  }

  // Basic properties
  withTitle(title: string): this {
    this.data.title = title;
    return this;
  }

  withPrice(price: number): this {
    this.data.price = price;
    return this;
  }

  withPurchasePrice(price: number): this {
    this.data.purchasePrice = price;
    return this;
  }

  withManufacturer(manufacturer: string): this {
    this.data.manufacturer = manufacturer;
    return this;
  }

  withNumbers(numbers: string[]): this {
    this.data.numbers = numbers;
    return this;
  }

  // History events
  withRegistrationEvent(date: Date | string): this {
    this.data.history!.push({
      name: HistoryEventType.REGISTRATION,
      date: typeof date === 'string' ? new Date(date) : date,
    });
    return this;
  }

  withRentingPeriod(startDate: Date | string, endDate: Date | string): this {
    this.data.history!.push(
      {
        name: HistoryEventType.START_OF_RENTING,
        date: typeof startDate === 'string' ? new Date(startDate) : startDate,
      },
      {
        name: HistoryEventType.END_OF_RENTING,
        date: typeof endDate === 'string' ? new Date(endDate) : endDate,
      },
    );
    return this;
  }

  withSale(date: Date | string): this {
    this.data.history!.push({
      name: HistoryEventType.SALE,
      date: typeof date === 'string' ? new Date(date) : date,
    });
    this.data.status = CarState.SOLD;
    return this;
  }

  // Combined lifecycle patterns
  withFullLifecycle(
    registrationDate: string,
    rentingStartDate: string,
    rentingEndDate: string,
    saleDate: string,
  ): this {
    this.withRegistrationEvent(registrationDate);
    this.withRentingPeriod(rentingStartDate, rentingEndDate);
    this.withSale(saleDate);
    return this;
  }

  withRentingLifecycle(
    registrationDate: string,
    rentingStartDate: string,
  ): this {
    this.withRegistrationEvent(registrationDate);
    this.data.history!.push({
      name: HistoryEventType.START_OF_RENTING,
      date: new Date(rentingStartDate),
    });
    return this;
  }

  // Build
  async build() {
    return this.factory.create(this.data);
  }
}

// Usage in tests:
// const car = await new CarBuilder(carsFactory)
//   .withManufacturer('BMW')
//   .withPrice(50000)
//   .withFullLifecycle('2024-01-01', '2024-02-01', '2024-12-01', '2025-01-01')
//   .build();
```

## Mock Builder Pattern

For mocking external services with complex responses.

```typescript
// test/factories/rshop.factory.ts
import { faker } from '@faker-js/faker';
import { Mocked } from '@suites/unit';

import { RshopService } from 'src/integrations/rshop/rshop.service';
import { OrderDocument, ContractDocument } from 'src/integrations/rshop/types';

export class RshopFactory {
  static createOrder(overrides?: Partial<OrderDocument>): OrderDocument {
    return {
      rshopId: faker.number.int({ min: 100, max: 999 }),
      carNumber: faker.string.alphanumeric(7).toUpperCase(),
      amount: faker.number.int({ min: 100, max: 5000 }),
      date: faker.date.recent(),
      status: 'completed',
      ...overrides,
    };
  }

  static createContract(overrides?: Partial<ContractDocument>): ContractDocument {
    return {
      rshopId: faker.number.int({ min: 1000, max: 9999 }),
      startDate: faker.date.past(),
      endDate: faker.date.future(),
      dailyRate: faker.number.int({ min: 20, max: 200 }),
      ...overrides,
    };
  }
}

export class RshopContractMockBuilder {
  private orders: OrderDocument[] = [];
  private contracts: ContractDocument[] = [];
  private error: Error | null = null;

  withOrder(overrides?: Partial<OrderDocument>): this {
    this.orders.push(RshopFactory.createOrder(overrides));
    return this;
  }

  withOrders(count: number, overrides?: Partial<OrderDocument>): this {
    for (let i = 0; i < count; i++) {
      this.orders.push(RshopFactory.createOrder(overrides));
    }
    return this;
  }

  withContract(overrides?: Partial<ContractDocument>): this {
    this.contracts.push(RshopFactory.createContract(overrides));
    return this;
  }

  withError(error: Error): this {
    this.error = error;
    return this;
  }

  applyTo(rshopService: Mocked<RshopService>): void {
    if (this.error) {
      rshopService.findOrders.mockRejectedValue(this.error);
      rshopService.findContracts.mockRejectedValue(this.error);
    } else {
      rshopService.findOrders.mockResolvedValue(this.orders);
      rshopService.findContracts.mockResolvedValue(this.contracts);
    }
  }
}

// Usage:
// new RshopContractMockBuilder()
//   .withOrder({ rshopId: 401, carNumber: 'CAR789', amount: 1000 })
//   .withOrder({ rshopId: 402, amount: 2000 })
//   .withContract({ dailyRate: 50 })
//   .applyTo(rshopService);
```

## Fixtures

For parameterized tests with predefined test data sets.

### Car History Fixtures
```typescript
// test/fixtures/car-history.fixtures.ts
import { HistoryEventType } from 'src/cars/schemas/car.schema';

export const validCarHistories = {
  fullLifecycle: [
    { name: HistoryEventType.REGISTRATION, date: '2024-01-01T00:00:00.000Z' },
    { name: HistoryEventType.START_OF_RENTING, date: '2024-02-01T00:00:00.000Z' },
    { name: HistoryEventType.END_OF_RENTING, date: '2024-12-01T00:00:00.000Z' },
    { name: HistoryEventType.SALE, date: '2025-01-01T00:00:00.000Z' },
  ],

  onlyRegistration: [
    { name: HistoryEventType.REGISTRATION, date: '2024-01-01T00:00:00.000Z' },
  ],

  currentlyRenting: [
    { name: HistoryEventType.REGISTRATION, date: '2024-01-01T00:00:00.000Z' },
    { name: HistoryEventType.START_OF_RENTING, date: '2024-02-01T00:00:00.000Z' },
  ],

  multipleRentingPeriods: [
    { name: HistoryEventType.REGISTRATION, date: '2024-01-01T00:00:00.000Z' },
    { name: HistoryEventType.START_OF_RENTING, date: '2024-02-01T00:00:00.000Z' },
    { name: HistoryEventType.END_OF_RENTING, date: '2024-03-01T00:00:00.000Z' },
    { name: HistoryEventType.START_OF_RENTING, date: '2024-04-01T00:00:00.000Z' },
    { name: HistoryEventType.END_OF_RENTING, date: '2024-05-01T00:00:00.000Z' },
  ],
};

export const invalidCarHistories = {
  rentingBeforeRegistration: [
    { name: HistoryEventType.START_OF_RENTING, date: '2024-01-01T00:00:00.000Z' },
    { name: HistoryEventType.REGISTRATION, date: '2024-02-01T00:00:00.000Z' },
  ],

  saleBeforeEndOfRenting: [
    { name: HistoryEventType.REGISTRATION, date: '2024-01-01T00:00:00.000Z' },
    { name: HistoryEventType.START_OF_RENTING, date: '2024-02-01T00:00:00.000Z' },
    { name: HistoryEventType.SALE, date: '2024-03-01T00:00:00.000Z' },
    { name: HistoryEventType.END_OF_RENTING, date: '2024-04-01T00:00:00.000Z' },
  ],

  duplicateRegistration: [
    { name: HistoryEventType.REGISTRATION, date: '2024-01-01T00:00:00.000Z' },
    { name: HistoryEventType.REGISTRATION, date: '2024-02-01T00:00:00.000Z' },
  ],

  endRentingWithoutStart: [
    { name: HistoryEventType.REGISTRATION, date: '2024-01-01T00:00:00.000Z' },
    { name: HistoryEventType.END_OF_RENTING, date: '2024-02-01T00:00:00.000Z' },
  ],
};
```

### Using Fixtures in Tests
```typescript
import {
  validCarHistories,
  invalidCarHistories,
} from 'test/fixtures/car-history.fixtures';

describe('Car history validation', () => {
  describe('valid histories', () => {
    test.each(Object.entries(validCarHistories))(
      'accepts %s',
      async (name, history) => {
        const car = await carsFactory.create({ history });

        await expect(service.validateHistory(car)).resolves.toBe(true);
      },
    );
  });

  describe('invalid histories', () => {
    test.each(Object.entries(invalidCarHistories))(
      'rejects %s',
      async (name, history) => {
        const car = await carsFactory.create({ history });

        await expect(service.validateHistory(car)).rejects.toThrow();
      },
    );
  });
});
```

## Static Factory Functions

For simple data objects without database persistence.

```typescript
// test/factories/static.factory.ts
import { faker } from '@faker-js/faker';

export function createCarInput(overrides = {}) {
  return {
    title: faker.vehicle.vehicle(),
    manufacturer: faker.vehicle.manufacturer(),
    price: faker.number.int({ min: 5000, max: 100000 }),
    year: faker.number.int({ min: 2015, max: 2024 }),
    ...overrides,
  };
}

export function createUserInput(overrides = {}) {
  return {
    email: faker.internet.email(),
    name: faker.person.fullName(),
    password: faker.internet.password(),
    ...overrides,
  };
}

export function createPaginationParams(overrides = {}) {
  return {
    page: 1,
    limit: 10,
    sortBy: 'createdAt',
    sortOrder: 'desc',
    ...overrides,
  };
}

// Usage:
// const input = createCarInput({ manufacturer: 'BMW' });
// const result = await service.create(input);
```

## Registering Factories in Test Module

```typescript
// test/testing-app.module.ts
import { Module } from '@nestjs/common';
import { CarsFactory } from './factories/cars.factory';
import { ContractsFactory } from './factories/contracts.factory';
import { UsersFactory } from './factories/users.factory';

@Module({
  providers: [
    CarsFactory,
    ContractsFactory,
    UsersFactory,
  ],
  exports: [
    CarsFactory,
    ContractsFactory,
    UsersFactory,
  ],
})
export class TestingAppModule {}

// In test setup:
const module = await Test.createTestingModule({
  imports: [
    DatabaseModule.forRoot(),
    CarsModule,
    TestingAppModule, // Import factories
  ],
}).compile();

const carsFactory = module.get(CarsFactory);
```

## Best Practices

### Do's
- Extend `TestDataFactory<E>` for database-backed factories
- Use `faker.js` for realistic random data
- Create convenience methods for common scenarios
- Use builders for complex entities with lifecycle
- Use fixtures for parameterized test data
- Clean database in `beforeEach` with `factory.clean()`

### Don'ts
- Don't hardcode test data values (use faker)
- Don't create deeply nested factory hierarchies
- Don't mix factory logic with test logic
- Don't forget relationships between entities
- Don't share factories between test suites without cleanup
