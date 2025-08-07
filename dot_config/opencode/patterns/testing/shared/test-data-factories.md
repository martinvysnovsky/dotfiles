# Test Data Factories

Patterns for creating realistic test data using factories and builders.

## Factory Pattern

### Basic Factory
```typescript
// test/factories/cars.factory.ts
import { faker } from '@faker-js/faker';
import { Car } from '../../src/cars/entities/car.entity';

export class CarsFactory {
  static create(overrides: Partial<Car> = {}): Car {
    return {
      id: faker.string.uuid(),
      title: faker.vehicle.vehicle(),
      manufacturer: faker.vehicle.manufacturer(),
      price: faker.number.int({ min: 5000, max: 100000 }),
      year: faker.number.int({ min: 2000, max: 2024 }),
      mileage: faker.number.int({ min: 0, max: 300000 }),
      fuel: faker.helpers.arrayElement(['petrol', 'diesel', 'electric']),
      active: true,
      createdAt: faker.date.past(),
      updatedAt: faker.date.recent(),
      ...overrides,
    };
  }

  static createMany(count: number, overrides: Partial<Car> = {}): Car[] {
    return Array.from({ length: count }, () => this.create(overrides));
  }

  static createBMW(): Car {
    return this.create({
      manufacturer: 'BMW',
      title: 'BMW X5',
      price: 45000,
    });
  }
}
```

## Builder Pattern

### Test Data Builder
```typescript
export class CarBuilder {
  private car: Partial<Car> = {};

  static aCar(): CarBuilder {
    return new CarBuilder();
  }

  withTitle(title: string): CarBuilder {
    this.car.title = title;
    return this;
  }

  withPrice(price: number): CarBuilder {
    this.car.price = price;
    return this;
  }

  withManufacturer(manufacturer: string): CarBuilder {
    this.car.manufacturer = manufacturer;
    return this;
  }

  build(): Car {
    return {
      id: faker.string.uuid(),
      title: 'Default Car',
      price: 20000,
      manufacturer: 'Default',
      active: true,
      ...this.car,
    } as Car;
  }
}

// Usage in tests
const car = CarBuilder.aCar()
  .withTitle('BMW X5')
  .withPrice(45000)
  .withManufacturer('BMW')
  .build();
```

## Database Factory (E2E Testing)

### Injectable Factory for Real Database
```typescript
// test/factories/cars.factory.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { faker } from '@faker-js/faker';

import { Car } from '../../src/cars/entities/car.entity';

@Injectable()
export class CarsFactory {
  constructor(
    @InjectRepository(Car)
    private readonly carsRepository: Repository<Car>,
  ) {}

  async create(overrides: Partial<Car> = {}): Promise<Car> {
    const carData = {
      title: faker.vehicle.vehicle(),
      manufacturer: faker.vehicle.manufacturer(),
      price: faker.number.int({ min: 5000, max: 100000 }),
      year: faker.number.int({ min: 2000, max: 2024 }),
      mileage: faker.number.int({ min: 0, max: 300000 }),
      fuel: faker.helpers.arrayElement(['petrol', 'diesel', 'electric']),
      bodyType: faker.helpers.arrayElement(['sedan', 'suv', 'hatchback']),
      active: true,
      ...overrides,
    };

    const car = this.carsRepository.create(carData);
    return await this.carsRepository.save(car);
  }

  async createMany(count: number, overrides: Partial<Car> = {}): Promise<Car[]> {
    const cars = [];
    for (let i = 0; i < count; i++) {
      cars.push(await this.create(overrides));
    }
    return cars;
  }
}
```

## Best Practices

### ✅ Do's
- Use faker.js for realistic test data
- Create specific factory methods for common scenarios
- Use builder pattern for complex object construction
- Keep factories simple and focused

### ❌ Don'ts
- Don't hardcode test data values
- Don't create overly complex factory hierarchies
- Don't mix factory logic with test logic
- Don't forget to handle relationships between entities