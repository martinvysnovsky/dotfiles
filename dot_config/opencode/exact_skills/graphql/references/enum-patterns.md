# GraphQL Enum Patterns

Comprehensive guide for using GraphQL enums in NestJS backend code.

## Golden Rule

**ALWAYS reuse generated enums from `src/generated/graphql`. NEVER create duplicate enums or use string literals.**

## Generated Enums Location

All GraphQL enums are automatically generated and available at:

```typescript
import { CarState, RentalType, VehicleType } from 'src/generated/graphql';
```

## Core Principles

### 1. Use Generated Enums Everywhere

```typescript
// ✅ CORRECT - Import from generated types
import { CarState } from 'src/generated/graphql';

@Injectable()
export class CarService {
  async findActive(): Promise<CarDocument[]> {
    return this.carModel.find({ status: CarState.ACTIVE }).exec();
  }
  
  async markAsSold(car: CarDocument): Promise<CarDocument> {
    car.status = CarState.SOLD;
    return car.save();
  }
}
```

```typescript
// ❌ WRONG - String literals
async findActive(): Promise<CarDocument[]> {
  return this.carModel.find({ status: 'ACTIVE' }).exec();
}

// ❌ WRONG - Manual enum creation
enum CarStatus {
  ACTIVE = 'ACTIVE',
  SOLD = 'SOLD'
}

// ❌ WRONG - Type aliases
type CarStatus = 'ACTIVE' | 'SOLD';
```

### 2. Check Generated Types First

**Before creating any enum**, always:

1. Check `src/generated/graphql.ts` for existing enums
2. Search codebase for enum usage: `grep -r "enum CarState" src/`
3. Verify enum is in GraphQL schema (`.graphql` files)

### 3. Import Path Consistency

```typescript
// ✅ CORRECT - Always use full path
import { CarState, RentalType } from 'src/generated/graphql';

// ❌ WRONG - Relative paths
import { CarState } from '../../../generated/graphql';

// ❌ WRONG - Barrel imports
import { CarState } from 'src/generated';
```

## Common Usage Patterns

### Service Methods

```typescript
import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';

import { CarState, RentalType } from 'src/generated/graphql';

import { Car } from './entities/car.entity';
import { CarModel } from './interfaces/car-model.interface';

@Injectable()
export class CarService {
  constructor(
    @InjectModel(Car.name) private readonly carModel: CarModel,
  ) {}

  // Enum as query filter
  async findByStatus(status: CarState): Promise<CarDocument[]> {
    return this.carModel.find({ status }).exec();
  }

  // Enum in create operations
  async create(data: CreateCarInput): Promise<CarDocument> {
    const car = new this.carModel({
      ...data,
      status: CarState.ACTIVE, // Default value
    });
    return car.save();
  }

  // Enum validation
  async updateStatus(car: CarDocument, newStatus: CarState): Promise<CarDocument> {
    const allowedTransitions = {
      [CarState.ACTIVE]: [CarState.SOLD, CarState.WAREHOUSE],
      [CarState.WAREHOUSE]: [CarState.ACTIVE, CarState.DAMAGED],
      [CarState.DAMAGED]: [CarState.WAREHOUSE],
    };

    const allowed = allowedTransitions[car.status] || [];
    if (!allowed.includes(newStatus)) {
      throw new BadRequestException(
        `Cannot transition from ${car.status} to ${newStatus}`
      );
    }

    car.status = newStatus;
    return car.save();
  }

  // Enum in array filters
  async findByStatuses(statuses: CarState[]): Promise<CarDocument[]> {
    return this.carModel.find({ status: { $in: statuses } }).exec();
  }

  // Multiple enum filters
  async findByFilters(
    status?: CarState,
    rentalType?: RentalType,
  ): Promise<CarDocument[]> {
    const query: FilterQuery<Car> = {};
    
    if (status) {
      query.status = status;
    }
    
    if (rentalType) {
      query.rentalType = rentalType;
    }
    
    return this.carModel.find(query).exec();
  }
}
```

### DTOs and Input Types

```typescript
import { InputType, Field } from '@nestjs/graphql';
import { IsEnum, IsOptional, IsArray } from 'class-validator';

import { CarState, RentalType } from 'src/generated/graphql';

@InputType()
export class UpdateCarInput {
  @Field(() => CarState, { nullable: true })
  @IsEnum(CarState)
  @IsOptional()
  status?: CarState;

  @Field(() => RentalType, { nullable: true })
  @IsEnum(RentalType)
  @IsOptional()
  rentalType?: RentalType;
}

@InputType()
export class CarFilters {
  @Field(() => [CarState], { nullable: true })
  @IsArray()
  @IsEnum(CarState, { each: true })
  @IsOptional()
  statuses?: CarState[];

  @Field(() => [RentalType], { nullable: true })
  @IsArray()
  @IsEnum(RentalType, { each: true })
  @IsOptional()
  rentalTypes?: RentalType[];
}
```

