# Dependency Injection Patterns

## Repository Injection

Standard pattern for injecting TypeORM repositories:

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

## Service Dependencies

Inject other services directly via constructor:

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

## Optional Dependencies

Use `@Optional()` decorator for non-critical dependencies:

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

## Configuration Injection

Inject configuration objects with custom tokens:

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

### Configuration Module Setup

```typescript
// car.config.ts
export interface CarConfig {
  depreciationRate: number;
  maxAge: number;
  maintenanceInterval: number;
}

// car.module.ts
@Module({
  providers: [
    CarService,
    {
      provide: 'CAR_CONFIG',
      useValue: {
        depreciationRate: 0.15,
        maxAge: 15,
        maintenanceInterval: 6, // months
      } as CarConfig,
    },
  ],
})
export class CarModule {}
```

## Constructor Best Practices

**Order of dependencies**:
1. Repositories (with `@InjectRepository()`)
2. Required services
3. Optional services (with `@Optional()`)
4. Configuration (with `@Inject()`)

**Naming convention**:
- Use `private readonly` for all injected dependencies
- Use descriptive names matching the service/repository type

```typescript
@Injectable()
export class CarService {
  constructor(
    // Repositories first
    @InjectRepository(Car) 
    private readonly carRepository: Repository<Car>,
    
    // Required services
    private readonly carTypeService: CarTypeService,
    private readonly loggerService: LoggerService,
    
    // Optional services
    @Optional() 
    private readonly externalApiService?: ExternalApiService,
    
    // Configuration
    @Inject('CAR_CONFIG') 
    private readonly config: CarConfig,
  ) {}
}
```
