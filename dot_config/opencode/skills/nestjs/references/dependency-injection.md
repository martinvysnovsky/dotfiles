# Dependency Injection Patterns

## Model Injection

Standard pattern for injecting Mongoose models:

```typescript
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';

import { Car } from './entities/car.entity';
import { CarModel } from './interfaces/car-model.interface';

@Injectable()
export class CarService {
  constructor(
    @InjectModel(Car.name) private readonly carModel: CarModel,
  ) {}
}
```

### Multiple Models

```typescript
@Injectable()
export class CarService {
  constructor(
    @InjectModel(Car.name) private readonly carModel: CarModel,
    @InjectModel(CarType.name) private readonly carTypeModel: CarTypeModel,
  ) {}
}
```

## Service Dependencies

Inject other services directly via constructor:

```typescript
@Injectable()
export class CarService {
  constructor(
    @InjectModel(Car.name) private readonly carModel: CarModel,
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
import { Injectable, Optional } from '@nestjs/common';

@Injectable()
export class CarService {
  constructor(
    @InjectModel(Car.name) private readonly carModel: CarModel,
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
import { Injectable, Inject } from '@nestjs/common';

@Injectable()
export class CarService {
  constructor(
    @InjectModel(Car.name) private readonly carModel: CarModel,
    @Inject('CAR_CONFIG') 
    private readonly config: CarConfig,
  ) {}

  calculateDepreciation(car: CarDocument): number {
    return car.purchasePrice * this.config.depreciationRate;
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
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { Car, CarSchema } from './entities/car.entity';
import { CarService } from './car.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Car.name, schema: CarSchema },
    ]),
  ],
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
  exports: [CarService],
})
export class CarModule {}
```

## Constructor Best Practices

**Order of dependencies**:
1. Models (with `@InjectModel()`)
2. Required services
3. Optional services (with `@Optional()`)
4. Configuration (with `@Inject()`)

**Naming convention**:
- Use `private readonly` for all injected dependencies
- Use descriptive names matching the service/model type

```typescript
@Injectable()
export class CarService {
  constructor(
    // Models first
    @InjectModel(Car.name) private readonly carModel: CarModel,
    
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

## Module Registration

### Basic Module with Model

```typescript
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { Car, CarSchema } from './entities/car.entity';
import { CarsService } from './cars.service';
import { CarsResolver } from './cars.resolver';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Car.name, schema: CarSchema },
    ]),
  ],
  providers: [CarsService, CarsResolver],
  exports: [CarsService],
})
export class CarsModule {}
```

### Module with Multiple Models

```typescript
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Car.name, schema: CarSchema },
      { name: CarType.name, schema: CarTypeSchema },
    ]),
  ],
  providers: [CarsService, CarTypesService],
  exports: [CarsService, CarTypesService],
})
export class CarsModule {}
```

### Module with External Dependencies

```typescript
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Car.name, schema: CarSchema },
    ]),
    CarTypesModule, // Import other modules
    LoggerModule,
  ],
  providers: [CarsService, CarsResolver],
  exports: [CarsService],
})
export class CarsModule {}
```
