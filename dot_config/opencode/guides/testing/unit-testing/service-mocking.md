# Service Testing with Mocks

Patterns for testing NestJS services using mocks for all external dependencies.

## Basic Service Testing

### TypeORM Repository Mocking
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CarsService } from './cars.service';
import { Car } from './entities/car.entity';
import { CreateCarDto } from './dto/create-car.dto';

describe('CarsService', () => {
  let service: CarsService;
  let repository: Repository<Car>;

  const mockRepository = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CarsService,
        {
          provide: getRepositoryToken(Car),
          useValue: mockRepository,
        },
      ],
    }).compile();

    service = module.get<CarsService>(CarsService);
    repository = module.get<Repository<Car>>(getRepositoryToken(Car));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findAll', () => {
    it('returns an array of cars', async () => {
      const cars = [
        { id: '1', title: 'BMW X5', price: 25000 },
        { id: '2', title: 'Audi A4', price: 20000 },
      ];

      mockRepository.find.mockResolvedValue(cars);

      const result = await service.findAll();

      expect(result).toEqual(cars);
      expect(repository.find).toHaveBeenCalledWith({
        where: { active: true },
        order: { createdAt: 'DESC' },
      });
    });
  });
});
```

### Mongoose Model Mocking
```typescript
import { getModelToken } from '@nestjs/mongoose';
import { Model } from 'mongoose';

describe('CarsService with Mongoose', () => {
  let service: CarsService;
  let model: Model<Car>;

  const mockModel = {
    find: jest.fn(),
    findById: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    findByIdAndUpdate: jest.fn(),
    findByIdAndDelete: jest.fn(),
    exec: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CarsService,
        {
          provide: getModelToken(Car.name),
          useValue: mockModel,
        },
      ],
    }).compile();

    service = module.get<CarsService>(CarsService);
    model = module.get<Model<Car>>(getModelToken(Car.name));
  });

  it('find cars with Mongoose', async () => {
    const cars = [{ _id: '1', title: 'BMW X5' }];
    mockModel.find.mockReturnValue({
      exec: jest.fn().mockResolvedValue(cars),
    });

    const result = await service.findAll();

    expect(result).toEqual(cars);
    expect(model.find).toHaveBeenCalledWith({ active: true });
  });
});
```

## Complex Query Builder Mocking

### TypeORM Query Builder
```typescript
import { Repository, SelectQueryBuilder } from 'typeorm';

describe('CarsService with QueryBuilder', () => {
  let service: CarsService;
  let repository: Repository<Car>;

  const mockQueryBuilder = {
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    offset: jest.fn().mockReturnThis(),
    getMany: jest.fn(),
    getOne: jest.fn(),
  };

  const mockRepository = {
    createQueryBuilder: jest.fn(() => mockQueryBuilder),
    find: jest.fn(),
    findOne: jest.fn(),
    save: jest.fn(),
    create: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CarsService,
        {
          provide: getRepositoryToken(Car),
          useValue: mockRepository,
        },
      ],
    }).compile();

    service = module.get<CarsService>(CarsService);
    repository = module.get<Repository<Car>>(getRepositoryToken(Car));
  });

  it('build complex queries', async () => {
    const cars = [{ id: '1', title: 'BMW X5' }];
    mockQueryBuilder.getMany.mockResolvedValue(cars);

    const result = await service.findWithFilters({ manufacturer: 'BMW' });

    expect(repository.createQueryBuilder).toHaveBeenCalledWith('car');
    expect(mockQueryBuilder.where).toHaveBeenCalledWith('car.active = :active', { active: true });
    expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith('car.manufacturer = :manufacturer', { manufacturer: 'BMW' });
  });
});
```

## External Service Dependencies

### HTTP Client Mocking
```typescript
import { HttpService } from '@nestjs/axios';
import { of } from 'rxjs';

describe('CarsService with HTTP Client', () => {
  let service: CarsService;
  let httpService: HttpService;

  const mockHttpService = {
    get: jest.fn(),
    post: jest.fn(),
    put: jest.fn(),
    delete: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CarsService,
        {
          provide: HttpService,
          useValue: mockHttpService,
        },
      ],
    }).compile();

    service = module.get<CarsService>(CarsService);
    httpService = module.get<HttpService>(HttpService);
  });

  it('fetch external car data', async () => {
    const externalData = { id: 'ext-1', title: 'External Car' };
    mockHttpService.get.mockReturnValue(of({ data: externalData }));

    const result = await service.fetchExternalCar('ext-1');

    expect(result).toEqual(externalData);
    expect(httpService.get).toHaveBeenCalledWith('/external/cars/ext-1');
  });
});
```

### Configuration Service Mocking
```typescript
import { ConfigService } from '@nestjs/config';

describe('CarsService with Config', () => {
  let service: CarsService;
  let configService: ConfigService;

  const mockConfigService = {
    get: jest.fn(),
    getOrThrow: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CarsService,
        {
          provide: getRepositoryToken(Car),
          useValue: mockRepository,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
      ],
    }).compile();

    service = module.get<CarsService>(CarsService);
    configService = module.get<ConfigService>(ConfigService);
  });

  it('uses configuration values', async () => {
    mockConfigService.get.mockReturnValue(10);

    const result = await service.findAll();

    expect(configService.get).toHaveBeenCalledWith('CARS_PER_PAGE');
  });
});
```

## Error Handling Testing

### Exception Testing
```typescript
describe('Error handling', () => {
  it('handles database connection errors', async () => {
    mockRepository.find.mockRejectedValue(new Error('Database connection failed'));

    await expect(service.findAll()).rejects.toThrow('Database connection failed');
  });

  it('handles validation errors', async () => {
    const invalidDto = { price: -1000 };

    await expect(service.create(invalidDto as CreateCarDto))
      .rejects.toThrow('Validation failed');
  });

  it('handles not found errors', async () => {
    mockRepository.findOne.mockResolvedValue(null);

    await expect(service.findOne('999')).rejects.toThrow('Car not found');
  });
});
```

### Async Operation Testing
```typescript
describe('Async operations', () => {
  it('handles concurrent requests', async () => {
    const promises = Array.from({ length: 10 }, (_, i) => 
      service.findOne(String(i + 1))
    );

    mockRepository.findOne.mockImplementation((options) => 
      Promise.resolve({ id: options.where.id, title: `Car ${options.where.id}` })
    );

    const results = await Promise.all(promises);

    expect(results).toHaveLength(10);
    expect(repository.findOne).toHaveBeenCalledTimes(10);
  });
});
```

## Best Practices

### ✅ Do's
- Mock all external dependencies
- Use descriptive test names
- Test both success and error scenarios
- Clear mocks between tests
- Test business logic, not implementation details

### ❌ Don'ts
- Don't test private methods directly
- Don't use real databases in unit tests
- Don't make tests dependent on each other
- Don't ignore error cases
- Don't test framework code