### GraphQL Resolvers

```typescript
import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';

import { Car, CarState, RentalType } from 'src/generated/graphql';

import { CarService } from './car.service';
import { UpdateCarInput, CarFilters } from './car.dto';

@Resolver(() => Car)
export class CarResolver {
  constructor(private readonly carService: CarService) {}

  @Query(() => [Car])
  async cars(
    @Args('filters', { nullable: true }) filters?: CarFilters,
  ): Promise<Car[]> {
    return this.carService.findByFilters(
      filters?.statuses?.[0],
      filters?.rentalTypes?.[0],
    );
  }

  @Query(() => [Car])
  async activeCars(): Promise<Car[]> {
    return this.carService.findByStatus(CarState.ACTIVE);
  }

  @Mutation(() => Car)
  async markCarAsSold(@Args('id') id: string): Promise<Car> {
    const car = await this.carService.findOne(id);
    return this.carService.updateStatus(car, CarState.SOLD);
  }

  @Mutation(() => Car)
  async updateCar(
    @Args('id') id: string,
    @Args('input') input: UpdateCarInput,
  ): Promise<Car> {
    const car = await this.carService.findOne(id);
    return this.carService.update(car, input);
  }
}
```

### Mongoose Schemas

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import mongoose from 'mongoose';

import { CarState, RentalType } from 'src/generated/graphql';

@Schema({ timestamps: true })
export class Car {
  @Prop({ required: true })
  number: string;

  @Prop({ type: mongoose.Schema.Types.String, enum: CarState, default: CarState.ACTIVE })
  status: CarState;

  @Prop({ type: mongoose.Schema.Types.String, enum: RentalType })
  rentalType?: RentalType;
}

export const CarSchema = SchemaFactory.createForClass(Car);
```

**Key points:**
- Use `type: mongoose.Schema.Types.String` for explicit typing
- Pass enum directly (not `Object.values(EnumName)`)
- Mongoose handles enum validation automatically

## Enum Comparison and Conditionals

### Switch Statements

```typescript
import { CarState } from 'src/generated/graphql';

function getStatusLabel(status: CarState): string {
  switch (status) {
    case CarState.ACTIVE:
      return 'Active';
    case CarState.SOLD:
      return 'Sold';
    case CarState.WAREHOUSE:
      return 'In Warehouse';
    case CarState.DAMAGED:
      return 'Damaged';
    case CarState.STOLEN:
      return 'Stolen';
    default:
      // TypeScript exhaustiveness check
      const _exhaustive: never = status;
      return _exhaustive;
  }
}
```

### If/Else Conditions

```typescript
import { CarState } from 'src/generated/graphql';

async processCar(car: CarDocument): Promise<void> {
  // ✅ CORRECT - Use enum values
  if (car.status === CarState.ACTIVE) {
    await this.calculateAmortization(car);
  }

  if (car.status === CarState.SOLD || car.status === CarState.DAMAGED) {
    await this.archiveCar(car);
  }

  // ❌ WRONG - String literals
  if (car.status === 'ACTIVE') {
    // ...
  }
}
```

### Array Checks

```typescript
import { CarState } from 'src/generated/graphql';

const activeStatuses = [CarState.ACTIVE, CarState.WAREHOUSE];
const soldStatuses = [CarState.SOLD];

async function categorize(car: CarDocument): Promise<string> {
  if (activeStatuses.includes(car.status)) {
    return 'available';
  }
  
  if (soldStatuses.includes(car.status)) {
    return 'unavailable';
  }
  
  return 'other';
}
```

## Testing with Enums

### Unit Tests

```typescript
import { Test } from '@nestjs/testing';

import { CarState } from 'src/generated/graphql';

import { CarService } from './car.service';

describe('CarService', () => {
  let service: CarService;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [CarService, /* ... */],
    }).compile();

    service = module.get<CarService>(CarService);
  });

  describe('findByStatus', () => {
    it('returns cars with active status', async () => {
      const cars = await service.findByStatus(CarState.ACTIVE);
      
      expect(cars).toBeDefined();
      expect(cars.every(car => car.status === CarState.ACTIVE)).toBe(true);
    });
  });

  describe('updateStatus', () => {
    it('transitions from active to sold', async () => {
      const car = await createTestCar({ status: CarState.ACTIVE });
      
      const updated = await service.updateStatus(car, CarState.SOLD);
      
      expect(updated.status).toBe(CarState.SOLD);
    });

    it('rejects invalid transitions', async () => {
      const car = await createTestCar({ status: CarState.SOLD });
      
      await expect(
        service.updateStatus(car, CarState.ACTIVE)
      ).rejects.toThrow('Cannot transition');
    });
  });
});
```

### Test Factories

```typescript
import { CarState, RentalType } from 'src/generated/graphql';

