# Embedded Schemas (Subdocuments)

## When to Use Embedded Schemas

Use embedded documents when:
- Data is always accessed together with the parent
- Data doesn't need to be queried independently
- One-to-few relationships (not one-to-many with thousands)

Examples: monthly costs on a car, history events, address on a user.

## Defining Subdocument Entity

```typescript
// car-event.entity.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import mongoose from 'mongoose';

import { HistoryEventType } from 'src/generated/graphql';

@Schema({ timestamps: false }) // Subdocuments often don't need timestamps
export class CarEvent {
  @Prop({
    type: mongoose.Schema.Types.String,
    enum: HistoryEventType,
    required: true,
  })
  name: HistoryEventType;

  @Prop({ required: true })
  date: Date;

  @Prop()
  description?: string;
}

export const CarEventSchema = SchemaFactory.createForClass(CarEvent);
```

## Subdocument with Timestamps and ID Virtual

```typescript
// cost.entity.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { Types } from 'mongoose';

import { parseDateTime, parseNumber } from 'src/database/database.helper';

@Schema({
  timestamps: true,
  versionKey: false,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
})
export class Cost {
  @Prop({
    set: (value: string) => parseDateTime(value, 'M/YYYY'),
    required: true,
  })
  date: Date;

  @Prop({ set: parseNumber })
  motorInsurance?: number;

  @Prop({ set: parseNumber })
  insurance?: number;

  @Prop({ set: parseNumber })
  roadTax?: number;

  @Prop({ set: parseNumber })
  interest?: number;

  createdAt: Date;
  updatedAt?: Date;
}

export const CostSchema = SchemaFactory.createForClass(Cost);

// Add id virtual for subdocuments (Mongoose 9 no longer provides this by default)
CostSchema.virtual('id').get(function (this: Cost & { _id: Types.ObjectId }) {
  return this._id.toHexString();
});
```

## Embedding in Parent Entity

```typescript
// car.entity.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { Cost, CostSchema } from 'src/costs/entities/cost.entity';

import { CarEvent, CarEventSchema } from './car-event.entity';

@Schema({
  timestamps: true,
  versionKey: false,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
})
export class Car {
  // Array of embedded documents with default
  @Prop({ type: [CarEventSchema], default: [], required: true })
  history: CarEvent[];

  // Optional array of embedded documents
  @Prop({ type: [CostSchema] })
  monthlyCosts: Cost[];

  // ... other fields
}
```

## Document Interface with DocumentArray

For proper typing of subdocument operations:

```typescript
// car-document.interface.ts
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

## Subdocument Operations

### Find by ID

```typescript
async findCostById(car: CarDocument, costId: string): Cost | null {
  return car.monthlyCosts.id(costId);
}
```

### Update Subdocument

```typescript
async updateCost(
  car: CarDocument,
  date: Date,
  costData: Partial<CostData>,
): Promise<CarDocument> {
  // Find existing item by date
  const items = car.monthlyCosts.filter(
    (cost) => startOfDay(cost.date).toString() === date.toString(),
  );

  if (items[0] && '_id' in items[0]) {
    // Update existing item
    car.monthlyCosts.id(items[0]._id)?.set(costData);
  } else {
    // Add new item
    car.monthlyCosts.push({
      date,
      ...costData,
    });
  }

  return car.save();
}
```

### Add Subdocument

```typescript
async addHistoryEvent(
  car: CarDocument,
  event: { name: HistoryEventType; date: Date; description?: string },
): Promise<CarDocument> {
  car.history.push(event);
  return car.save();
}
```

### Delete Subdocument

```typescript
async deleteCost(car: CarDocument, costId: string): Promise<CarDocument> {
  await car.monthlyCosts.id(costId)?.deleteOne();
  return car.save();
}
```

### Delete Multiple Subdocuments

```typescript
async removeInterestsAfter(
  car: CarDocument,
  afterDate: Date,
): Promise<CarDocument> {
  const startOfNextMonth = startOfMonth(addMonths(afterDate, 1));

  // Find all costs that should be removed
  const costsToRemove = car.monthlyCosts.filter(
    (cost) => cost.date >= startOfNextMonth,
  );

  // Remove each cost individually
  await Promise.all(
    costsToRemove.map(async (cost) => {
      if ('_id' in cost) {
        await car.monthlyCosts.id(cost._id)?.deleteOne();
      }
    }),
  );

  return car.save();
}
```

### Remove Duplicates

```typescript
async removeDuplicateCosts(car: CarDocument, date: Date): Promise<CarDocument> {
  const items = car.monthlyCosts.filter(
    (cost) => startOfDay(cost.date).toString() === date.toString(),
  );

  // Keep first, remove rest
  await Promise.all(
    items.map(async (cost, key) => {
      if (key > 0 && '_id' in cost) {
        await car.monthlyCosts.id(cost._id)?.deleteOne();
      }
    }),
  );

  return car.save();
}
```

## Query Embedded Documents

### Find by Nested Field

```typescript
// Find car by history event ID
findOneByHistoryEventId(id: string): Promise<CarDocument | null> {
  return this.carModel.findOne({ 'history._id': id }).exec();
}
```

### Element Match

```typescript
// Find cars with specific history event type and date range
findByHistoryEvent(type: HistoryEventType, startDate: Date, endDate: Date) {
  return this.carModel.find({
    history: {
      $elemMatch: {
        name: type,
        date: { $gte: startDate, $lte: endDate },
      },
    },
  }).exec();
}
```

### Compound Index on Embedded Fields

```typescript
// In entity file after schema creation
CarSchema.index({ 'history.name': 1, 'history.date': 1 });
```

## Best Practices

1. **Always add ID virtual for subdocuments** (Mongoose 9+)
2. **Use `Types.DocumentArray<T>`** in document overrides for proper typing
3. **Check for `_id` existence** before operations: `if ('_id' in cost)`
4. **Use optional chaining** with `.id()`: `car.monthlyCosts.id(costId)?.deleteOne()`
5. **Always call `.save()`** on parent after modifying subdocuments
6. **Create indexes** on frequently queried embedded fields
