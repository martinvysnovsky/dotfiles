# Service Testing Patterns

## Unit Testing with Mocked Dependencies

### Basic Service Test Setup

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { CarService } from './car.service';
import { Car } from 'src/generated/entities';
import { CarTypeService } from '../car-type/car-type.service';
import { LoggerService } from 'src/common/logger/logger.service';

describe('CarService', () => {
  let service: CarService;
  let carRepository: MockRepository<Car>;
  let carTypeService: Partial<CarTypeService>;
  let loggerService: Partial<LoggerService>;

  beforeEach(async () => {
    // Create mock repository
    carRepository = {
      findOne: jest.fn(),
      find: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
      createQueryBuilder: jest.fn(),
    };

    // Create mock services
    carTypeService = {
      findOne: jest.fn(),
    };

    loggerService = {
      notifyError: jest.fn(),
      notifyInfo: jest.fn(),
      warn: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CarService,
        {
          provide: getRepositoryToken(Car),
          useValue: carRepository,
        },
        {
          provide: CarTypeService,
          useValue: carTypeService,
        },
        {
          provide: LoggerService,
          useValue: loggerService,
        },
      ],
    }).compile();

    service = module.get<CarService>(CarService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findOne', () => {
    it('returns car when found', async () => {
      const car = { id: '1', title: 'BMW X5', price: 50000 };
      carRepository.findOne.mockResolvedValue(car);

      const result = await service.findOne('1');

      expect(result).toEqual(car);
      expect(carRepository.findOne).toHaveBeenCalledWith({
        where: { id: '1' },
        relations: expect.any(Array)
      });
    });

    it('throws NotFoundException when car not found', async () => {
      carRepository.findOne.mockResolvedValue(null);

      await expect(service.findOne('999'))
        .rejects
        .toThrow('Car not found');
    });
  });

  describe('create', () => {
    it('creates new car with valid data', async () => {
      const input = {
        title: 'BMW X5',
        price: 50000,
        carTypeId: '1',
        year: 2023
      };
      
      const carType = { id: '1', name: 'SUV' };
      const car = { id: '1', ...input, carType };

      carTypeService.findOne.mockResolvedValue(carType);
      carRepository.findOne.mockResolvedValue(null); // No existing car
      carRepository.create.mockReturnValue(car);
      carRepository.save.mockResolvedValue(car);

      const result = await service.create(input);

      expect(result).toEqual(car);
      expect(carTypeService.findOne).toHaveBeenCalledWith('1');
      expect(carRepository.save).toHaveBeenCalledWith(car);
    });

    it('throws BadRequestException when car type not found', async () => {
      const input = { title: 'BMW X5', carTypeId: '999' };
      
      carTypeService.findOne.mockResolvedValue(null);

      await expect(service.create(input))
        .rejects
        .toThrow('Car type not found');
    });

    it('validates business rules', async () => {
      const input = {
        title: 'BMW X5',
        carTypeId: '1',
        year: new Date().getFullYear() + 2 // Invalid year
      };

      const carType = { id: '1', name: 'SUV' };
      carTypeService.findOne.mockResolvedValue(carType);

      await expect(service.create(input))
        .rejects
        .toThrow('Car year cannot be more than one year in the future');
    });
  });

  describe('update', () => {
    it('updates existing car', async () => {
      const car = { id: '1', title: 'BMW X5', price: 50000 };
      const updates = { price: 55000 };
      const updated = { ...car, ...updates };

      carRepository.findOne.mockResolvedValue(car);
      carRepository.save.mockResolvedValue(updated);

      const result = await service.update('1', updates);

      expect(result.price).toBe(55000);
      expect(carRepository.save).toHaveBeenCalled();
    });
  });

  describe('delete', () => {
    it('deletes existing car', async () => {
      const car = { id: '1', title: 'BMW X5' };
      carRepository.findOne.mockResolvedValue(car);
      carRepository.remove.mockResolvedValue(car);

      await service.delete('1');

      expect(carRepository.remove).toHaveBeenCalledWith(car);
    });
  });
});
```

## Testing with Query Builder

```typescript
describe('findWithFilters', () => {
  let queryBuilder: any;

  beforeEach(() => {
    queryBuilder = {
      leftJoinAndSelect: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      getMany: jest.fn(),
      getCount: jest.fn(),
      skip: jest.fn().mockReturnThis(),
      take: jest.fn().mockReturnThis(),
    };

    carRepository.createQueryBuilder.mockReturnValue(queryBuilder);
  });

  it('applies manufacturer filter', async () => {
    const filters = { manufacturer: 'BMW' };
    const cars = [{ id: '1', manufacturer: 'BMW' }];
    
    queryBuilder.getMany.mockResolvedValue(cars);

    await service.findWithFilters(filters);

    expect(queryBuilder.andWhere).toHaveBeenCalledWith(
      'car.manufacturer = :manufacturer',
      { manufacturer: 'BMW' }
    );
  });

  it('applies multiple filters', async () => {
    const filters = {
      manufacturer: 'BMW',
      yearFrom: 2020,
      yearTo: 2023
    };

    queryBuilder.getMany.mockResolvedValue([]);

    await service.findWithFilters(filters);

    expect(queryBuilder.andWhere).toHaveBeenCalledTimes(3);
  });
});
```

## Testing Transactions

```typescript
describe('processRentalEnd', () => {
  let transactionManager: any;

  beforeEach(() => {
    transactionManager = {
      findOne: jest.fn(),
      save: jest.fn(),
      create: jest.fn(),
    };

    carRepository.manager = {
      transaction: jest.fn((callback) => callback(transactionManager))
    };
  });

  it('processes rental end in transaction', async () => {
    const car = { 
      id: '1', 
      status: CarStatus.RENTED 
    };
    const endDate = new Date();

    transactionManager.findOne.mockResolvedValue(car);
    transactionManager.save.mockResolvedValue({ 
      ...car, 
      status: CarStatus.AVAILABLE 
    });
    transactionManager.create.mockReturnValue({ carId: '1' });

    await service.processRentalEnd('1', endDate);

    expect(transactionManager.findOne).toHaveBeenCalledWith(
      Car, 
      { where: { id: '1' } }
    );
    expect(transactionManager.save).toHaveBeenCalled();
    expect(loggerService.notifyInfo).toHaveBeenCalledWith(
      'Rental period ended successfully',
      expect.any(Object)
    );
  });

  it('throws NotFoundException when car not found', async () => {
    transactionManager.findOne.mockResolvedValue(null);

    await expect(service.processRentalEnd('999', new Date()))
      .rejects
      .toThrow('Car not found');
  });
});
```

## Testing Error Handling

```typescript
describe('error handling', () => {
  it('logs errors in background jobs', async () => {
    const error = new Error('External API failed');
    
    jest.spyOn(service as any, 'callExternalApi')
      .mockRejectedValue(error);

    await expect(service.syncWithExternalSystem('1'))
      .rejects
      .toThrow('External API failed');

    expect(loggerService.notifyError).toHaveBeenCalledWith(
      error,
      expect.objectContaining({
        context: expect.any(Object)
      })
    );
  });

  it('does not log errors for standard operations', async () => {
    carRepository.findOne.mockResolvedValue(null);

    await expect(service.findOne('999'))
      .rejects
      .toThrow();

    // LoggerService should NOT be called for standard exceptions
    expect(loggerService.notifyError).not.toHaveBeenCalled();
  });
});
```

## Testing with Partial Mocks

```typescript
describe('with partial mocks', () => {
  it('uses partial mock for optional service', async () => {
    const externalApiService = {
      syncCar: jest.fn().mockResolvedValue(undefined)
    };

    // Create service with optional dependency
    const moduleWithOptional = await Test.createTestingModule({
      providers: [
        CarService,
        {
          provide: getRepositoryToken(Car),
          useValue: carRepository,
        },
        {
          provide: 'ExternalApiService',
          useValue: externalApiService,
        },
      ],
    }).compile();

    const serviceWithApi = moduleWithOptional.get<CarService>(CarService);

    await serviceWithApi.syncWithExternalSystem('1');

    expect(externalApiService.syncCar).toHaveBeenCalledWith('1');
  });
});
```

## Mock Type Helper

```typescript
type MockRepository<T = any> = Partial<Record<keyof Repository<T>, jest.Mock>>;