import { CarDocument } from './interfaces/car-document.interface';

export class CarTestFactory {
  static create(overrides?: Partial<CarDocument>): CarDocument {
    return {
      _id: 'test-id',
      number: 'CAR-001',
      status: CarState.ACTIVE,
      rentalType: RentalType.LONG_TERM,
      ...overrides,
    } as CarDocument;
  }

  static createSold(): CarDocument {
    return this.create({ status: CarState.SOLD });
  }

  static createInWarehouse(): CarDocument {
    return this.create({ status: CarState.WAREHOUSE });
  }
}
```

## Common Mistakes and Fixes

### Mistake 1: String Literals

```typescript
// ❌ WRONG
const car = await this.carModel.findOne({ status: 'ACTIVE' });

// ✅ CORRECT
import { CarState } from 'src/generated/graphql';
const car = await this.carModel.findOne({ status: CarState.ACTIVE });
```

### Mistake 2: Creating Duplicate Enums

```typescript
// ❌ WRONG - Duplicate enum
enum CarStatus {
  ACTIVE = 'ACTIVE',
  SOLD = 'SOLD',
}

// ✅ CORRECT - Import generated enum
import { CarState } from 'src/generated/graphql';
```

### Mistake 3: Using Type Aliases

```typescript
// ❌ WRONG - Type alias loses enum benefits
type CarStatus = 'ACTIVE' | 'SOLD' | 'WAREHOUSE';

// ✅ CORRECT - Use generated enum
import { CarState } from 'src/generated/graphql';
```

### Mistake 4: Hardcoded Enum Values

```typescript
// ❌ WRONG - Hardcoded values
const statuses = ['ACTIVE', 'WAREHOUSE'];

// ✅ CORRECT - Use enum values
import { CarState } from 'src/generated/graphql';
const statuses = [CarState.ACTIVE, CarState.WAREHOUSE];
```

### Mistake 5: Incorrect Import Paths

```typescript
// ❌ WRONG - Relative path
import { CarState } from '../../../generated/graphql';

// ✅ CORRECT - Absolute path
import { CarState } from 'src/generated/graphql';
```

## Workflow Checklist

When working with enums in NestJS:

1. **Check generated types first**: Open `src/generated/graphql.ts` and search for the enum
2. **Verify GraphQL schema**: Check `.graphql` files to understand enum values and documentation
3. **Import correctly**: Always use `import { EnumName } from 'src/generated/graphql';`
4. **Use enum values**: Never use string literals - always `EnumName.VALUE`
5. **Validate with class-validator**: Use `@IsEnum(EnumName)` in DTOs
6. **Define in Mongoose schemas**: Use `type: mongoose.Schema.Types.String, enum: EnumName` in `@Prop()`
7. **Test with enum values**: Use enum constants in test cases and factories

## Integration with GraphQL Code Generator

### How Enums Are Generated

GraphQL schema definition:
```graphql
"""
State of car in the system
"""
enum CarState {
  "Active car available for rental"
  ACTIVE
  
  "Car has been sold"
  SOLD
  
  "Car in warehouse storage"
  WAREHOUSE
}
```

Generated TypeScript enum (in `src/generated/graphql.ts`):
```typescript
export enum CarState {
  Active = 'ACTIVE',
  Sold = 'SOLD',
  Warehouse = 'WAREHOUSE'
}
```

### Enum Configuration in codegen.ts

Ensure your `codegen.ts` has:
```typescript
config: {
  enumsAsTypes: false,      // Generate real enums, not type aliases
  futureProofEnums: true,   // Allow unknown enum values from API
}
```

## Best Practices

1. **Single Source of Truth**: GraphQL schema is the only place to define enums
2. **Type Safety**: Use TypeScript's exhaustiveness checking in switch statements
3. **Validation**: Always use `@IsEnum()` decorator in DTOs
4. **Documentation**: Enum descriptions from GraphQL schema appear in IDE tooltips
5. **Consistency**: Never mix string literals and enum values in same codebase
6. **Testing**: Use enum values in test factories and assertions
7. **Readability**: Enum usage makes code self-documenting and searchable

## Related Patterns

- **GraphQL Schema Design**: See [schema-design.md](schema-design.md) for enum definition patterns
- **GraphQL Code Generation**: See [codegen.md](codegen.md) for enum generation configuration
- **NestJS Resolvers**: See `nestjs/resolver-patterns` for resolver-level enum usage
- **NestJS Services**: See `nestjs/SKILL.md` for service-level patterns
