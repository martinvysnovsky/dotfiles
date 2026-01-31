# Entity Definitions

## Schema Decorator Options

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

@Schema({
  timestamps: true,           // Adds createdAt and updatedAt fields
  versionKey: false,          // Disables __v field
  toJSON: { virtuals: true }, // Include virtuals when converting to JSON
  toObject: { virtuals: true }, // Include virtuals when converting to object
})
export class Car {
  // properties...

  createdAt: Date;  // Added by timestamps: true
  updatedAt?: Date; // Added by timestamps: true
}
```

## @Prop Decorator Variations

### Basic Properties

```typescript
// Required field
@Prop({ required: true })
name: string;

// Optional field (default)
@Prop()
description?: string;

// With default value
@Prop({ type: Boolean, default: true })
isActive?: boolean;

@Prop({ type: Number, default: 0 })
count: number;
```

### Index Options

```typescript
// Simple index
@Prop({ index: true })
email: string;

// Unique index
@Prop({ required: true, unique: true })
vin: string;

// Unique but allows multiple nulls (sparse)
@Prop({ type: Number, unique: true, sparse: true })
externalId?: number;

// Combined options
@Prop({ required: true, index: true, unique: true })
numbers: string[];
```

### Enum Types

```typescript
import { CarState, VehicleType } from 'src/generated/graphql';

// String enum with default
@Prop({
  type: String,
  enum: CarState,
  required: true,
  default: CarState.ACTIVE,
  index: true,
})
status: CarState;

// Optional enum
@Prop({ type: String, enum: VehicleType, default: VehicleType.PERSONAL })
vehicleType?: VehicleType;
```

### Reference Types (Relations)

```typescript
import mongoose, { Types } from 'mongoose';

// Reference to another collection
@Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'CarType', index: true })
type?: Types.ObjectId;
```

### Array Types

```typescript
// Array of primitives
@Prop({ type: [String], default: [] })
tags: string[];

@Prop({ type: [Number], default: [], index: true })
years: number[];

// Array of embedded schemas (see embedded-schemas.md)
@Prop({ type: [CostSchema], default: [] })
monthlyCosts: Cost[];
```

### Custom Setters and Getters

```typescript
import { parseNumber } from 'src/database/database.helper';

// Custom setter for parsing input
@Prop({ type: Number, set: parseNumber })
enginePower?: number;

// Custom getter for default values
@Prop({ type: Number, get: (value: number | null) => value || 0 })
pricelistPrice: number;

// Both setter and getter
@Prop({
  set: parseNumber,
  get: (value: number | null) => value || 0,
})
amortization?: number;
```

### Validation

```typescript
@Prop({
  set: parseNumber,
  get: (value: number | null) => value || 0,
  validate: {
    validator: (value: number) => value >= 0,
    message: 'Tire price must be non-negative',
  },
})
tirePrice?: number;
```

## SchemaFactory

```typescript
import { SchemaFactory } from '@nestjs/mongoose';

export const CarSchema = SchemaFactory.createForClass(Car);
```

## Mongoose 9 ID Virtual

Mongoose 9 no longer provides `id` virtual by default. Add it manually:

```typescript
import { Types } from 'mongoose';

export const CarSchema = SchemaFactory.createForClass(Car);

// Add id virtual (Mongoose 9 no longer provides this by default)
CarSchema.virtual('id').get(function (this: Car & { _id: Types.ObjectId }) {
  return this._id.toHexString();
});
```

## Compound Indexes

For optimized queries on multiple fields:

```typescript
export const CarSchema = SchemaFactory.createForClass(Car);

// Compound index for queries filtering by history event name and date
CarSchema.index({ 'history.name': 1, 'history.date': 1 });

// Multiple compound indexes
CarSchema.index({ status: 1, createdAt: -1 }); // Status + newest first
CarSchema.index({ type: 1, status: 1 });       // Type + status combination
```

## Complete Entity Example

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import mongoose, { Types } from 'mongoose';

import { CarState, VehicleType } from 'src/generated/graphql';

import { parseNumber } from 'src/database/database.helper';

import { Cost, CostSchema } from './cost.entity';
import { CarEvent, CarEventSchema } from './car-event.entity';

@Schema({
  timestamps: true,
  versionKey: false,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
})
export class Car {
  @Prop({
    type: String,
    enum: CarState,
    required: true,
    default: CarState.ACTIVE,
    index: true,
  })
  status: CarState;

  @Prop({ required: true, index: true, unique: true })
  numbers: string[];

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'CarType', index: true })
  type?: Types.ObjectId;

  @Prop({ type: String, enum: VehicleType, default: VehicleType.PERSONAL })
  vehicleType?: VehicleType;

  @Prop()
  manufacturer?: string;

  @Prop()
  model?: string;

  @Prop({ type: Number, set: parseNumber })
  enginePower?: number;

  @Prop({ type: Number, get: (value: number | null) => value || 0 })
  purchasePrice: number;

  @Prop({ type: [CarEventSchema], default: [], required: true })
  history: CarEvent[];

  @Prop({ type: [CostSchema] })
  monthlyCosts: Cost[];

  @Prop({ type: Date })
  availableDate?: Date;

  createdAt: Date;
  updatedAt?: Date;

  // Virtuals (defined after schema creation)
  number: string;
}

export const CarSchema = SchemaFactory.createForClass(Car);

// Add id virtual (Mongoose 9 no longer provides this by default)
CarSchema.virtual('id').get(function (this: Car & { _id: Types.ObjectId }) {
  return this._id.toHexString();
});

// Compound indexes for optimized queries
CarSchema.index({ 'history.name': 1, 'history.date': 1 });

// Custom virtual with getter and setter
const addNumber = (self: Car, number: string) => {
  if (!number) return;
  if (!self.numbers) self.numbers = [];
  if (!self.numbers.includes(number)) {
    self.numbers.push(number);
  }
};

CarSchema.virtual('number')
  .set(function (this: Car, number: string) {
    addNumber(this, number);
  })
  .get(function (this: Car) {
    return this.numbers[0];
  });
```
