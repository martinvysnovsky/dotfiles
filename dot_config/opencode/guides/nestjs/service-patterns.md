# NestJS Service Patterns

## Basic Service Structure

```typescript
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';

import { Repository } from 'typeorm';

import { Car } from 'src/generated/entities';

import { LoggerService } from 'src/common/logger/logger.service';

import { CarTypeService } from '../car-type/car-type.service';

import { CreateCarInput, UpdateCarInput, CarFilters } from './car.dto';

@Injectable()
export class CarService {
  constructor(
    @InjectRepository(Car) 
    private readonly carRepository: Repository<Car>,
    private readonly carTypeService: CarTypeService,
    private readonly loggerService: LoggerService,
  ) {}

  // Business logic methods first
  calculateAmortization(car: Car): number {
    // Implementation
  }

  validateCarHistory(events: HistoryEvent[]): boolean {
    // Implementation
  }

  // CRUD methods last
  async findAll(filters?: CarFilters): Promise<Car[]> {
    // Implementation
  }

  async findOne(id: string): Promise<Car | null> {
    // Implementation
  }

  async create(data: CreateCarInput): Promise<Car> {
    // Implementation
  }

  async update(id: string, data: UpdateCarInput): Promise<Car> {
    // Implementation
  }

  async delete(id: string): Promise<void> {
    // Implementation
  }
}
```

## Database Operations with TypeORM

### Repository Injection
```typescript
@Injectable()
export class CarService {
  constructor(
    @InjectRepository(Car) 
    private readonly carRepository: Repository<Car>,
    @InjectRepository(HistoryEvent)
    private readonly historyEventRepository: Repository<HistoryEvent>,
  ) {}
}
```

### Query Builder Patterns
```typescript
async findWithFilters(filters: CarFilters): Promise<Car[]> {
  const queryBuilder = this.carRepository.createQueryBuilder('car')
    .leftJoinAndSelect('car.carType', 'carType')
    .leftJoinAndSelect('car.historyEvents', 'historyEvents');

  if (filters.manufacturer) {
    queryBuilder.andWhere('car.manufacturer = :manufacturer', {
      manufacturer: filters.manufacturer
    });
  }

  if (filters.yearFrom) {
    queryBuilder.andWhere('car.year >= :yearFrom', {
      yearFrom: filters.yearFrom
    });
  }

  if (filters.yearTo) {
    queryBuilder.andWhere('car.year <= :yearTo', {
      yearTo: filters.yearTo
    });
  }

  if (filters.priceRange) {
    queryBuilder.andWhere('car.price BETWEEN :minPrice AND :maxPrice', {
      minPrice: filters.priceRange.min,
      maxPrice: filters.priceRange.max
    });
  }

  return queryBuilder
    .orderBy('car.createdAt', 'DESC')
    .getMany();
}
```

### Transaction Handling
```typescript
async processRentalEnd(carId: string, endDate: Date): Promise<void> {
  await this.carRepository.manager.transaction(async (transactionManager) => {
    // Update car status
    const car = await transactionManager.findOne(Car, { 
      where: { id: carId } 
    });
    
    if (!car) {
      throw new NotFoundException('Car not found');
    }

    car.status = CarStatus.AVAILABLE;
    car.lastRentalEndDate = endDate;
    await transactionManager.save(car);

    // Create history event
    const historyEvent = transactionManager.create(HistoryEvent, {
      carId,
      type: HistoryEventType.END_OF_RENTING,
      eventDate: endDate,
      description: 'Rental period ended'
    });
    await transactionManager.save(historyEvent);

    // Create final invoice
    await this.createFinalInvoice(transactionManager, car, endDate);
  });

  this.loggerService.notifyInfo('Rental period ended successfully', {
    context: { carId, endDate: endDate.toISOString() }
  });
}
```

## Error Handling Patterns

### Business Logic Validation
```typescript
async create(data: CreateCarInput): Promise<Car> {
  // Validate car type exists
  const carType = await this.carTypeService.findOne(data.carTypeId);
  if (!carType) {
    throw new BadRequestException('Car type not found');
  }

  // Validate unique constraints
  const existingCar = await this.carRepository.findOne({
    where: { vin: data.vin }
  });
  if (existingCar) {
    throw new BadRequestException('Car with this VIN already exists');
  }

  // Business rule validation
  if (data.year > new Date().getFullYear() + 1) {
    throw new BadRequestException('Car year cannot be more than one year in the future');
  }

  // Create and save
  const car = this.carRepository.create({
    ...data,
    carType,
    status: CarStatus.AVAILABLE,
    createdAt: new Date(),
  });

  return this.carRepository.save(car);
}
```

