---
name: mongoose
description: Mongoose patterns for NestJS including entity definitions, document/model interfaces, queries, embedded schemas, and helpers. Use when (1) creating Mongoose entities with @Schema/@Prop decorators, (2) defining Document and Model interfaces for type safety, (3) writing queries with FilterQuery and aggregation pipelines, (4) working with embedded subdocuments and DocumentArrays, (5) implementing custom setters/getters/virtuals, (6) adding validation to schema properties.
---

# Mongoose Patterns

## Quick Reference

This skill provides comprehensive Mongoose patterns for NestJS applications. Load reference files as needed:

- **[entities.md](references/entities.md)** - @Schema/@Prop decorators, SchemaFactory, indexes, Mongoose 9 id virtual
- **[documents.md](references/documents.md)** - HydratedDocument, Model types, @InjectModel pattern, DocumentArray typing
- **[queries.md](references/queries.md)** - find/findOne, FilterQuery, operators ($in, $or, $elemMatch), aggregation pipelines
- **[embedded-schemas.md](references/embedded-schemas.md)** - Subdocument entities, embedding patterns, DocumentArray manipulation
- **[helpers.md](references/helpers.md)** - Custom setters (parseNumber, parseDate), getters, virtuals, validation

## Core Entity Structure

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { Types } from 'mongoose';

@Schema({
  timestamps: true,
  versionKey: false,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
})
export class CarType {
  @Prop({ required: true, unique: true })
  name: string;

  @Prop({ type: Number, unique: true, sparse: true })
  rshopId?: number;

  @Prop({ type: Boolean, default: true })
  new?: boolean;

  createdAt: Date;
  updatedAt?: Date;
}

export const CarTypeSchema = SchemaFactory.createForClass(CarType);

// Add id virtual (Mongoose 9 no longer provides this by default)
CarTypeSchema.virtual('id').get(function (this: CarType & { _id: Types.ObjectId }) {
  return this._id.toHexString();
});
```

## Import Organization

Follow this strict order:
1. **Framework imports** (`@nestjs/mongoose`, `@nestjs/common`)
2. **Third-party packages** (`mongoose`, `date-fns`)
3. **Generated files** (`src/generated/...`)
4. **Helper utilities** (`src/database/...`)
5. **Common modules** (`src/common/...`)
6. **Application modules** (`src/modules/...`)
7. **Relative imports** (`./`, `../`)

## Document and Model Interfaces

```typescript
// car-document.interface.ts
import { HydratedDocument, Types } from 'mongoose';

import { Car } from '../entities/car.entity';
import { CarEvent } from '../entities/car-event.entity';

export interface CarDocumentOverrides {
  id: string;
  history: Types.DocumentArray<CarEvent>;
}

export interface CarDocument
  extends HydratedDocument<Car, CarDocumentOverrides> {}

// car-model.interface.ts
import { Model } from 'mongoose';

export type CarModel = Model<Car, unknown, unknown, unknown, CarDocument>;
```

## Service with Model Injection

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

  // CRUD methods
  findAll(): Promise<CarDocument[]> {
    return this.carModel.find().exec();
  }

  findOne(id: string): Promise<CarDocument | null> {
    return this.carModel.findById(id).exec();
  }

  create(data: CreateCarInput): Promise<CarDocument> {
    const car = new this.carModel(data);
    return car.save();
  }

  async update(car: CarDocument, data: UpdateCarInput): Promise<CarDocument> {
    car.set(data);
    return car.save();
  }

  async delete(car: CarDocument): Promise<CarDocument> {
    await car.deleteOne();
    return car;
  }
}
```

## When to Load Reference Files

**Defining entities?**
- Schema options and @Prop variations → [entities.md](references/entities.md)
- Indexes (simple and compound) → [entities.md](references/entities.md)

**Setting up type safety?**
- Document and Model interfaces → [documents.md](references/documents.md)
- @InjectModel with proper typing → [documents.md](references/documents.md)

**Writing queries?**
- FilterQuery and operators → [queries.md](references/queries.md)
- Aggregation pipelines → [queries.md](references/queries.md)

**Working with nested data?**
- Subdocument schemas → [embedded-schemas.md](references/embedded-schemas.md)
- DocumentArray manipulation → [embedded-schemas.md](references/embedded-schemas.md)

**Custom data transformation?**
- Setters for parsing input → [helpers.md](references/helpers.md)
- Getters for default values → [helpers.md](references/helpers.md)
- Virtuals for computed fields → [helpers.md](references/helpers.md)
