---
name: nestjs
description: NestJS patterns for services and GraphQL resolvers including structure, dependency injection, error handling, background jobs, field resolvers, queries, mutations, subscriptions, and testing. Use when (1) creating NestJS services or resolvers, (2) implementing CRUD operations with Mongoose, (3) adding GraphQL field resolvers, (4) implementing queries and mutations, (5) setting up DataLoader patterns, (6) adding authentication/authorization, (7) setting up background jobs or cron tasks, (8) testing services or resolvers with mocked dependencies.
---

# NestJS Patterns

## Quick Reference

This skill provides comprehensive NestJS patterns for services and GraphQL resolvers. Load reference files as needed:

**Services:**
- **[dependency-injection.md](references/dependency-injection.md)** - Model injection, service dependencies, optional dependencies, configuration injection
- **[pagination-filtering.md](references/pagination-filtering.md)** - Pagination interfaces, filter patterns, search implementation
- **[background-jobs.md](references/background-jobs.md)** - Cron jobs, queue patterns, error handling in background tasks
- **[custom-exceptions.md](references/custom-exceptions.md)** - Creating domain-specific exceptions
- **[testing.md](references/testing.md)** - Unit testing with mocked dependencies

**GraphQL Resolvers:**
- **[resolver-patterns.md](references/resolver-patterns.md)** - Field resolvers, queries, mutations, subscriptions, DataLoader integration, authentication, resolver testing

**Database Operations:**
- See **[mongoose skill](../mongoose/SKILL.md)** for Mongoose patterns (entities, documents, queries, embedded schemas, helpers)

## Core Service Structure

```typescript
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';

import { Car } from './entities/car.entity';
import { CarDocument } from './interfaces/car-document.interface';
import { CarModel } from './interfaces/car-model.interface';

import { LoggerService } from 'src/common/logger/logger.service';

import { CarTypeService } from '../car-type/car-type.service';

import { CreateCarInput, UpdateCarInput, CarFilters } from './car.dto';

@Injectable()
export class CarService {
  constructor(
    @InjectModel(Car.name) private readonly carModel: CarModel,
    private readonly carTypeService: CarTypeService,
    private readonly loggerService: LoggerService,
  ) {}

  // Business logic methods first
  calculateAmortization(car: CarDocument): number {
    // Implementation
  }

  validateCarHistory(events: HistoryEvent[]): boolean {
    // Implementation
  }

  // CRUD methods last
  async findAll(filters?: CarFilters): Promise<CarDocument[]> {
    // Implementation
  }

  async findOne(id: string): Promise<CarDocument | null> {
    // Implementation
  }

  async create(data: CreateCarInput): Promise<CarDocument> {
    // Implementation
  }

  async update(car: CarDocument, data: UpdateCarInput): Promise<CarDocument> {
    // Implementation
  }

  async delete(car: CarDocument): Promise<CarDocument> {
    // Implementation
  }
}
```

## Enum Usage

**CRITICAL**: Always use enums from `src/generated/graphql`. Never create duplicate enums or use string literals.

```typescript
// ✅ CORRECT
import { CarState } from 'src/generated/graphql';
car.status = CarState.ACTIVE;

// ❌ WRONG
car.status = 'ACTIVE';
enum CarStatus { ACTIVE = 'ACTIVE' }
```

**See `graphql/enum-patterns` for comprehensive patterns.**

## Import Organization

Follow this strict order:
1. **Framework imports** (NestJS decorators)
2. **Third-party packages** (mongoose, date-fns)
3. **Generated files** (`src/generated/...`) - **Import enums here**
4. **Helper utilities** (`src/helpers/...`, `src/database/...`)
5. **Common modules** (`src/common/...`)
6. **Application modules** (`src/modules/...`)
7. **Relative imports** (`./`, `../`)

## Method Ordering Standards

**Universal principle**: Most important functionality first, public before private

**Service method order**:
1. Business logic methods (domain-specific operations)
2. CRUD methods in standard order:
   - `findAll()` - List/search operations
   - `findOne()` - Single entity retrieval
   - `create()` - Entity creation
   - `update()` - Entity modification
   - `delete()` - Entity removal

## Basic CRUD Patterns

### Find All
```typescript
async findAll(filters?: CarFilters): Promise<CarDocument[]> {
  const query: FilterQuery<Car> = {};

  if (filters?.status) {
    query.status = filters.status;
  }

  if (filters?.manufacturer) {
    query.manufacturer = filters.manufacturer;
  }

  return this.carModel.find(query).sort({ createdAt: -1 }).exec();
}
```

### Find One
```typescript
async findOne(id: string): Promise<CarDocument | null> {
  const car = await this.carModel.findById(id).exec();

  if (!car) {
    throw new NotFoundException('Car not found');
  }

  return car;
}

findOneByNumber(number: string): Promise<CarDocument | null> {
  return this.carModel.findOne({ numbers: number }).exec();
}
```

### Create
```typescript
async create(data: CreateCarInput): Promise<CarDocument> {
  // Validate dependencies
  const carType = await this.carTypeService.findOne(data.carTypeId);
  if (!carType) {
    throw new BadRequestException('Car type not found');
  }

  // Business validation
  if (data.year > new Date().getFullYear() + 1) {
    throw new BadRequestException('Car year cannot be more than one year in the future');
  }

  // Create and save
  const car = new this.carModel({
    ...data,
    type: carType._id,
    status: CarState.ACTIVE,
  });

  return car.save();
}
```

