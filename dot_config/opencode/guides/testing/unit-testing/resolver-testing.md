# GraphQL Resolver Testing Patterns

Patterns for testing NestJS GraphQL resolvers with mocked service dependencies.

## Basic Resolver Testing

### Query Resolver Testing
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { CarsResolver } from './cars.resolver';
import { CarsService } from './cars.service';

describe('CarsResolver', () => {
  let resolver: CarsResolver;
  let service: CarsService;

  const carsService = {
    findAll: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    remove: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CarsResolver,
        {
          provide: CarsService,
          useValue: carsService,
        },
      ],
    }).compile();

    resolver = module.get<CarsResolver>(CarsResolver);
    service = module.get<CarsService>(CarsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('cars', () => {
    it('returns an array of cars', async () => {
      const cars = [{ id: '1', title: 'BMW X5' }];
      carsService.findAll.mockResolvedValue(cars);

      const result = await resolver.cars();

      expect(result).toEqual(cars);
      expect(service.findAll).toHaveBeenCalled();
    });

    it('handles filters', async () => {
      const cars = [{ id: '1', title: 'BMW X5', manufacturer: 'BMW' }];
      carsService.findAll.mockResolvedValue(cars);

      const filters = { manufacturer: 'BMW' };
      const result = await resolver.cars(filters);

      expect(result).toEqual(cars);
      expect(service.findAll).toHaveBeenCalledWith(filters);
    });
  });

  describe('car', () => {
    it('returns a single car', async () => {
      const car = { id: '1', title: 'BMW X5' };
      carsService.findOne.mockResolvedValue(car);

      const result = await resolver.car('1');

      expect(result).toEqual(car);
      expect(service.findOne).toHaveBeenCalledWith('1');
    });

    it('returns null for non-existent car', async () => {
      carsService.findOne.mockResolvedValue(null);

      const result = await resolver.car('999');

      expect(result).toBeNull();
      expect(service.findOne).toHaveBeenCalledWith('999');
    });
  });
});
```

### Mutation Resolver Testing
```typescript
describe('Mutations', () => {
  describe('createCar', () => {
    it('creates a new car', async () => {
      const createCarInput = {
        title: 'BMW X5',
        price: 25000,
        manufacturer: 'BMW',
      };
      const car = { id: '1', ...createCarInput };
      carsService.create.mockResolvedValue(car);

      const result = await resolver.createCar(createCarInput);

      expect(result).toEqual(car);
      expect(service.create).toHaveBeenCalledWith(createCarInput);
    });

    it('handles validation errors', async () => {
      const invalidInput = { title: '', price: -1000 };
      carsService.create.mockRejectedValue(
        new Error('Validation failed')
      );

      await expect(resolver.createCar(invalidInput))
        .rejects.toThrow('Validation failed');
    });
  });

  describe('updateCar', () => {
    it('updates existing car', async () => {
      const updateInput = { title: 'Updated BMW X5' };
      const car = { id: '1', title: 'Updated BMW X5', price: 25000 };
      carsService.update.mockResolvedValue(car);

      const result = await resolver.updateCar('1', updateInput);

      expect(result).toEqual(car);
      expect(service.update).toHaveBeenCalledWith('1', updateInput);
    });
  });

  describe('deleteCar', () => {
    it('deletes car', async () => {
      carsService.remove.mockResolvedValue(true);

      const result = await resolver.deleteCar('1');

      expect(result).toBe(true);
      expect(service.remove).toHaveBeenCalledWith('1');
    });
  });
});
```

## DataLoader Testing

### Resolver with DataLoader
```typescript
import { DataLoader } from 'dataloader';