### Custom Exceptions
```typescript
export class CarValidationException extends BadRequestException {
  constructor(message: string, public readonly context?: any) {
    super(message);
    this.name = 'CarValidationException';
  }
}

export class CarNotAvailableException extends BadRequestException {
  constructor(carId: string) {
    super(`Car ${carId} is not available for rental`);
    this.name = 'CarNotAvailableException';
  }
}

// Usage
async startRental(carId: string): Promise<void> {
  const car = await this.findOne(carId);
  if (!car) {
    throw new NotFoundException('Car not found');
  }

  if (car.status !== CarStatus.AVAILABLE) {
    throw new CarNotAvailableException(carId);
  }

  // Process rental start
}
```

## Dependency Injection Patterns

### Service Dependencies
```typescript
@Injectable()
export class CarService {
  constructor(
    @InjectRepository(Car) 
    private readonly carRepository: Repository<Car>,
    private readonly carTypeService: CarTypeService,
    private readonly priceCalculatorService: PriceCalculatorService,
    private readonly notificationService: NotificationService,
    private readonly loggerService: LoggerService,
  ) {}
}
```

### Optional Dependencies
```typescript
@Injectable()
export class CarService {
  constructor(
    @InjectRepository(Car) 
    private readonly carRepository: Repository<Car>,
    @Optional() 
    private readonly externalApiService?: ExternalApiService,
  ) {}

  async syncWithExternalSystem(carId: string): Promise<void> {
    if (!this.externalApiService) {
      this.loggerService.warn('External API service not available');
      return;
    }

    await this.externalApiService.syncCar(carId);
  }
}
```

### Configuration Injection
```typescript
@Injectable()
export class CarService {
  constructor(
    @InjectRepository(Car) 
    private readonly carRepository: Repository<Car>,
    @Inject('CAR_CONFIG') 
    private readonly config: CarConfig,
  ) {}

  calculateDepreciation(car: Car): number {
    return car.originalPrice * this.config.depreciationRate;
  }
}
```

## Pagination and Filtering

### Pagination Pattern
```typescript
interface PaginationOptions {
  page: number;
  limit: number;
}

interface PaginatedResult<T> {
  data: T[];
  meta: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

async findAllPaginated(
  filters?: CarFilters,
  pagination?: PaginationOptions
): Promise<PaginatedResult<Car>> {
  const page = pagination?.page ?? 1;
  const limit = pagination?.limit ?? 25;
  const skip = (page - 1) * limit;

  const queryBuilder = this.carRepository.createQueryBuilder('car');

  // Apply filters
  if (filters?.manufacturer) {
    queryBuilder.andWhere('car.manufacturer = :manufacturer', {
      manufacturer: filters.manufacturer
    });
  }

  // Get total count
  const total = await queryBuilder.getCount();

  // Get paginated results
  const data = await queryBuilder
    .skip(skip)
    .take(limit)
    .orderBy('car.createdAt', 'DESC')
    .getMany();

  return {
    data,
    meta: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit)
    }
  };
}
```

## Background Processing

### Job Service Pattern
```typescript
@Injectable()
export class CarMaintenanceJob {
  constructor(
    private readonly carService: CarService,
    private readonly notificationService: NotificationService,
    private readonly loggerService: LoggerService,
  ) {}

  @Cron('0 0 * * *') // Daily at midnight
  async dailyMaintenanceCheck(): Promise<void> {
    try {
      const carsNeedingMaintenance = await this.findCarsNeedingMaintenance();
      
      for (const car of carsNeedingMaintenance) {
        await this.scheduleMaintenanceReminder(car);
      }

      this.loggerService.notifyInfo('Daily maintenance check completed', {
        context: { 
          carsChecked: carsNeedingMaintenance.length,
          operation: 'dailyMaintenanceCheck'
        }
      });
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { operation: 'dailyMaintenanceCheck' }
      });
      throw error;
    }
  }

  private async findCarsNeedingMaintenance(): Promise<Car[]> {
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    return this.carService.findAll({
      lastMaintenanceDate: { $lt: threeMonthsAgo },
      status: CarStatus.AVAILABLE
    });
  }

  private async scheduleMaintenanceReminder(car: Car): Promise<void> {
    await this.notificationService.send({
      type: 'maintenance_reminder',
      carId: car.id,
      message: `Car ${car.title} needs maintenance check`
    });
  }
}
```

## Testing Service Patterns

### Unit Test with Mocked Dependencies
```typescript
describe('CarService', () => {
  let service: CarService;
  let carRepository: MockType<Repository<Car>>;
  let carTypeService: MockType<CarTypeService>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        CarService,
        {
          provide: getRepositoryToken(Car),
          useFactory: repositoryMockFactory,
        },
        {
          provide: CarTypeService,
          useFactory: serviceMockFactory,
        },
      ],
    }).compile();

    service = module.get<CarService>(CarService);
    carRepository = module.get(getRepositoryToken(Car));
    carTypeService = module.get<CarTypeService>(CarTypeService);
  });

  describe('create', () => {
    it('creates new car with valid data', async () => {
      const input: CreateCarInput = {
        title: 'BMW X5',
        price: 50000,
        carTypeId: '1'
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
  });
});
```