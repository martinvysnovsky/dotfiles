# Controller Testing Patterns

Patterns for testing NestJS REST controllers with mocked service dependencies.

## Basic Controller Testing

### REST Controller Testing
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { CarsController } from './cars.controller';
import { CarsService } from './cars.service';

describe('CarsController', () => {
  let controller: CarsController;
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
      controllers: [CarsController],
      providers: [
        {
          provide: CarsService,
          useValue: carsService,
        },
      ],
    }).compile();

    controller = module.get<CarsController>(CarsController);
    service = module.get<CarsService>(CarsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findAll', () => {
    it('returns an array of cars', async () => {
      const cars = [{ id: '1', title: 'BMW X5' }];
      carsService.findAll.mockResolvedValue(cars);

      const result = await controller.findAll();

      expect(result).toEqual(cars);
      expect(service.findAll).toHaveBeenCalled();
    });
  });

  describe('findOne', () => {
    it('returns a single car', async () => {
      const car = { id: '1', title: 'BMW X5' };
      carsService.findOne.mockResolvedValue(car);

      const result = await controller.findOne('1');

      expect(result).toEqual(car);
      expect(service.findOne).toHaveBeenCalledWith('1');
    });
  });

  describe('create', () => {
    it('creates a new car', async () => {
      const createCarDto = { title: 'BMW X5', price: 25000 };
      const car = { id: '1', ...createCarDto };
      carsService.create.mockResolvedValue(car);

      const result = await controller.create(createCarDto);

      expect(result).toEqual(car);
      expect(service.create).toHaveBeenCalledWith(createCarDto);
    });
  });
});
```

## Authentication Testing

### JWT Guard Testing
```typescript
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ExecutionContext } from '@nestjs/common';

describe('Protected Controller', () => {
  let controller: CarsController;
  let guard: JwtAuthGuard;

  const mockExecutionContext = {
    switchToHttp: jest.fn(() => ({
      getRequest: jest.fn(() => ({
        user: { id: '1', email: 'admin@example.com' },
      })),
    })),
  } as unknown as ExecutionContext;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CarsController],
      providers: [
        {
          provide: CarsService,
          useValue: carsService,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({
        canActivate: jest.fn(() => true),
      })
      .compile();

    controller = module.get<CarsController>(CarsController);
  });

  it('allows access with valid JWT', async () => {
    const result = await controller.create(mockCreateCarDto);
    expect(result).toBeDefined();
  });
});
```

### Role-Based Access Control
```typescript
describe('Admin-only endpoints', () => {
  it('allows admin access', async () => {
    const mockRequest = {
      user: { id: '1', role: 'admin' },
    };

    const result = await controller.adminOnlyMethod(mockRequest);
    expect(result).toBeDefined();
  });

  it('deny non-admin access', async () => {
    const mockRequest = {
      user: { id: '2', role: 'user' },
    };

    await expect(controller.adminOnlyMethod(mockRequest))
      .rejects.toThrow('Insufficient permissions');
  });
});
```

## Request/Response Testing

### Query Parameters
```typescript
describe('GET /cars with query parameters', () => {
  it('handles pagination parameters', async () => {
    const cars = [{ id: '1', title: 'BMW X5' }];
    const mockMeta = { page: 1, limit: 10, total: 1 };
    
    carsService.findAll.mockResolvedValue({
      data: cars,
      meta: mockMeta,
    });

    const query = { page: '1', limit: '10' };
    const result = await controller.findAll(query);

    expect(result.data).toEqual(cars);
    expect(result.meta).toEqual(mockMeta);
    expect(service.findAll).toHaveBeenCalledWith({
      page: 1,
      limit: 10,
    });
  });

  it('handles filter parameters', async () => {
    const cars = [{ id: '1', title: 'BMW X5', manufacturer: 'BMW' }];
    carsService.findAll.mockResolvedValue(cars);

    const query = { manufacturer: 'BMW', year: '2020' };
    const result = await controller.findAll(query);

    expect(result).toEqual(cars);
    expect(service.findAll).toHaveBeenCalledWith({
      manufacturer: 'BMW',
      year: 2020,
    });
  });
});
```

### Request Body Validation
```typescript
describe('POST /cars validation', () => {
  it('validates required fields', async () => {
    const invalidDto = {}; // Missing required fields

    // This would typically be handled by ValidationPipe
    // In unit tests, we test the controller logic assuming validation passed
    carsService.create.mockRejectedValue(
      new BadRequestException('Validation failed')
    );

    await expect(controller.create(invalidDto))
      .rejects.toThrow('Validation failed');
  });

  it('handles valid request body', async () => {
    const validDto = {
      title: 'BMW X5',
      price: 25000,
      year: 2020,
    };
    const car = { id: '1', ...validDto };
    carsService.create.mockResolvedValue(car);

    const result = await controller.create(validDto);

    expect(result).toEqual(car);
    expect(service.create).toHaveBeenCalledWith(validDto);
  });
});
```

## Error Handling

### Exception Testing
```typescript
import { NotFoundException, BadRequestException } from '@nestjs/common';

describe('Error handling', () => {
  it('handles service exceptions', async () => {
    carsService.findOne.mockRejectedValue(
      new NotFoundException('Car not found')
    );

    await expect(controller.findOne('999'))
      .rejects.toThrow('Car not found');
  });

  it('handles validation exceptions', async () => {
    carsService.create.mockRejectedValue(
      new BadRequestException('Invalid data')
    );

    await expect(controller.create({}))
      .rejects.toThrow('Invalid data');
  });
});
```

## File Upload Testing

### Multipart Form Data
```typescript
describe('File upload', () => {
  it('handles file upload', async () => {
    const file = {
      fieldname: 'image',
      originalname: 'car.jpg',
      encoding: '7bit',
      mimetype: 'image/jpeg',
      buffer: Buffer.from('fake-image-data'),
      size: 1024,
    } as Express.Multer.File;

    const result = {
      id: '1',
      imageUrl: 'https://example.com/car.jpg',
    };

    carsService.uploadImage.mockResolvedValue(result);

    const result = await controller.uploadImage('1', file);

    expect(result).toEqual(result);
    expect(service.uploadImage).toHaveBeenCalledWith('1', file);
  });

  it('handles missing file', async () => {
    await expect(controller.uploadImage('1', undefined))
      .rejects.toThrow('File is required');
  });
});
```

## Response Transformation

### Custom Response Format
```typescript
describe('Response transformation', () => {
  it('transforms response data', async () => {
    const car = {
      id: '1',
      title: 'BMW X5',
      price: 25000,
      createdAt: new Date('2023-01-01'),
    };

    carsService.findOne.mockResolvedValue(car);

    const result = await controller.findOne('1');

    // Assuming controller transforms the response
    expect(result).toEqual({
      id: '1',
      title: 'BMW X5',
      price: 25000,
      createdAt: '2023-01-01T00:00:00.000Z',
    });
  });
});
```

## Best Practices

### ✅ Do's
- Mock service dependencies completely
- Test HTTP-specific logic (params, body, headers)
- Test authentication and authorization
- Test error handling and edge cases
- Use descriptive test names
- Clear mocks between tests

### ❌ Don'ts
- Don't test business logic in controller tests
- Don't use real services or databases
- Don't test framework functionality
- Don't ignore error scenarios
- Don't test private methods
- Don't make tests dependent on each other