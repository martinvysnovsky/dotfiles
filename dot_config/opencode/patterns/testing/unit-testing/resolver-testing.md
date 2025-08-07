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

  const mockCarsService = {
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
          useValue: mockCarsService,
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
    it('should return an array of cars', async () => {
      const mockCars = [{ id: '1', title: 'BMW X5' }];
      mockCarsService.findAll.mockResolvedValue(mockCars);

      const result = await resolver.cars();

      expect(result).toEqual(mockCars);
      expect(service.findAll).toHaveBeenCalled();
    });

    it('should handle filters', async () => {
      const mockCars = [{ id: '1', title: 'BMW X5', manufacturer: 'BMW' }];
      mockCarsService.findAll.mockResolvedValue(mockCars);

      const filters = { manufacturer: 'BMW' };
      const result = await resolver.cars(filters);

      expect(result).toEqual(mockCars);
      expect(service.findAll).toHaveBeenCalledWith(filters);
    });
  });

  describe('car', () => {
    it('should return a single car', async () => {
      const mockCar = { id: '1', title: 'BMW X5' };
      mockCarsService.findOne.mockResolvedValue(mockCar);

      const result = await resolver.car('1');

      expect(result).toEqual(mockCar);
      expect(service.findOne).toHaveBeenCalledWith('1');
    });

    it('should return null for non-existent car', async () => {
      mockCarsService.findOne.mockResolvedValue(null);

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
    it('should create a new car', async () => {
      const createCarInput = {
        title: 'BMW X5',
        price: 25000,
        manufacturer: 'BMW',
      };
      const mockCar = { id: '1', ...createCarInput };
      mockCarsService.create.mockResolvedValue(mockCar);

      const result = await resolver.createCar(createCarInput);

      expect(result).toEqual(mockCar);
      expect(service.create).toHaveBeenCalledWith(createCarInput);
    });

    it('should handle validation errors', async () => {
      const invalidInput = { title: '', price: -1000 };
      mockCarsService.create.mockRejectedValue(
        new Error('Validation failed')
      );

      await expect(resolver.createCar(invalidInput))
        .rejects.toThrow('Validation failed');
    });
  });

  describe('updateCar', () => {
    it('should update existing car', async () => {
      const updateInput = { title: 'Updated BMW X5' };
      const mockCar = { id: '1', title: 'Updated BMW X5', price: 25000 };
      mockCarsService.update.mockResolvedValue(mockCar);

      const result = await resolver.updateCar('1', updateInput);

      expect(result).toEqual(mockCar);
      expect(service.update).toHaveBeenCalledWith('1', updateInput);
    });
  });

  describe('deleteCar', () => {
    it('should delete car', async () => {
      mockCarsService.remove.mockResolvedValue(true);

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

  const mockCarLoader = {
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
          useValue: mockCarLoader,
        },
      ],
    }).compile();

    resolver = module.get<CarsResolver>(CarsResolver);
    carLoader = module.get<DataLoader<string, Car>>('CAR_LOADER');
  });

  it('should use DataLoader to fetch car', async () => {
    const mockCar = { id: '1', title: 'BMW X5' };
    mockCarLoader.load.mockResolvedValue(mockCar);

    const result = await resolver.car('1');

    expect(result).toEqual(mockCar);
    expect(carLoader.load).toHaveBeenCalledWith('1');
  });

  it('should batch load multiple cars', async () => {
    const mockCars = [
      { id: '1', title: 'BMW X5' },
      { id: '2', title: 'Audi A4' },
    ];
    mockCarLoader.loadMany.mockResolvedValue(mockCars);

    const result = await resolver.carsByIds(['1', '2']);

    expect(result).toEqual(mockCars);
    expect(carLoader.loadMany).toHaveBeenCalledWith(['1', '2']);
  });
});
```

## Field Resolver Testing

### Related Entity Resolution
```typescript
describe('Field Resolvers', () => {
  const mockManufacturerService = {
    findOne: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CarsResolver,
        {
          provide: CarsService,
          useValue: mockCarsService,
        },
        {
          provide: ManufacturerService,
          useValue: mockManufacturerService,
        },
      ],
    }).compile();

    resolver = module.get<CarsResolver>(CarsResolver);
  });

  describe('manufacturer', () => {
    it('should resolve manufacturer for car', async () => {
      const mockCar = { id: '1', manufacturerId: 'bmw-1' };
      const mockManufacturer = { id: 'bmw-1', name: 'BMW' };
      
      mockManufacturerService.findOne.mockResolvedValue(mockManufacturer);

      const result = await resolver.manufacturer(mockCar);

      expect(result).toEqual(mockManufacturer);
      expect(mockManufacturerService.findOne).toHaveBeenCalledWith('bmw-1');
    });

    it('should handle missing manufacturer', async () => {
      const mockCar = { id: '1', manufacturerId: 'non-existent' };
      mockManufacturerService.findOne.mockResolvedValue(null);

      const result = await resolver.manufacturer(mockCar);

      expect(result).toBeNull();
    });
  });

  describe('images', () => {
    it('should resolve images for car', async () => {
      const mockCar = { id: '1' };
      const mockImages = [
        { id: '1', url: 'image1.jpg', carId: '1' },
        { id: '2', url: 'image2.jpg', carId: '1' },
      ];

      const mockImageService = {
        findByCarId: jest.fn().mockResolvedValue(mockImages),
      };

      // Add ImageService to module providers
      const result = await resolver.images(mockCar);

      expect(result).toEqual(mockImages);
    });
  });
});
```

## Context and Authentication

### GraphQL Context Testing
```typescript
describe('Authentication Context', () => {
  it('should access user from context', async () => {
    const mockContext = {
      req: {
        user: { id: '1', email: 'admin@example.com', role: 'admin' },
      },
    };

    const createCarInput = { title: 'BMW X5', price: 25000 };
    const mockCar = { id: '1', ...createCarInput, ownerId: '1' };
    
    mockCarsService.create.mockResolvedValue(mockCar);

    const result = await resolver.createCar(createCarInput, mockContext);

    expect(result).toEqual(mockCar);
    expect(service.create).toHaveBeenCalledWith({
      ...createCarInput,
      ownerId: '1',
    });
  });

  it('should handle unauthenticated requests', async () => {
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
  it('should allow admin to create cars', async () => {
    const mockContext = {
      req: { user: { id: '1', role: 'admin' } },
    };

    const createCarInput = { title: 'BMW X5', price: 25000 };
    const mockCar = { id: '1', ...createCarInput };
    mockCarsService.create.mockResolvedValue(mockCar);

    const result = await resolver.createCar(createCarInput, mockContext);

    expect(result).toEqual(mockCar);
  });

  it('should deny regular user from creating cars', async () => {
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
          useValue: mockCarsService,
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
    it('should return async iterator for car additions', () => {
      const mockIterator = Symbol('async-iterator');
      mockPubSub.asyncIterator.mockReturnValue(mockIterator);

      const result = resolver.carAdded();

      expect(result).toBe(mockIterator);
      expect(pubSub.asyncIterator).toHaveBeenCalledWith('carAdded');
    });
  });

  it('should publish car creation event', async () => {
    const createCarInput = { title: 'BMW X5', price: 25000 };
    const mockCar = { id: '1', ...createCarInput };
    mockCarsService.create.mockResolvedValue(mockCar);

    await resolver.createCar(createCarInput);

    expect(pubSub.publish).toHaveBeenCalledWith('carAdded', {
      carAdded: mockCar,
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