type MockService<T = any> = Partial<Record<keyof T, jest.Mock>>;

// Usage
let carRepository: MockRepository<Car>;
let carTypeService: MockService<CarTypeService>;
```

## Test Data Factory Pattern

```typescript
class CarTestFactory {
  static createCar(overrides?: Partial<Car>): Car {
    return {
      id: '1',
      title: 'BMW X5',
      manufacturer: 'BMW',
      price: 50000,
      year: 2023,
      status: CarStatus.AVAILABLE,
      createdAt: new Date(),
      modifiedAt: new Date(),
      ...overrides
    };
  }

  static createInput(overrides?: Partial<CreateCarInput>): CreateCarInput {
    return {
      title: 'BMW X5',
      manufacturer: 'BMW',
      price: 50000,
      year: 2023,
      carTypeId: '1',
      ...overrides
    };
  }
}

// Usage in tests
it('creates car', async () => {
  const input = CarTestFactory.createInput({ price: 60000 });
  const car = CarTestFactory.createCar({ price: 60000 });
  
  carRepository.create.mockReturnValue(car);
  carRepository.save.mockResolvedValue(car);

  const result = await service.create(input);
  expect(result.price).toBe(60000);
});
```

## Testing Best Practices

### Test Descriptions
Use direct statements without "should":
```typescript
// ✅ Good
it('returns car when found', async () => {});
it('throws NotFoundException when car not found', async () => {});

// ❌ Avoid
it('should return car when found', async () => {});
it('should throw NotFoundException', async () => {});
```

### Variable Naming
Use simple, descriptive names without "mock" prefix:
```typescript
// ✅ Good
const car = { id: '1', title: 'BMW X5' };
const input = { title: 'BMW X5', price: 50000 };

// ❌ Avoid
const mockCar = { id: '1', title: 'BMW X5' };
const mockInput = { title: 'BMW X5', price: 50000 };
```

### Arrange-Act-Assert Pattern
```typescript
it('creates new car', async () => {
  // Arrange
  const input = CarTestFactory.createInput();
  const carType = { id: '1', name: 'SUV' };
  carTypeService.findOne.mockResolvedValue(carType);
  carRepository.create.mockReturnValue({ ...input, id: '1' });
  
  // Act
  const result = await service.create(input);
  
  // Assert
  expect(result.id).toBe('1');
  expect(carRepository.save).toHaveBeenCalled();
});
```