### Update
```typescript
async update(car: CarDocument, data: UpdateCarInput): Promise<CarDocument> {
  car.set(data);
  return car.save();
}
```

### Delete
```typescript
async delete(car: CarDocument): Promise<CarDocument> {
  await car.deleteOne();
  return car;
}
```

## Error Handling

### Standard Exceptions
```typescript
import { NotFoundException, BadRequestException } from '@nestjs/common';

async findOne(id: string): Promise<CarDocument> {
  const car = await this.carModel.findById(id).exec();
  
  if (!car) {
    throw new NotFoundException('Car not found');
  }
  
  return car;
}

async create(data: CreateCarInput): Promise<CarDocument> {
  // Check unique constraints
  const existing = await this.carModel.findOne({ vin: data.vin }).exec();
  
  if (existing) {
    throw new BadRequestException('Car with this VIN already exists');
  }

  // Business rule validation
  if (data.year < 1900) {
    throw new BadRequestException('Invalid year');
  }

  const car = new this.carModel(data);
  return car.save();
}
```

### Automatic Error Handling
GraphQL resolvers and HTTP controllers use global exception filters - no manual error notifications needed for these components.

### Manual Error Notifications Required
For background jobs, cron tasks, and external API integrations, use `loggerService.notifyError()`:

```typescript
async syncWithExternalApi(): Promise<void> {
  try {
    // API call
  } catch (error) {
    this.loggerService.notifyError(error as Error, {
      context: { operation: 'syncWithExternalApi' }
    });
    throw error;
  }
}
```

## GraphQL Resolver Structure

```typescript
import { Resolver, Query, Mutation, Args, ResolveField, Parent } from '@nestjs/graphql';
import { UseGuards } from '@nestjs/common';

import { Car, CarType } from 'src/generated/graphql';

import { GqlAuthGuard } from 'src/common/guards/gql-auth.guard';
import { CurrentUser } from 'src/common/decorators/current-user.decorator';

import { CarService } from './car.service';
import { CreateCarInput, UpdateCarInput, CarFilters } from './car.dto';

@Resolver(() => Car)
export class CarResolver {
  constructor(
    private readonly carService: CarService,
    private readonly carTypeService: CarTypeService,
  ) {}

  // Field resolvers first (most important)
  @ResolveField(() => CarType)
  async carType(@Parent() car: Car): Promise<CarType> {
    return this.carTypeService.findOne(car.carTypeId);
  }

  // Queries second
  @Query(() => [Car])
  async cars(@Args('filters', { nullable: true }) filters?: CarFilters): Promise<Car[]> {
    return this.carService.findAll(filters);
  }

  @Query(() => Car, { nullable: true })
  async car(@Args('id') id: string): Promise<Car | null> {
    return this.carService.findOne(id);
  }

  // Mutations last
  @Mutation(() => Car)
  @UseGuards(GqlAuthGuard)
  async createCar(
    @Args('input') input: CreateCarInput,
    @CurrentUser() user: any
  ): Promise<Car> {
    return this.carService.create(input);
  }
}
```

### Resolver Method Order
1. **Field resolvers** (@ResolveField) - Computed fields and relations
2. **Queries** (@Query) - Data retrieval operations
3. **Mutations** (@Mutation) - Data modification operations
4. **Subscriptions** (@Subscription) - Real-time updates (if needed)

## When to Load Reference Files

**Using GraphQL enums?**
- Always reuse generated enums → Use `openskills read graphql/enum-patterns`
- Services, DTOs, schemas, tests → Use `openskills read graphql/enum-patterns`

**Working with GraphQL resolvers?**
- Field resolvers and DataLoader integration → [resolver-patterns.md](references/resolver-patterns.md)
- Queries with pagination and filtering → [resolver-patterns.md](references/resolver-patterns.md)
- Mutations with validation and auth → [resolver-patterns.md](references/resolver-patterns.md)
- Subscriptions and real-time updates → [resolver-patterns.md](references/resolver-patterns.md)

**Need Mongoose database operations?**
- Entity definitions, queries, embedded schemas → Use `openskills read mongoose`

**Implementing search or filtering?**
- Pagination with metadata → [pagination-filtering.md](references/pagination-filtering.md)
- Advanced filtering and search → [pagination-filtering.md](references/pagination-filtering.md)

**Setting up background processing?**
- Cron jobs or scheduled tasks → [background-jobs.md](references/background-jobs.md)
- Queue-based processing → [background-jobs.md](references/background-jobs.md)

**Need advanced dependency patterns?**
- Optional dependencies → [dependency-injection.md](references/dependency-injection.md)
- Configuration injection → [dependency-injection.md](references/dependency-injection.md)

**Creating domain-specific exceptions?**
- Custom exception classes → [custom-exceptions.md](references/custom-exceptions.md)

**Writing tests?**
- Unit testing patterns → [testing.md](references/testing.md)
- Resolver unit tests → [resolver-patterns.md](references/resolver-patterns.md)