describe('CarsResolver with DataLoader', () => {
  let resolver: CarsResolver;
  let carLoader: DataLoader<string, Car>;

  const carLoader = {
    load: jest.fn(),
    loadMany: jest.fn(),
    clear: jest.fn(),
    clearAll: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CarsResolver,
        {
          provide: 'CAR_LOADER',
          useValue: carLoader,
        },
      ],
    }).compile();

    resolver = module.get<CarsResolver>(CarsResolver);
    carLoader = module.get<DataLoader<string, Car>>('CAR_LOADER');
  });

  it('uses DataLoader to fetch car', async () => {
    const car = { id: '1', title: 'BMW X5' };
    carLoader.load.mockResolvedValue(car);

    const result = await resolver.car('1');

    expect(result).toEqual(car);
    expect(carLoader.load).toHaveBeenCalledWith('1');
  });

  it('batches load multiple cars', async () => {
    const cars = [
      { id: '1', title: 'BMW X5' },
      { id: '2', title: 'Audi A4' },
    ];
    carLoader.loadMany.mockResolvedValue(cars);

    const result = await resolver.carsByIds(['1', '2']);

    expect(result).toEqual(cars);
    expect(carLoader.loadMany).toHaveBeenCalledWith(['1', '2']);
  });
});
```

## Field Resolver Testing

### Related Entity Resolution
```typescript
describe('Field Resolvers', () => {
  const manufacturerService = {
    findOne: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CarsResolver,
        {
          provide: CarsService,
          useValue: carsService,
        },
        {
          provide: ManufacturerService,
          useValue: manufacturerService,
        },
      ],
    }).compile();

    resolver = module.get<CarsResolver>(CarsResolver);
  });

  describe('manufacturer', () => {
    it('resolves manufacturer for car', async () => {
      const car = { id: '1', manufacturerId: 'bmw-1' };
      const manufacturer = { id: 'bmw-1', name: 'BMW' };
      
      manufacturerService.findOne.mockResolvedValue(manufacturer);

      const result = await resolver.manufacturer(car);

      expect(result).toEqual(manufacturer);
      expect(manufacturerService.findOne).toHaveBeenCalledWith('bmw-1');
    });

    it('handles missing manufacturer', async () => {
      const car = { id: '1', manufacturerId: 'non-existent' };
      manufacturerService.findOne.mockResolvedValue(null);

      const result = await resolver.manufacturer(car);

      expect(result).toBeNull();
    });
  });

  describe('images', () => {
    it('resolves images for car', async () => {
      const car = { id: '1' };
      const mockImages = [
        { id: '1', url: 'image1.jpg', carId: '1' },
        { id: '2', url: 'image2.jpg', carId: '1' },
      ];

      const mockImageService = {
        findByCarId: jest.fn().mockResolvedValue(mockImages),
      };

      // Add ImageService to module providers
      const result = await resolver.images(car);

      expect(result).toEqual(mockImages);
    });
  });
});
```

## Context and Authentication

### GraphQL Context Testing
```typescript
describe('Authentication Context', () => {
  it('accesses user from context', async () => {
    const mockContext = {
      req: {
        user: { id: '1', email: 'admin@example.com', role: 'admin' },
      },
    };

    const createCarInput = { title: 'BMW X5', price: 25000 };
    const car = { id: '1', ...createCarInput, ownerId: '1' };
    
    carsService.create.mockResolvedValue(car);

    const result = await resolver.createCar(createCarInput, mockContext);

    expect(result).toEqual(car);
    expect(service.create).toHaveBeenCalledWith({
      ...createCarInput,
      ownerId: '1',
    });
  });

  it('handles unauthenticated requests', async () => {
    const mockContext = { req: {} }; // No user in context

    const createCarInput = { title: 'BMW X5', price: 25000 };

    await expect(resolver.createCar(createCarInput, mockContext))
      .rejects.toThrow('Unauthorized');
  });
});
```

### Role-Based Authorization
```typescript
describe('Authorization', () => {
  it('allows admin to create cars', async () => {
    const mockContext = {
      req: { user: { id: '1', role: 'admin' } },
    };

    const createCarInput = { title: 'BMW X5', price: 25000 };
    const car = { id: '1', ...createCarInput };
    carsService.create.mockResolvedValue(car);

    const result = await resolver.createCar(createCarInput, mockContext);

    expect(result).toEqual(car);
  });

  it('deny regular user from creating cars', async () => {
    const mockContext = {
      req: { user: { id: '2', role: 'user' } },
    };

    const createCarInput = { title: 'BMW X5', price: 25000 };

    await expect(resolver.createCar(createCarInput, mockContext))
      .rejects.toThrow('Forbidden');
  });
});
```

## Subscription Testing

### GraphQL Subscriptions
```typescript
import { PubSub } from 'graphql-subscriptions';

describe('Subscriptions', () => {
  let pubSub: PubSub;

  const mockPubSub = {
    publish: jest.fn(),
    subscribe: jest.fn(),
    asyncIterator: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CarsResolver,
        {
          provide: CarsService,
          useValue: carsService,
        },
        {
          provide: 'PUB_SUB',
          useValue: mockPubSub,
        },
      ],
    }).compile();

    resolver = module.get<CarsResolver>(CarsResolver);
    pubSub = module.get<PubSub>('PUB_SUB');
  });

  describe('carAdded', () => {
    it('returns async iterator for car additions', () => {
      const mockIterator = Symbol('async-iterator');
      mockPubSub.asyncIterator.mockReturnValue(mockIterator);

      const result = resolver.carAdded();

      expect(result).toBe(mockIterator);
      expect(pubSub.asyncIterator).toHaveBeenCalledWith('carAdded');
    });
  });

  it('publish car creation event', async () => {
    const createCarInput = { title: 'BMW X5', price: 25000 };
    const car = { id: '1', ...createCarInput };
    carsService.create.mockResolvedValue(car);

    await resolver.createCar(createCarInput);

    expect(pubSub.publish).toHaveBeenCalledWith('carAdded', {
      carAdded: car,
    });
  });
});
```

## Best Practices

### ✅ Do's
- Mock service dependencies completely
- Test GraphQL-specific logic (field resolution, context)
- Test DataLoader integration
- Test authentication and authorization
- Test subscription publishing
- Use descriptive test names
- Clear mocks between tests

### ❌ Don'ts
- Don't test business logic in resolver tests
- Don't use real services or databases
- Don't test GraphQL framework functionality
- Don't ignore error scenarios
- Don't test private methods
- Don't make tests dependent on each other