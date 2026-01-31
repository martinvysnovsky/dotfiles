# Document and Model Interfaces

## Why Define Interfaces?

Mongoose documents need proper TypeScript typing for:
- Type-safe access to document methods (`.save()`, `.deleteOne()`)
- Correct typing for embedded DocumentArrays
- Proper Model type for injection

## Document Interface Pattern

### Simple Document (No Overrides)

For entities without embedded arrays:

```typescript
// car-type-document.interface.ts
import { HydratedDocument } from 'mongoose';

import { CarType } from '../entities/car-type.entity';

export interface CarTypeDocumentOverrides {
  id: string;
}

export type CarTypeDocument = HydratedDocument<
  CarType,
  CarTypeDocumentOverrides
>;
```

### Document with Embedded Arrays

For entities with embedded subdocuments:

```typescript
// car-document.interface.ts
import { HydratedDocument, Types } from 'mongoose';

import { AdditionalCost } from 'src/costs/entities/additional-cost.entity';
import { Cost } from 'src/costs/entities/cost.entity';

import { Car } from '../entities/car.entity';
import { CarEvent } from '../entities/car-event.entity';

export interface CarDocumentOverrides {
  id: string;
  history: Types.DocumentArray<CarEvent>;
  monthlyCosts: Types.DocumentArray<Cost>;
  additionalCosts: Types.DocumentArray<AdditionalCost>;
}

export interface CarDocument
  extends HydratedDocument<Car, CarDocumentOverrides> {}
```

### Key Points

- **`id: string`** - Override ensures `id` returns string (from virtual)
- **`Types.DocumentArray<T>`** - Enables subdocument methods like `.id()`, `.push()`, `.deleteOne()`
- **`HydratedDocument<Entity, Overrides>`** - Combines entity type with document methods

## Model Type Pattern

```typescript
// car-model.interface.ts
import { Model } from 'mongoose';

import { Car } from '../entities/car.entity';

import { CarDocument } from './car-document.interface';

export type CarModel = Model<Car, unknown, unknown, unknown, CarDocument>;
```

### Model Generic Parameters

```typescript
Model<
  Car,           // Raw document interface (entity class)
  unknown,       // Query helpers (use unknown if none)
  unknown,       // Instance methods (use unknown if none)
  unknown,       // Virtuals (use unknown if none)
  CarDocument    // Hydrated document type
>
```

## Service Injection Pattern

```typescript
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';

import { Car } from './entities/car.entity';
import { CarDocument } from './interfaces/car-document.interface';
import { CarModel } from './interfaces/car-model.interface';

@Injectable()
export class CarsService {
  constructor(
    @InjectModel(Car.name) private carModel: CarModel,
  ) {}

  // Methods return CarDocument for proper typing
  findAll(): Promise<CarDocument[]> {
    return this.carModel.find().exec();
  }

  findOne(id: string): Promise<CarDocument | null> {
    return this.carModel.findById(id).exec();
  }
}
```

### Key Points

- **`@InjectModel(Car.name)`** - Uses the entity class name for injection token
- **`CarModel`** - Properly typed model with CarDocument as return type
- **Return types** - Always use `CarDocument` or `CarDocument[]`

## Module Registration

```typescript
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { Car, CarSchema } from './entities/car.entity';
import { CarsService } from './cars.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Car.name, schema: CarSchema },
    ]),
  ],
  providers: [CarsService],
  exports: [CarsService],
})
export class CarsModule {}
```

## Working with Documents

### Document Methods

```typescript
// Create new document
create(data: CreateCarInput): Promise<CarDocument> {
  const car = new this.carModel(data);
  return car.save();
}

// Update existing document
async update(car: CarDocument, data: UpdateCarInput): Promise<CarDocument> {
  car.set(data);
  return car.save();
}

// Delete document
async delete(car: CarDocument): Promise<CarDocument> {
  await car.deleteOne();
  return car;
}
```

### Accessing Embedded Arrays

With proper `Types.DocumentArray` typing:

```typescript
async updateCost(car: CarDocument, costId: string, data: CostData): Promise<CarDocument> {
  // Find subdocument by ID
  const cost = car.monthlyCosts.id(costId);
  
  if (cost) {
    // Update subdocument
    cost.set(data);
  }
  
  return car.save();
}

async addCost(car: CarDocument, data: CostData): Promise<CarDocument> {
  // Push new subdocument
  car.monthlyCosts.push(data);
  return car.save();
}

async removeCost(car: CarDocument, costId: string): Promise<CarDocument> {
  // Delete subdocument
  await car.monthlyCosts.id(costId)?.deleteOne();
  return car.save();
}
```

## Complete Interface Files Example

### File Structure

```
src/cars/
├── entities/
│   ├── car.entity.ts
│   └── car-event.entity.ts
├── interfaces/
│   ├── car-document.interface.ts
│   └── car-model.interface.ts
├── cars.service.ts
└── cars.module.ts
```

### car-document.interface.ts

```typescript
import { HydratedDocument, Types } from 'mongoose';

import { Cost } from 'src/costs/entities/cost.entity';

import { Car } from '../entities/car.entity';
import { CarEvent } from '../entities/car-event.entity';

export interface CarDocumentOverrides {
  id: string;
  history: Types.DocumentArray<CarEvent>;
  monthlyCosts: Types.DocumentArray<Cost>;
}

export interface CarDocument
  extends HydratedDocument<Car, CarDocumentOverrides> {}
```

### car-model.interface.ts

```typescript
import { Model } from 'mongoose';

import { Car } from '../entities/car.entity';

import { CarDocument } from './car-document.interface';

export type CarModel = Model<Car, unknown, unknown, unknown, CarDocument>;
```
